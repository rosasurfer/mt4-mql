
#define __TYPE__ T_EXPERT

#include <ChartInfos/functions.mqh>


/**
 * Globale init()-Funktion f�r Expert Adviser.
 *
 * Ist das Flag __STATUS__CANCELLED gesetzt, bricht init() ab.  Nur bei Aufruf durch das Terminal wird
 * der letzte Errorcode 'last_error' in 'prev_error' gespeichert und vor Abarbeitung zur�ckgesetzt.
 *
 * @return int - Fehlerstatus
 */
int init() { /*throws ERR_TERMINAL_NOT_YET_READY*/
   if (__STATUS__CANCELLED)
      return(NO_ERROR);

   if (__WHEREAMI__ == NULL) {                                                // Aufruf durch Terminal
      __WHEREAMI__ = FUNC_INIT;
      prev_error   = last_error;
      last_error   = NO_ERROR;
   }

   __NAME__           = WindowExpertName();
     int initFlags    = SumInts(__INIT_FLAGS__);
   __LOG_INSTANCE_ID  = initFlags & LOG_INSTANCE_ID;
   __LOG_PER_INSTANCE = initFlags & LOG_PER_INSTANCE;
   if (IsTesting())
      __LOG = Tester.IsLogging();


   // (1) globale Variablen re-initialisieren (Indikatoren setzen Variablen nach jedem deinit() zur�ck)
   PipDigits   = Digits & (~1);
   PipPoints   = Round(MathPow(10, Digits<<31>>31));                   PipPoint = PipPoints;
   Pip         = NormalizeDouble(1/MathPow(10, PipDigits), PipDigits); Pips     = Pip;
   PriceFormat = StringConcatenate(".", PipDigits, ifString(Digits==PipDigits, "", "'"));


   // (2) stdlib re-initialisieren (Indikatoren setzen Variablen nach jedem deinit() zur�ck)
   int error = stdlib_init(__TYPE__, __NAME__, __WHEREAMI__, initFlags, UninitializeReason());
   if (IsError(error))
      return(SetLastError(error));


   // (3) user-spezifische Init-Tasks ausf�hren
   if (_bool(initFlags & INIT_TIMEZONE)) {}                                   // Verarbeitung nicht hier, sondern in stdlib_init()

   if (_bool(initFlags & INIT_PIPVALUE)) {                                    // schl�gt fehl, wenn kein Tick vorhanden ist
      TickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
      error = GetLastError();
      if (IsError(error)) {                                                   // - Symbol nicht subscribed (Start, Account-/Templatewechsel), Symbol kann noch "auftauchen"
         if (error == ERR_UNKNOWN_SYMBOL)                                     // - synthetisches Symbol im Offline-Chart
            return(debug("init()   MarketInfo() => ERR_UNKNOWN_SYMBOL", SetLastError(ERR_TERMINAL_NOT_YET_READY)));
         return(catch("init(1)", error));
      }
      if (TickSize == 0) return(debug("init()   MarketInfo(TICKSIZE) = "+ NumberToStr(TickSize, ".+"), SetLastError(ERR_TERMINAL_NOT_YET_READY)));

      double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
      error = GetLastError();
      if (IsError(error)) {
         if (error == ERR_UNKNOWN_SYMBOL)                                     // siehe oben bei MODE_TICKSIZE
            return(debug("init()   MarketInfo() => ERR_UNKNOWN_SYMBOL", SetLastError(ERR_TERMINAL_NOT_YET_READY)));
         return(catch("init(2)", error));
      }
      if (tickValue == 0) return(debug("init()   MarketInfo(TICKVALUE) = "+ NumberToStr(tickValue, ".+"), SetLastError(ERR_TERMINAL_NOT_YET_READY)));
   }

   if (_bool(initFlags & INIT_BARS_ON_HIST_UPDATE)) {}                        // noch nicht implementiert


   // (4)  EA's ggf. aktivieren
   int reasons1[] = { REASON_UNDEFINED, REASON_CHARTCLOSE, REASON_REMOVE };
   if (!IsTesting()) /*&&*/ if (!IsExpertEnabled()) /*&&*/ if (IntInArray(reasons1, UninitializeReason())) {
      error = Toolbar.Experts(true);                                          // !!! TODO: Bug, wenn mehrere EA's den Modus gleichzeitig umschalten
      if (IsError(error))
         return(SetLastError(error));
   }


   // (5) nach Neuladen Orderkontext explizit zur�cksetzen (siehe MQL.doc)
   int reasons2[] = { REASON_UNDEFINED, REASON_CHARTCLOSE, REASON_REMOVE, REASON_ACCOUNT };
   if (IntInArray(reasons2, UninitializeReason()))
      OrderSelect(0, SELECT_BY_TICKET);


   // (6) im Tester ChartInfo-Anzeige konfigurieren
   if (IsVisualMode()) {
      chartInfo.appliedPrice = PRICE_BID;                                     // PRICE_BID ist in EA's ausreichend und schneller (@see ChartInfos-Indikator)
      chartInfo.leverage     = GetGlobalConfigDouble("Leverage", "CurrencyPair", 1);
      if (LT(chartInfo.leverage, 1))
         return(catch("init(3)   invalid configuration value [Leverage] CurrencyPair = "+ NumberToStr(chartInfo.leverage, ".+"), ERR_INVALID_CONFIG_PARAMVALUE));
      error = ChartInfo.CreateLabels();
      if (IsError(error))
         return(error);
   }


   // (7) user-spezifische init()-Routinen aufrufen                           // User-Routinen *k�nnen*, m�ssen aber nicht implementiert werden.
   if (onInit() == -1)                                                        //
      return(last_error);                                                     // Preprocessing-Hook
                                                                              //
   switch (UninitializeReason()) {                                            // Gibt eine der Funktionen einen Fehler zur�ck oder setzt das Flag __STATUS__CANCELLED,
      case REASON_UNDEFINED  : error = onInitUndefined();       break;        // bricht init() *nicht* ab.
      case REASON_CHARTCLOSE : error = onInitChartClose();      break;        //
      case REASON_REMOVE     : error = onInitRemove();          break;        // Gibt eine der Funktionen -1 zur�ck, bricht init() ab.
      case REASON_RECOMPILE  : error = onInitRecompile();       break;        //
      case REASON_PARAMETERS : error = onInitParameterChange(); break;        //
      case REASON_CHARTCHANGE: error = onInitChartChange();     break;        //
      case REASON_ACCOUNT    : error = onInitAccountChange();   break;        //
   }                                                                          //
   if (error == -1)                                                           //
      return(last_error);                                                     //
                                                                              //
   afterInit();                                                               // Postprocessing-Hook
   if (IsLastError() || __STATUS__CANCELLED)                                  //
      return(last_error);                                                     //


   // (8) au�er bei REASON_CHARTCHANGE nicht auf den n�chsten echten Tick warten, sondern sofort selbst einen Tick schicken
   if (!IsTesting())
      if (UninitializeReason() != REASON_CHARTCHANGE)
         Chart.SendTick(false);                                               // Ganz zum Schlu�, da Ticks aus init() verloren gehen, wenn die entsprechende Windows-Message
                                                                              // vor Verlassen von init() vom UI-Thread verarbeitet wird.

   catch("init(4)");
   return(last_error);
}


/**
 * Globale start()-Funktion f�r Expert Adviser.
 *
 * - Ist das Flag __STATUS__CANCELLED gesetzt, bricht start() ab.
 *
 * - Erfolgt der Aufruf nach einem vorherigem init()-Aufruf und init() kehrte mit dem Fehler ERR_TERMINAL_NOT_YET_READY zur�ck,
 *   wird versucht, init() erneut auszuf�hren. Bei erneutem init()-Fehler bricht start() ab.
 *   Wurde init() fehlerfrei ausgef�hrt, wird der letzte Errorcode 'last_error' vor Abarbeitung zur�ckgesetzt.
 *
 * - Der letzte Errorcode 'last_error' wird in 'prev_error' gespeichert und vor Abarbeitung zur�ckgesetzt.
 *
 * @return int - Fehlerstatus
 */
int start() {
   if (__STATUS__CANCELLED)
      return(NO_ERROR);


   // im Tester "time machine bug" abfangen
   if (IsTesting()) {
      static datetime lastTime;
      if (TimeCurrent() < lastTime) {
         __STATUS__CANCELLED = true;
         return(catch("start()   Time is running backward here:   current tick='"+ TimeToStr(TimeCurrent(), TIME_FULL) +"'   last tick='"+ TimeToStr(lastTime, TIME_FULL) +"'", ERR_RUNTIME_ERROR));
      }
      lastTime = TimeCurrent();
   }


   int error;

   Tick++; Ticks = Tick;
   ValidBars = IndicatorCounted();


   // (1) Falls wir aus init() kommen, pr�fen, ob es erfolgreich war und *nur dann* Flag zur�cksetzen.
   if (__WHEREAMI__ == FUNC_INIT) {
      if (IsLastError()) {
         if (last_error != ERR_TERMINAL_NOT_YET_READY)                        // init() ist mit Fehler zur�ckgekehrt
            return(last_error);
         __WHEREAMI__ = FUNC_START;
         error = init();                                                      // init() erneut aufrufen
         if (IsError(error)) {                                                // erneuter Fehler
            __WHEREAMI__ = FUNC_INIT;
            return(error);
         }
      }
      last_error = NO_ERROR;                                                  // init() war erfolgreich
      ValidBars  = 0;
   }
   else {
      prev_error = last_error;                                                // weiterer Tick: last_error sichern und zur�cksetzen
      last_error = NO_ERROR;
      if (prev_error == ERR_TERMINAL_NOT_YET_READY)
         ValidBars = 0;                                                       // falls das Terminal beim vorherigen start()-Aufruf noch nicht bereit war
   }
   __WHEREAMI__ = FUNC_START;


   // (2) bei Bedarf Input-Dialog aufrufen
   if (__STATUS__RELAUNCH_INPUT) {
      __STATUS__RELAUNCH_INPUT = false;
      return(start.RelaunchInputDialog());
   }


   // (3) Abschlu� der Chart-Initialisierung �berpr�fen (kann bei Terminal-Start auftreten)
   if (Bars == 0) {
      debug("start()   ERR_TERMINAL_NOT_YET_READY (Bars = 0)");
      return(SetLastError(ERR_TERMINAL_NOT_YET_READY));
   }


   // (4) ChangedBars berechnen
   ChangedBars = Bars - ValidBars;


   // (5) stdLib benachrichtigen
   if (stdlib_start(Tick, ValidBars, ChangedBars) != NO_ERROR)
      return(SetLastError(stdlib_PeekLastError()));


   // (6) im Tester ChartInfos-Anzeige (@see ChartInfos-Indikator)
   if (IsVisualMode()) {
      error = NO_ERROR;
      chartInfo.positionChecked = false;
      error |= ChartInfo.UpdatePrice();
      error |= ChartInfo.UpdateSpread();
      error |= ChartInfo.UpdateUnitSize();
      error |= ChartInfo.UpdatePosition();
      error |= ChartInfo.UpdateTime();
      error |= ChartInfo.UpdateMarginLevels();
      if (error != NO_ERROR)                                                  // error ist hier die Summe aller in ChartInfo.* aufgetretenen Fehler
         return(last_error);
   }


   // (8) Main-Funktion aufrufen
   error = onTick();


   // (9) Fehlerbehandlung
   if (error != NO_ERROR)
      if (IsTesting())
         Tester.Stop();


   return(error);
}


/**
 * Globale deinit()-Funktion f�r Expert Adviser.
 *
 * @return int - Fehlerstatus
 *
 *
 * NOTE: 1) Ist das Flag __STATUS__CANCELLED gesetzt, bricht deinit() *nicht* ab. Es liegt in der Verantwortung des EA's, diesen Status
 *          selbst auszuwerten.
 *
 *       2) Bei VisualMode=Off und regul�rem Testende (Testperiode zu Ende = REASON_UNDEFINED) bricht das Terminal komplexere deinit()-Funktionen verfr�ht ab.
 *          In der Regel wird afterDeinit() schon nicht mehr ausgef�hrt. In diesem Fall werden die deinit()-Funktionen von geladenen Libraries auch nicht mehr
 *          ausgef�hrt.
 *
 *          TODO:       Testperiode auslesen und Test nach dem letzten Tick per Tester.Stop() beenden
 *          Workaround: Testende im EA direkt vors regul�re Testende der Historydatei setzen
 */
int deinit() {
   __WHEREAMI__ = FUNC_DEINIT;


   // (1) User-spezifische deinit()-Routinen aufrufen                            // User-Routinen *k�nnen*, m�ssen aber nicht implementiert werden.
   int error = onDeinit();                                                       // Preprocessing-Hook
                                                                                 //
   if (error != -1) {                                                            //
      switch (UninitializeReason()) {                                            //
         case REASON_UNDEFINED  : error = onDeinitUndefined();       break;      // - deinit() bricht *nicht* ab, falls eine der User-Routinen einen Fehler zur�ckgibt oder
         case REASON_CHARTCLOSE : error = onDeinitChartClose();      break;      //   das Flag __STATUS__CANCELLED setzt.
         case REASON_REMOVE     : error = onDeinitRemove();          break;      //
         case REASON_RECOMPILE  : error = onDeinitRecompile();       break;      // - deinit() bricht ab, falls eine der User-Routinen -1 zur�ckgibt.
         case REASON_PARAMETERS : error = onDeinitParameterChange(); break;      //
         case REASON_CHARTCHANGE: error = onDeinitChartChange();     break;      //
         case REASON_ACCOUNT    : error = onDeinitAccountChange();   break;      //
      }                                                                          //
   }                                                                             //
                                                                                 //
   if (error != -1)                                                              //
      error = afterDeinit();                                                     // Postprocessing-Hook


   // (2) User-spezifische Deinit-Tasks ausf�hren
   if (error != -1) {
      // ...
   }


   // (3) stdlib deinitialisieren
   error = stdlib_deinit(SumInts(__DEINIT_FLAGS__), UninitializeReason());
   if (IsError(error))
      SetLastError(error);

   return(last_error);
}


/**
 * Ob das aktuelle ausgef�hrte Programm ein Expert Adviser ist.
 *
 * @return bool
 */
bool IsExpert() {
   return(true);
}


/**
 * Ob das aktuelle ausgef�hrte Programm ein Indikator ist.
 *
 * @return bool
 */
bool IsIndicator() {
   return(false);
}


/**
 * Ob das aktuelle ausgef�hrte Programm ein Script ist.
 *
 * @return bool
 */
bool IsScript() {
   return(false);
}


/**
 * Ob das aktuelle ausgef�hrte Programm eine Library ist.
 *
 * @return bool
 */
bool IsLibrary() {
   return(false);
}
