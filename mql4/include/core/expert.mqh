
#define __TYPE__    T_EXPERT
#define __iCustom__ NULL

#include <ChartInfos/functions.mqh>
#include <EventListener.BarOpen.mqh>


// Teststatistiken
datetime Test.fromDate,    Test.toDate;
int      Test.startMillis, Test.stopMillis;                          // in Millisekunden


/**
 * Globale init()-Funktion f�r Expert Adviser.
 *
 * Nur bei Aufruf durch das Terminal wird der letzte Errorcode 'last_error' in 'prev_error' gespeichert und vor Abarbeitung
 * zur�ckgesetzt.
 *
 * @return int - Fehlerstatus
 */
int init() { //throws ERS_TERMINAL_NOT_READY
   if (__STATUS_ERROR)
      return(last_error);

   if (__WHEREAMI__ == NULL) {                                       // Aufruf durch Terminal
      __WHEREAMI__ = FUNC_INIT;
      prev_error   = last_error;
      last_error   = NO_ERROR;
   }

   __NAME__       = WindowExpertName();
   __InitFlags    = SumInts(__INIT_FLAGS__) | INIT_HSTLIB;           // in Experts wird die hstLib immer initialisiert
   __LOG_CUSTOM   = __InitFlags & INIT_CUSTOMLOG;
   if (IsTesting())
      __LOG = Tester.IsLogging();
   IsChart        = !IsTesting() || IsVisualMode();
 //IsOfflineChart = IsChart && ???


   // (1) globale Variablen re-initialisieren (Indikatoren setzen Variablen nach jedem deinit() zur�ck)
   PipDigits      = Digits & (~1);                                        SubPipDigits      = PipDigits+1;
   PipPoints      = MathRound(MathPow(10, Digits<<31>>31));               PipPoint          = PipPoints;
   Pip            = NormalizeDouble(1/MathPow(10, PipDigits), PipDigits); Pips              = Pip;
   PipPriceFormat = StringConcatenate(".", PipDigits);                    SubPipPriceFormat = StringConcatenate(PipPriceFormat, "'");
   PriceFormat    = ifString(Digits==PipDigits, PipPriceFormat, SubPipPriceFormat);


   // (2) stdlib re-initialisieren (Indikatoren setzen Variablen nach jedem deinit() zur�ck)
   int iNull[];
   int error = stdlib_init(__TYPE__, __NAME__, __WHEREAMI__, IsChart, IsOfflineChart, __iCustom__, __InitFlags, UninitializeReason(), iNull);
   if (IsError(error))
      return(SetLastError(error));                                            // #define INIT_TIMEZONE               in stdlib_init()
                                                                              // #define INIT_PIPVALUE
                                                                              // #define INIT_BARS_ON_HIST_UPDATE
                                                                              // #define INIT_CUSTOMLOG
   // (3) user-spezifische Init-Tasks ausf�hren                               // #define INIT_HSTLIB
   if (_bool(__InitFlags & INIT_PIPVALUE)) {
      TickSize = MarketInfo(Symbol(), MODE_TICKSIZE);                         // schl�gt fehl, wenn kein Tick vorhanden ist
      error = GetLastError();
      if (IsError(error)) {                                                   // - Symbol nicht subscribed (Start, Account-/Templatewechsel), Symbol kann noch "auftauchen"
         if (error == ERR_UNKNOWN_SYMBOL)                                     // - synthetisches Symbol im Offline-Chart
            return(debug("init()   MarketInfo() => ERR_UNKNOWN_SYMBOL", SetLastError(ERS_TERMINAL_NOT_READY)));
         return(catch("init(1)", error));
      }
      if (!TickSize) return(debug("init()   MarketInfo(TICKSIZE) = "+ NumberToStr(TickSize, ".+"), SetLastError(ERS_TERMINAL_NOT_READY)));

      double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
      error = GetLastError();
      if (IsError(error)) {
         if (error == ERR_UNKNOWN_SYMBOL)                                     // siehe oben bei MODE_TICKSIZE
            return(debug("init()   MarketInfo() => ERR_UNKNOWN_SYMBOL", SetLastError(ERS_TERMINAL_NOT_READY)));
         return(catch("init(2)", error));
      }
      if (!tickValue) return(debug("init()   MarketInfo(TICKVALUE) = "+ NumberToStr(tickValue, ".+"), SetLastError(ERS_TERMINAL_NOT_READY)));
   }

   if (_bool(__InitFlags & INIT_BARS_ON_HIST_UPDATE)) {}                      // noch nicht implementiert

   if (_bool(__InitFlags & INIT_HSTLIB)) {
      error = hstlib_init(__TYPE__, __NAME__, __WHEREAMI__, IsChart, IsOfflineChart, __iCustom__, __InitFlags, UninitializeReason());
      if (IsError(error))
         return(SetLastError(error));
   }


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
      if (IsError(ChartInfo.CreateLabels()))
         return(last_error);
   }

                                                                              // User-Routinen *k�nnen*, m�ssen aber nicht implementiert werden.
   // (7) user-spezifische init()-Routinen aufrufen                           //
   onInit();                                                                  // Preprocessing-Hook
                                                                              //
   if (!__STATUS_ERROR) {                                                     //
      switch (UninitializeReason()) {                                         //
         case REASON_PARAMETERS : error = onInitParameterChange(); break;     //
         case REASON_CHARTCHANGE: error = onInitChartChange();     break;     //
         case REASON_ACCOUNT    : error = onInitAccountChange();   break;     //
         case REASON_CHARTCLOSE : error = onInitChartClose();      break;     //
         case REASON_UNDEFINED  : error = onInitUndefined();       break;     //
         case REASON_REMOVE     : error = onInitRemove();          break;     //
         case REASON_RECOMPILE  : error = onInitRecompile();       break;     //
      }                                                                       //
   }                                                                          //
                                                                              //
   afterInit();                                                               // Postprocessing-Hook wird immer ausgef�hrt (auch bei __STATUS_ERROR)
   ShowStatus();                                                              //

   if (__STATUS_ERROR)
      return(last_error);


   // (8) au�er bei REASON_CHARTCHANGE nicht auf den n�chsten echten Tick warten, sondern sofort selbst einen Tick schicken
   if (!IsTesting()) {
      if (UninitializeReason() != REASON_CHARTCHANGE) {                       // Ganz zum Schlu�, da Ticks verloren gehen, wenn die entsprechende Windows-Message
         error = Chart.SendTick(false);                                       // vor Verlassen von init() verarbeitet wird.
         if (IsError(error))
            SetLastError(error);
      }
   }
   else {
      Test.fromDate    = TimeCurrent();
      Test.startMillis = GetTickCount();
   }
   return(catch("init(4)")|last_error);
}


/**
 * Globale start()-Funktion f�r Expert Adviser.
 *
 * - Erfolgt der Aufruf nach einem vorherigem init()-Aufruf und init() kehrte mit dem Fehler ERS_TERMINAL_NOT_READY zur�ck,
 *   wird versucht, init() erneut auszuf�hren. Bei erneutem init()-Fehler bricht start() ab.
 *   Wurde init() fehlerfrei ausgef�hrt, wird der letzte Errorcode 'last_error' vor Abarbeitung zur�ckgesetzt.
 *
 * - Der letzte Errorcode 'last_error' wird in 'prev_error' gespeichert und vor Abarbeitung zur�ckgesetzt.
 *
 * @return int - Fehlerstatus
 */
int start() {
   if (__STATUS_ERROR) {
      ShowStatus();
      return(last_error);
   }


   // "Time machine"-Bug im Tester abfangen
   if (IsTesting()) {
      static datetime time, lastTime;
      time = TimeCurrent();
      if (time < lastTime) {
         catch("start(1)   Bug in TimeCurrent()/MarketInfo(MODE_TIME) testen !!!\nTime is running backward here:   previous='"+ TimeToStr(lastTime, TIME_FULL) +"'   current='"+ TimeToStr(time, TIME_FULL) +"'", ERR_RUNTIME_ERROR);
         ShowStatus();
         return(last_error);
      }
      lastTime = time;
   }


   int error;

   Tick++; Ticks = Tick;
   Tick.prevTime = Tick.Time;
   Tick.Time     = MarketInfo(Symbol(), MODE_TIME);
   ValidBars     = -1;
   ChangedBars   = -1;


   // (1) Falls wir aus init() kommen, pr�fen, ob es erfolgreich war und *nur dann* Flag zur�cksetzen.
   if (__WHEREAMI__ == FUNC_INIT) {
      if (IsLastError()) {
         if (last_error != ERS_TERMINAL_NOT_READY) {                 // init() ist mit hartem Fehler zur�ckgekehrt
            ShowStatus();
            return(last_error);
         }
         __WHEREAMI__ = FUNC_START;
         if (IsError(init())) {                                      // init() erneut aufrufen
            __WHEREAMI__ = FUNC_INIT;                                // erneuter Fehler (hart oder weich)
            ShowStatus();
            return(last_error);
         }
      }
      last_error = NO_ERROR;                                         // init() war erfolgreich
   }
   else {
      prev_error = last_error;                                       // weiterer Tick: last_error sichern und zur�cksetzen
      last_error = NO_ERROR;
   }
   __WHEREAMI__ = FUNC_START;


   // (2) bei Bedarf Input-Dialog aufrufen
   if (__STATUS_RELAUNCH_INPUT) {
      __STATUS_RELAUNCH_INPUT = false;
      start.RelaunchInputDialog();
      ShowStatus();
      return(last_error);
   }


   // (3) Abschlu� der Chart-Initialisierung �berpr�fen (kann bei Terminal-Start auftreten)
   if (!Bars) {
      SetLastError(debug("start()   Bars = 0", ERS_TERMINAL_NOT_READY));
      ShowStatus();
      return(last_error);
   }


   // (4) stdLib benachrichtigen
   if (stdlib_start(Tick, Tick.Time, ValidBars, ChangedBars) != NO_ERROR) {
      SetLastError(stdlib_GetLastError());
      ShowStatus();
      return(last_error);
   }


   // (5) im Tester ChartInfos-Anzeige (@see ChartInfos-Indikator)
   if (IsVisualMode()) {
      error = NO_ERROR;
      chartInfo.positionChecked = false;
      error |= ChartInfo.UpdatePrice();
      error |= ChartInfo.UpdateSpread();
      error |= ChartInfo.UpdateUnitSize();
      error |= ChartInfo.UpdatePosition();
      error |= ChartInfo.UpdateTime();
      error |= ChartInfo.UpdateMarginLevels();
      if (error != NO_ERROR) {                                       // error ist hier die Summe aller in ChartInfo.* aufgetretenen Fehler
         ShowStatus();
         return(last_error);
      }
   }


   // (6) Main-Funktion aufrufen und auswerten
   onTick();

   error = GetLastError();
   if (error != NO_ERROR)
      catch("start(2)", error);


   // (7) Tester nach Fehler anhalten
   if (last_error!=NO_ERROR) /*&&*/ if (IsTesting())
      Tester.Stop();


   ShowStatus();
   return(last_error);
}


/**
 * Globale deinit()-Funktion f�r Expert Adviser.
 *
 * @return int - Fehlerstatus
 *
 *
 * NOTE: Bei VisualMode=Off und regul�rem Testende (Testperiode zu Ende = REASON_UNDEFINED) bricht das Terminal komplexere deinit()-Funktionen verfr�ht ab.
 *       afterDeinit() und stdlib_deinit() werden u.U. schon nicht mehr ausgef�hrt.
 *
 *       Workaround: Testperiode auslesen (Controls), letzten Tick ermitteln (Historydatei) und Test nach letztem Tick per Tester.Stop() beenden.
 *                   Alternativ bei EA's, die dies unterst�tzen, Testende vors regul�re Testende der Historydatei setzen.
 */
int deinit() {
   __WHEREAMI__  = FUNC_DEINIT;
   __DeinitFlags = SumInts(__DEINIT_FLAGS__);

   if (IsTesting()) {
      Test.toDate     = TimeCurrent();
      Test.stopMillis = GetTickCount();
   }


   // (1) User-spezifische deinit()-Routinen aufrufen                            // User-Routinen *k�nnen*, m�ssen aber nicht implementiert werden.
   int error = onDeinit();                                                       // Preprocessing-Hook
                                                                                 //
   if (error != -1) {                                                            // - deinit() bricht *nicht* ab, falls eine der User-Routinen einen Fehler zur�ckgibt.
      switch (UninitializeReason()) {                                            // - deinit() bricht ab, falls eine der User-Routinen -1 zur�ckgibt.
         case REASON_PARAMETERS : error = onDeinitParameterChange(); break;      //
         case REASON_CHARTCHANGE: error = onDeinitChartChange();     break;      //
         case REASON_ACCOUNT    : error = onDeinitAccountChange();   break;      //
         case REASON_CHARTCLOSE : error = onDeinitChartClose();      break;      //
         case REASON_UNDEFINED  : error = onDeinitUndefined();       break;      //
         case REASON_REMOVE     : error = onDeinitRemove();          break;      //
         case REASON_RECOMPILE  : error = onDeinitRecompile();       break;      //
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
   error = stdlib_deinit(__DeinitFlags, UninitializeReason());
   if (IsError(error))
      SetLastError(error);

   return(last_error);
}


/**
 * Ob das aktuell ausgef�hrte Programm ein Expert Adviser ist.
 *
 * @return bool
 */
bool IsExpert() {
   return(true);
}


/**
 * Ob das aktuell ausgef�hrte Programm ein im Tester laufender Expert ist.
 *
 * @return bool
 */
bool Expert.IsTesting() {
   return(IsTesting());
}


/**
 * Ob das aktuell ausgef�hrte Programm ein Indikator ist.
 *
 * @return bool
 */
bool IsIndicator() {
   return(false);
}


/**
 * Ob der aktuelle Indikator via iCustom() ausgef�hrt wird.
 *
 * @return bool
 */
bool Indicator.IsICustom() {
   return(false);
}


/**
 * Ob das aktuell ausgef�hrte Programm ein Script ist.
 *
 * @return bool
 */
bool IsScript() {
   return(false);
}


/**
 * Ob das aktuell ausgef�hrte Modul eine Library ist.
 *
 * @return bool
 */
bool IsLibrary() {
   return(false);
}


/**
 * Setzt den internen Fehlercode des Moduls.
 *
 * @param  int error - Fehlercode
 *
 * @return int - derselbe Fehlercode (for chaining)
 *
 *
 * NOTE: Akzeptiert einen weiteren beliebigen Parameter, der bei der Verarbeitung jedoch ignoriert wird.
 */
int SetLastError(int error, int param=NULL) {
   last_error = error;

   switch (error) {
      case NO_ERROR              : break;
      case ERS_HISTORY_UPDATE    : break;
      case ERS_TERMINAL_NOT_READY: break;
      case ERS_EXECUTION_STOPPING: break;

      default:
         __STATUS_ERROR = true;
   }
   return(error);
}


// -- init()-Templates ------------------------------------------------------------------------------------------------------------------------------


/**
 * Preprocessing-Hook
 *
 * @return int - Fehlerstatus
 *
int onInit() {
   return(NO_ERROR);
}


/**
 * Nach Parameter�nderung
 *
 *  - altes Chartfenster, alter EA, Input-Dialog
 *
 * @return int - Fehlerstatus
 *
int onInitParameterChange() {
   return(NO_ERROR);
}


/**
 * Nach Symbol- oder Timeframe-Wechsel
 *
 * - altes Chartfenster, alter EA, kein Input-Dialog
 *
 * @return int - Fehlerstatus
 *
int onInitChartChange() {
   return(NO_ERROR);
}


/**
 * Nach Accountwechsel
 *
 * TODO: Umst�nde ungekl�rt, wird in stdlib mit ERR_RUNTIME_ERROR abgefangen
 *
 * @return int - Fehlerstatus
 *
int onInitAccountChange() {
   return(NO_ERROR);
}


/**
 * Altes Chartfenster mit neu geladenem Template
 *
 * - neuer EA, Input-Dialog
 *
 * @return int - Fehlerstatus
 *
int onInitChartClose() {
   return(NO_ERROR);
}


/**
 * Kein UninitializeReason gesetzt
 *
 * - nach Terminal-Neustart: neues Chartfenster, vorheriger EA, kein Input-Dialog
 * - nach File->New->Chart:  neues Chartfenster, neuer EA, Input-Dialog
 * - im Tester:              neues Chartfenster bei VisualMode=On, neuer EA, kein Input-Dialog
 *
 * @return int - Fehlerstatus
 *
int onInitUndefined() {
   return(NO_ERROR);
}


/**
 * Vorheriger EA von Hand entfernt (Chart->Expert->Remove) oder neuer EA dr�bergeladen
 *
 * - altes Chartfenster, neuer EA, Input-Dialog
 *
 * @return int - Fehlerstatus
 *
int onInitRemove() {
   return(NO_ERROR);
}


/**
 * Nach Recompilation
 *
 * - altes Chartfenster, vorheriger EA, kein Input-Dialog
 *
 * @return int - Fehlerstatus
 *
int onInitRecompile() {
   return(NO_ERROR);
}


/**
 * Postprocessing-Hook
 *
 * @return int - Fehlerstatus
 *
int afterInit() {
   return(NO_ERROR);
}
 */


// -- deinit()-Templates ----------------------------------------------------------------------------------------------------------------------------


/**
 * Preprocessing-Hook
 *
 * @return int - Fehlerstatus
 *
int onDeinit() {
   double test.duration = (Test.stopMillis-Test.startMillis)/1000.0;
   double test.days     = (Test.toDate-Test.fromDate) * 1.0 /DAYS;
   debug("onDeinit()   time="+ DoubleToStr(test.duration, 1) +" sec   days="+ Round(test.days) +"   ("+ DoubleToStr(test.duration/test.days, 3) +" sec/day)");
   return(last_error);
}


/**
 * Parameter�nderung
 *
 * @return int - Fehlerstatus
 *
int onDeinitParameterChange() {
   return(NO_ERROR);
}


/**
 * Symbol- oder Timeframewechsel
 *
 * @return int - Fehlerstatus
 *
int onDeinitChartChange() {
   return(NO_ERROR);
}


/**
 * Accountwechsel
 *
 * TODO: Umst�nde ungekl�rt, wird in stdlib mit ERR_RUNTIME_ERROR abgefangen
 *
 * @return int - Fehlerstatus
 *
int onDeinitAccountChange() {
   return(NO_ERROR);
}


/**
 * Im Tester: - Nach Bet�tigen des "Stop"-Buttons oder nach Chart->Close. Der "Stop"-Button des Testers kann nach Fehler oder Testabschlu�
 *              vom Code "bet�tigt" worden sein.
 *
 * Online:    - Chart wird geschlossen                  - oder -
 *            - Template wird neu geladen               - oder -
 *            - Terminal-Shutdown                       - oder -
 *
 * @return int - Fehlerstatus
 *
int onDeinitChartClose() {
   return(NO_ERROR);
}


/**
 * Kein UninitializeReason gesetzt: nur im Tester nach regul�rem Ende (Testperiode zu Ende)
 *
 * @return int - Fehlerstatus
 *
int onDeinitUndefined() {
   return(NO_ERROR);
}


/**
 * Nur Online: EA von Hand entfernt (Chart->Expert->Remove) oder neuer EA dr�bergeladen
 *
 * @return int - Fehlerstatus
 *
int onDeinitRemove() {
   return(NO_ERROR);
}


/**
 * Recompilation
 *
 * @return int - Fehlerstatus
 *
int onDeinitRecompile() {
   return(NO_ERROR);
}


/**
 * Postprocessing-Hook
 *
 * @return int - Fehlerstatus
 *
int afterDeinit() {
   return(NO_ERROR);
}
 */
