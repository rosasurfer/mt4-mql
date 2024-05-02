/**
 * Chart grid
 *
 *
 *
 * TODO:
 *  @see  https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowrect#                                                      [GetWindowRect()]
 *  @see  https://stackoverflow.com/questions/68375674/how-to-get-scaling-aware-window-size-using-winapi#                              [Get scaling-aware window size]
 *  @see  https://gist.github.com/marler8997/9f39458d26e2d8521d48e36530fbb459#                                                          [Win32DPI and monitor scaling]
 *  @see  https://cplusplus.com/forum/windows/285609/#                                                           [Get desktop dimensions while DPI scaling is enabled]
 *  @see  https://stackoverflow.com/questions/5977445/how-to-get-windows-display-settings#                                              [How to get Win7 scale factor]
 *  @see  https://www.reddit.com/r/Windows10/comments/3lolnr/why_is_dpi_scaling_on_windows_7_better_than_on/?rdt=56415# [Whiy is DPI scaling on W7 better than on W10]
 *  @see  https://forums.mydigitallife.net/threads/solved-windows-10-higher-dpi-win8dpiscaling-problem.62528/
 *  @see  https://www.reddit.com/r/buildapc/comments/5v8pcd/rwindows10_wasnt_very_friendly_but_does_anyone/#              [Disable W10 DPI scaling for an application]
 */
#include <stddefines.mqh>
int   __InitFlags[] = {INIT_TIMEZONE};
int __DeinitFlags[];

////////////////////////////////////////////////////// Configuration ////////////////////////////////////////////////////////

extern color Color.RegularGrid = Gainsboro;        // C'220,220,220'
extern color Color.SuperGrid   = LightGray;        // C'211,211,211' (slightly darker)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <core/indicator.mqh>
#include <stdfunctions.mqh>
#include <rsfLib.mqh>
#include <functions/iBarShiftNext.mqh>
#include <functions/ObjectCreateRegister.mqh>
#include <win32api.mqh>

#property indicator_chart_window
#property indicator_buffers      1
#property indicator_color1       CLR_NONE


/**
 * Initialization
 *
 * @return int - error status
 */
int onInit() {
   string indicator = WindowExpertName();

   // after deserialization the terminal might turn CLR_NONE (0xFFFFFFFF) into Black (0xFF000000)
   if (AutoConfiguration) Color.RegularGrid = GetConfigColor(indicator, "Color.RegularGrid", Color.RegularGrid);
   if (AutoConfiguration) Color.SuperGrid   = GetConfigColor(indicator, "Color.SuperGrid",   Color.SuperGrid);

   if (Color.RegularGrid == 0xFF000000) Color.RegularGrid = CLR_NONE;
   if (Color.SuperGrid   == 0xFF000000) Color.SuperGrid   = CLR_NONE;

   SetIndicatorOptions();
   return(catch("onInit(1)"));
}


/**
 * Main function
 *
 * @return int - error status
 */
int onTick() {
   if (!ValidBars) SetIndicatorOptions();

   if (__isChart) {
      if (ChangedBars > 2) UpdateVerticalGrid();
      UpdateHorizontalGrid();
   }
   return(last_error);
}


double lastMinPrice;
double lastMaxPrice;
double lastHeight;


/**
 * Update the horizontal grid (price separators).
 *
 * @return bool - success status
 */
bool UpdateHorizontalGrid() {
   double minPrice = WindowPriceMin();
   double maxPrice = WindowPriceMax();
   if (!minPrice || !maxPrice) return(true);          // ERS_TERMINAL_NOT_YET_READY

   int hWnd = __ExecutionContext[EC.hChart], rect[RECT_size];
   if (!GetWindowRect(hWnd, rect)) return(!catch("UpdateHorizontalGrid(1)->GetWindowRect()", ERR_WIN32_ERROR+GetLastWin32Error()));
   int height = rect[RECT.bottom]-rect[RECT.top];
   if (!height) return(true);                         // view port resized to zero height

   if (height!=lastHeight || minPrice!=lastMinPrice || maxPrice!=lastMaxPrice) {
      if (false) debug("onTick(0.1)  height="+ height +"  minPrice="+ NumberToStr(minPrice, PriceFormat) +"  maxPrice="+ NumberToStr(maxPrice, PriceFormat));

      lastMinPrice = minPrice;
      lastMaxPrice = maxPrice;
      lastHeight = height;
   }
   return(!catch("UpdateHorizontalGrid(2)"));
}


/**
 * Zeichnet das Grid.
 *
 * @return bool - success status
 */
bool UpdateVerticalGrid() {
   // due to init flag INIT_TIMEZONE we don't have to check for timezone related errors
   datetime firstWeekDay, separatorTime, chartTime, lastChartTime;
   int      dow, dd, mm, yyyy, bar, sepColor, sepStyle;
   string   label="", lastLabel="";

   // Zeitpunkte des �ltesten und j�ngsten Separators berechen
   datetime fromFXT = GetNextSessionStartTime(ServerToFxtTime(Time[Bars-1]) - 1*SECOND, TZ_FXT);
   datetime toFXT   = GetNextSessionStartTime(ServerToFxtTime(Time[0]),                 TZ_FXT);

   // Tagesseparatoren
   if (Period() < PERIOD_H4) {
      //fromFXT = ...                                                         // fromFXT bleibt unver�ndert
      //toFXT   = ...                                                         // toFXT bleibt unver�ndert
   }

   // Wochenseparatoren
   else if (Period() == PERIOD_H4) {
      fromFXT += (8-TimeDayOfWeekEx(fromFXT))%7 * DAYS;                       // fromFXT ist der erste Montag
      toFXT   += (8-TimeDayOfWeekEx(toFXT))%7 * DAYS;                         // toFXT ist der n�chste Montag
   }

   // Monatsseparatoren
   else if (Period() == PERIOD_D1) {
      yyyy = TimeYearEx(fromFXT);                                             // fromFXT ist der erste Wochentag des ersten vollen Monats
      mm   = TimeMonth(fromFXT);
      firstWeekDay = GetFirstWeekdayOfMonth(yyyy, mm);

      if (firstWeekDay < fromFXT) {
         if (mm == 12) { yyyy++; mm = 0; }
         firstWeekDay = GetFirstWeekdayOfMonth(yyyy, mm+1);
      }
      fromFXT = firstWeekDay;
      // ------------------------------------------------------
      yyyy = TimeYearEx(toFXT);                                               // toFXT ist der erste Wochentag des n�chsten Monats
      mm   = TimeMonth(toFXT);
      firstWeekDay = GetFirstWeekdayOfMonth(yyyy, mm);

      if (firstWeekDay < toFXT) {
         if (mm == 12) { yyyy++; mm = 0; }
         firstWeekDay = GetFirstWeekdayOfMonth(yyyy, mm+1);
      }
      toFXT = firstWeekDay;
   }

   // Jahresseparatoren
   else if (Period() > PERIOD_D1) {
      yyyy = TimeYearEx(fromFXT);                                             // fromFXT ist der erste Wochentag des ersten vollen Jahres
      firstWeekDay = GetFirstWeekdayOfMonth(yyyy, 1);
      if (firstWeekDay < fromFXT)
         firstWeekDay = GetFirstWeekdayOfMonth(yyyy+1, 1);
      fromFXT = firstWeekDay;
      // ------------------------------------------------------
      yyyy = TimeYearEx(toFXT);                                               // toFXT ist der erste Wochentag des n�chsten Jahres
      firstWeekDay = GetFirstWeekdayOfMonth(yyyy, 1);
      if (firstWeekDay < toFXT)
         firstWeekDay = GetFirstWeekdayOfMonth(yyyy+1, 1);
      toFXT = firstWeekDay;
   }

   // Separatoren zeichnen
   for (datetime time=fromFXT; time <= toFXT; time+=1*DAY) {
      separatorTime = FxtToServerTime(time);
      dow           = TimeDayOfWeekEx(time);

      // Bar und Chart-Time des Separators ermitteln
      if (Time[0] < separatorTime) {                                          // keine entsprechende Bar: aktuelle Session oder noch laufendes ERS_HISTORY_UPDATE
         bar = -1;
         chartTime = separatorTime;                                           // urspr�ngliche Zeit verwenden
         if (dow == MONDAY)
            chartTime -= 2*DAYS;                                              // bei zuk�nftigen Separatoren Wochenenden von Hand "kollabieren" TODO: Bug bei Periode > H4
      }
      else {                                                                  // Separator liegt innerhalb der Bar-Range, Zeit der ersten existierenden Bar verwenden
         bar = iBarShiftNext(NULL, NULL, separatorTime);
         if (bar == EMPTY_VALUE) return(false);
         chartTime = Time[bar];
      }

      // Label des Separators zusammenstellen (ie. "Fri 23.12.2011")
      label = TimeToStr(time);
      label = StringConcatenate(GmtTimeFormat(time, "%a"), " ", StringSubstr(label, 8, 2), ".", StringSubstr(label, 5, 2), ".", StringSubstr(label, 0, 4));

      if (lastChartTime == chartTime) ObjectDelete(lastLabel);                // Bars der vorherigen Periode fehlen (noch laufendes ERS_HISTORY_UPDATE oder Kursl�cke)
                                                                              // Separator f�r die fehlende Periode wieder l�schen
      // Separator zeichnen
      if (ObjectFind(label) == -1) if (!ObjectCreateRegister(label, OBJ_VLINE, 0, chartTime, 0, 0, 0, 0, 0)) return(false);
      sepStyle = STYLE_DOT;
      sepColor = Color.RegularGrid;
      if (Period() < PERIOD_H4) {
         if (dow == MONDAY) {
            sepStyle = STYLE_DASHDOTDOT;
            sepColor = Color.SuperGrid;
         }
      }
      else if (Period() == PERIOD_H4) {
         sepStyle = STYLE_DASHDOTDOT;
         sepColor = Color.SuperGrid;
      }
      ObjectSet(label, OBJPROP_STYLE, sepStyle);
      ObjectSet(label, OBJPROP_COLOR, sepColor);
      ObjectSet(label, OBJPROP_BACK,  true);
      lastChartTime = chartTime;
      lastLabel     = label;                                                  // Daten des letzten Separators f�r L�ckenerkennung merken

      // je nach Periode einen Tag *vor* den n�chsten Separator springen
      // Tagesseparatoren
      if (Period() < PERIOD_H4) {
         if (dow == FRIDAY)                                                   // Wochenenden �berspringen
            time += 2*DAYS;
      }
      // Wochenseparatoren
      else if (Period() == PERIOD_H4) {
         time += 6*DAYS;                                                      // TimeDayOfWeek(time) == MONDAY
      }
      // Monatsseparatoren
      else if (Period() == PERIOD_D1) {                                       // erster Wochentag des Monats
         yyyy = TimeYearEx(time);
         mm   = TimeMonth(time);
         if (mm == 12) { yyyy++; mm = 0; }
         time = GetFirstWeekdayOfMonth(yyyy, mm+1) - 1*DAY;
      }
      // Jahresseparatoren
      else if (Period() > PERIOD_D1) {                                        // erster Wochentag des Jahres
         yyyy = TimeYearEx(time);
         time = GetFirstWeekdayOfMonth(yyyy+1, 1) - 1*DAY;
      }
   }
   return(!catch("UpdateVerticalGrid(2)"));
}


/**
 * Ermittelt den ersten Wochentag eines Monats.
 *
 * @param  int year  - Jahr (1970 bis 2037)
 * @param  int month - Monat
 *
 * @return datetime - erster Wochentag des Monats oder EMPTY (-1), falls ein Fehler auftrat
 */
datetime GetFirstWeekdayOfMonth(int year, int month) {
   if (year  < 1970 || 2037 < year ) return(_EMPTY(catch("GetFirstWeekdayOfMonth(1)  illegal parameter year: "+ year +" (not between 1970 and 2037)", ERR_INVALID_PARAMETER)));
   if (month <    1 ||   12 < month) return(_EMPTY(catch("GetFirstWeekdayOfMonth(2)  invalid parameter month: "+ month, ERR_INVALID_PARAMETER)));

   datetime firstDayOfMonth = StrToTime(StringConcatenate(year, ".", StrRight("0"+month, 2), ".01 00:00:00"));

   int dow = TimeDayOfWeekEx(firstDayOfMonth);
   if (dow == SATURDAY) return(firstDayOfMonth + 2*DAYS);
   if (dow == SUNDAY  ) return(firstDayOfMonth + 1*DAY );

   return(firstDayOfMonth);
}


/**
 * Workaround for various terminal bugs when setting indicator options. Usually options are set in init(). However after
 * recompilation options must be set in start() to not be ignored.
 */
void SetIndicatorOptions() {
   IndicatorBuffers(indicator_buffers);
   SetIndexStyle(0, DRAW_NONE);
   SetIndexLabel(0, NULL);
   IndicatorShortName("");
}


/**
 * Return a string representation of the input parameters (for logging purposes).
 *
 * @return string
 */
string InputsToStr() {
   return(StringConcatenate("Color.RegularGrid=", ColorToStr(Color.RegularGrid), ";", NL,
                            "Color.SuperGrid=",   ColorToStr(Color.SuperGrid),   ";")
   );
}
