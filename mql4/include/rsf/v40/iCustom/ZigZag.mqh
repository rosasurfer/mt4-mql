#define ZigZag.MODE_SEMAPHORE_OPEN     0              // semaphore open price
#define ZigZag.MODE_SEMAPHORE_CLOSE    1              // semaphore close price
#define ZigZag.MODE_UPPER_BAND         2              // upper channel band
#define ZigZag.MODE_LOWER_BAND         3              // lower channel band
#define ZigZag.MODE_UPPER_CROSS        4              // upper channel band crossings
#define ZigZag.MODE_LOWER_CROSS        5              // lower channel band crossings
#define ZigZag.MODE_REVERSAL           6              // offset of last ZigZag reversal to previous ZigZag semaphore
#define ZigZag.MODE_TREND              7              // trend (combined buffers MODE_KNOWN_TREND and MODE_UNKNOWN_TREND)


/**
 * Load the custom "ZigZag" indicator and return a value.
 *
 * @param  int timeframe - timeframe to load the indicator (NULL: the current timeframe)
 * @param  int periods   - indicator parameter
 * @param  int iBuffer   - indicator buffer index of the value to return
 * @param  int iBar      - bar index of the value to return
 *
 * @return double - indicator value or NULL in case of errors
 */
double icZigZag(int timeframe, int periods, int iBuffer, int iBar) {
   static int lpSuperContext = 0; if (!lpSuperContext) {
      lpSuperContext = GetIntsAddress(__ExecutionContext);
   }

   double value = iCustom(NULL, timeframe, "ZigZag",
                          "",                         // string ____________________________
                          periods,                    // int    ZigZag.Periods
                          0,                          // int    ZigZag.Periods.Step
                          "Line",                     // string ZigZag.Type
                          1,                          // int    ZigZag.Width
                          108,                        // int    ZigZag.Semaphores.Wingdings
                          CLR_NONE,                   // color  ZigZag.Color

                          "",                         // string ____________________________
                          false,                      // bool   Donchian.ShowChannel
                          "all",                      // string Donchian.ShowCrossings
                          1,                          // int    Donchian.Crossings.Width
                          161,                        // int    Donchian.Crossings.Wingdings
                          CLR_NONE,                   // color  Donchian.Upper.Color
                          CLR_NONE,                   // color  Donchian.Lower.Color

                          "",                         // string ____________________________
                          0,                          // int    Show123Projections
                          false,                      // bool   ShowChartLegend
                          -1,                         // int    MaxBarsBack

                          "",                         // string ____________________________
                          false,                      // bool   Signal.onReversal
                          "",                         // string Signal.onReversal.Types
                          false,                      // bool   Signal.onBreakout
                          false,                      // bool   Signal.onBreakout.123Only
                          "",                         // string Signal.onBreakout.Types
                          "",                         // string Signal.Sound.Up
                          "",                         // string Signal.Sound.Down
                          false,                      // bool   Sound.onChannelWidening
                          "",                         // string Sound.onNewChannelHigh
                          "",                         // string Sound.onNewChannelLow

                          "",                         // string ____________________________
                          false,                      // bool   AutoConfiguration
                          lpSuperContext,             // int    __lpSuperContext

                          iBuffer, iBar);

   int error = GetLastError();
   if (error != NO_ERROR) {
      if (error != ERS_HISTORY_UPDATE) return(!catch("icZigZag(1)", error));
      logWarn("icZigZag(2)  "+ PeriodDescription(timeframe) +" (tick="+ Ticks +")", ERS_HISTORY_UPDATE);
   }

   error = __ExecutionContext[EC.mqlError];           // TODO: synchronize execution contexts
   if (!error) return(value);
   return(!SetLastError(error));
}