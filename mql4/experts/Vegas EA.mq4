/**
 * A combination of ideas from the "Vegas H1 Tunnel" system, the "Turtle Trading" system and a grid for scaling in/out.
 *
 *  @see [Vegas H1 Tunnel Method] https://www.forexfactory.com/thread/4365-all-vegas-documents-located-here
 *  @see [Turtle Trading]         https://analyzingalpha.com/turtle-trading
 *  @see [Turtle Trading]         http://web.archive.org/web/20220417032905/https://vantagepointtrading.com/top-trader-richard-dennis-turtle-trading-strategy/
 *
 *
 * Features
 * --------
 *  � A finished test can be loaded into an online chart for trade inspection and further analysis.
 *
 *  � The EA constantly writes a status file with complete runtime data and detailed trade statistics (more detailed than
 *    the built-in functionality). This status file can be used to move a running EA instance with all historic runtime data
 *    between different machines (e.g. from laptop to VPS).
 *
 *  � The EA supports a "virtual trading mode" in which all trades are only emulated. This makes it possible to hide all
 *    trading related deviations that impact test or real results (tester bugs, spread, slippage, swap, commission).
 *    It allows the EA to be tested and adjusted under idealised conditions.
 *
 *  � The EA contains a recorder that can record several performance graphs simultaneously at runtime (also in tester).
 *    These recordings are saved as regular chart symbols in the history directory of a second MT4 terminal. They can be
 *    displayed and analysed like regular MT4 symbols.
 *
 *
 * Requirements
 * ------------
 *  � MA Tunnel indicator: @see https://github.com/rosasurfer/mt4-mql/blob/master/mql4/indicators/MA%20Tunnel.mq4
 *  � ZigZag indicator:    @see https://github.com/rosasurfer/mt4-mql/blob/master/mql4/indicators/ZigZag.mq4
 *
 *
 * Input parameters
 * ----------------
 *  � Instance.ID:        ...
 *  � Tunnel.Definition:  ...
 *  � Donchian.Periods:   ...
 *  � Lots:               ...
 *  � EA.Recorder:        Metrics to record, for syntax @see https://github.com/rosasurfer/mt4-mql/blob/master/mql4/include/core/expert.recorder.mqh
 *
 *     1: Records real PnL after all costs in account currency (net).
 *     2: Records real PnL after all costs in price units (net).
 *     3: Records signal level PnL before spread/any costs in price units.
 *
 *     Metrics in price units are recorded in the best matching unit. That's pip for Forex or full points otherwise.
 *
 *
 * External control
 * ----------------
 * The EA can be controlled via execution of the following scripts (online and in tester):
 *  � EA.Stop
 *  � EA.Restart
 *  � EA.ToggleMetrics
 *  � Chart.ToggleOpenOrders
 *  � Chart.ToggleTradeHistory
 *
 *
 *
 * TODO:
 *  - implement partial profit taking
 *     manage/track partial open/closed positions
 *     add break-even stop
 *     add exit strategies
 *
 *  - track runup/down per position
 *  - convert signal constants to array
 *  - add entry strategies
 *  - add virtual trading
 *  - add input "TradingTimeframe"
 *  - document input params, control scripts and general usage
 */
#include <stddefines.mqh>
int   __InitFlags[] = {INIT_PIPVALUE, INIT_BUFFERED_LOG};
int __DeinitFlags[];
int __virtualTicks = 0;

////////////////////////////////////////////////////// Configuration ////////////////////////////////////////////////////////

extern string Instance.ID          = "";                             // instance to load from a status file, format "[T]123"
extern string Tunnel.Definition    = "EMA(9), EMA(36), EMA(144)";    // one or more MA definitions separated by comma
extern string Supported.MA.Methods = "SMA, LWMA, EMA, SMMA";
extern int    Donchian.Periods     = 30;

extern double Lots                 = 1.0;

extern int    Initial.TakeProfit   = 100;                            // in pip (0: partial targets only or no TP)
extern int    Initial.StopLoss     = 50;                             // in pip (0: moving stops only or no SL

extern int    Target1              = 0;                              // in pip (0: no target)
extern int    Target1.ClosePercent = 0;                              // size to close (0: nothing)
extern int    Target1.MoveStopTo   = 1;                              // in pip (0: don't move stop)
extern int    Target2              = 0;                              // ...
extern int    Target2.ClosePercent = 30;                             //
extern int    Target2.MoveStopTo   = 0;                              //
extern int    Target3              = 0;                              //
extern int    Target3.ClosePercent = 30;                             //
extern int    Target3.MoveStopTo   = 0;                              //
extern int    Target4              = 0;                              //
extern int    Target4.ClosePercent = 30;                             //
extern int    Target4.MoveStopTo   = 0;                              //

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <core/expert.mqh>
#include <stdfunctions.mqh>
#include <rsfLib.mqh>
#include <functions/HandleCommands.mqh>
#include <functions/IsBarOpen.mqh>
#include <functions/iCustom/MaTunnel.mqh>
#include <functions/iCustom/ZigZag.mqh>
#include <structs/rsf/OrderExecution.mqh>

#include <ea/functions/instance/defines.mqh>
#include <ea/functions/metric/defines.mqh>
#include <ea/functions/status/defines.mqh>
#include <ea/functions/trade/defines.mqh>
#include <ea/functions/trade/signal/defines.mqh>
#include <ea/functions/trade/stats/defines.mqh>

#define STRATEGY_ID     108                  // unique strategy id (used for magic order numbers)

#define SIGNAL_LONG       1                  // signal types
#define SIGNAL_SHORT      2                  //

// instance data
int      instance.id;                        // used for magic order numbers
string   instance.name = "";
datetime instance.created;
bool     instance.isTest;
int      instance.status;
double   instance.startEquity;

double   instance.openNetProfit;             // real PnL after all costs in money (net)
double   instance.closedNetProfit;           //
double   instance.totalNetProfit;            //
double   instance.maxNetProfit;              // max. observed profit:   0...+n
double   instance.maxNetDrawdown;            // max. observed drawdown: -n...0

double   instance.openNetProfitP;            // real PnL after all costs in point (net)
double   instance.closedNetProfitP;          //
double   instance.totalNetProfitP;           //
double   instance.maxNetProfitP;             //
double   instance.maxNetDrawdownP;           //

double   instance.openSigProfitP;            // signal PnL before spread/any costs in point
double   instance.closedSigProfitP;          //
double   instance.totalSigProfitP;           //
double   instance.maxSigProfitP;             //
double   instance.maxSigDrawdownP;           //

// debug settings                            // configurable via framework config, see afterInit()
bool     test.onStopPause        = false;    // whether to pause a test after StopInstance()
bool     test.reduceStatusWrites = true;     // whether to reduce status file I/O in tester

// initialization/deinitialization
#include <ea/vegas-ea/init.mqh>
#include <ea/vegas-ea/deinit.mqh>

// shared functions
#include <ea/functions/instance/CreateInstanceId.mqh>
#include <ea/functions/instance/IsTestInstance.mqh>
#include <ea/functions/instance/RestoreInstance.mqh>
#include <ea/functions/instance/SetInstanceId.mqh>

#include <ea/functions/log/GetLogFilename.mqh>

#include <ea/functions/metric/Recorder_GetSymbolDefinition.mqh>
#include <ea/functions/metric/RecordMetrics.mqh>

#include <ea/functions/status/StatusToStr.mqh>
#include <ea/functions/status/StatusDescription.mqh>
#include <ea/functions/status/SS.MetricDescription.mqh>
#include <ea/functions/status/SS.OpenLots.mqh>
#include <ea/functions/status/SS.ClosedTrades.mqh>
#include <ea/functions/status/SS.TotalProfit.mqh>
#include <ea/functions/status/SS.ProfitStats.mqh>
#include <ea/functions/status/ShowTradeHistory.mqh>

#include <ea/functions/status/file/FindStatusFile.mqh>
#include <ea/functions/status/file/GetStatusFilename.mqh>
#include <ea/functions/status/file/ReadStatus.General.mqh>
#include <ea/functions/status/file/ReadStatus.Targets.mqh>
#include <ea/functions/status/file/ReadStatus.OpenPosition.mqh>
#include <ea/functions/status/file/ReadStatus.HistoryRecord.mqh>
#include <ea/functions/status/file/ReadStatus.TradeHistory.mqh>
#include <ea/functions/status/file/ReadStatus.TradeStats.mqh>
#include <ea/functions/status/file/SaveStatus.General.mqh>
#include <ea/functions/status/file/SaveStatus.Targets.mqh>
#include <ea/functions/status/file/SaveStatus.OpenPosition.mqh>
#include <ea/functions/status/file/SaveStatus.TradeHistory.mqh>
#include <ea/functions/status/file/SaveStatus.TradeStats.mqh>

#include <ea/functions/status/volatile/StoreVolatileStatus.mqh>
#include <ea/functions/status/volatile/RestoreVolatileStatus.mqh>
#include <ea/functions/status/volatile/RemoveVolatileStatus.mqh>
#include <ea/functions/status/volatile/ToggleOpenOrders.mqh>
#include <ea/functions/status/volatile/ToggleTradeHistory.mqh>
#include <ea/functions/status/volatile/ToggleMetrics.mqh>

#include <ea/functions/trade/CalculateMagicNumber.mqh>
#include <ea/functions/trade/IsMyOrder.mqh>
#include <ea/functions/trade/AddHistoryRecord.mqh>
#include <ea/functions/trade/HistoryRecordToStr.mqh>
#include <ea/functions/trade/MovePositionToHistory.mqh>

#include <ea/functions/trade/stats/CalculateStats.mqh>

#include <ea/functions/validation/ValidateInputs.ID.mqh>
#include <ea/functions/validation/ValidateInputs.Targets.mqh>
#include <ea/functions/validation/onInputError.mqh>


/**
 * Main function
 *
 * @return int - error status
 */
int onTick() {
   if (!instance.status) return(catch("onTick(1)  illegal instance.status: "+ instance.status, ERR_ILLEGAL_STATE));

   if (__isChart) HandleCommands();                // process incoming commands, may switch on/off the instance

   if (instance.status != STATUS_STOPPED) {
      int signal;
      IsTradeSignal(signal);
      UpdateStatus(signal);
      RecordMetrics();
   }
   return(last_error);
}


/**
 * Process an incoming command.
 *
 * @param  string cmd    - command name
 * @param  string params - command parameters
 * @param  int    keys   - pressed modifier keys
 *
 * @return bool - success status of the executed command
 */
bool onCommand(string cmd, string params, int keys) {
   string fullCmd = cmd +":"+ params +":"+ keys;

   if (cmd == "stop") {
      switch (instance.status) {
         case STATUS_WAITING:
         case STATUS_TRADING:
            logInfo("onCommand(1)  "+ instance.name +" "+ DoubleQuoteStr(fullCmd));
            return(StopInstance());
      }
   }
   else if (cmd == "restart") {
      switch (instance.status) {
         case STATUS_STOPPED:
            logInfo("onCommand(2)  "+ instance.name +" "+ DoubleQuoteStr(fullCmd));
            return(RestartInstance());
      }
   }
   else if (cmd == "toggle-metrics") {
      int direction = ifInt(keys & F_VK_SHIFT, METRIC_PREVIOUS, METRIC_NEXT);
      return(ToggleMetrics(direction, METRIC_NET_MONEY, METRIC_SIG_UNITS));
   }
   else if (cmd == "toggle-open-orders") {
      return(ToggleOpenOrders());
   }
   else if (cmd == "toggle-trade-history") {
      return(ToggleTradeHistory());
   }
   else return(!logNotice("onCommand(3)  "+ instance.name +" unsupported command: "+ DoubleQuoteStr(fullCmd)));

   return(!logWarn("onCommand(4)  "+ instance.name +" cannot execute command "+ DoubleQuoteStr(fullCmd) +" in status "+ StatusToStr(instance.status)));
}


/**
 * Whether a trade signal occurred.
 *
 * @param  _Out_ int &signal - variable receiving the signal identifier of a triggered condition
 *
 * @return bool
 */
bool IsTradeSignal(int &signal) {
   signal = NULL;
   if (last_error != NULL) return(false);

   // MA Tunnel signal ------------------------------------------------------------------------------------------------------
   if (IsMaTunnelSignal(signal)) {
      return(true);
   }

   // ZigZag signal ---------------------------------------------------------------------------------------------------------
   if (false) /*&&*/ if (IsZigZagSignal(signal)) {
      return(true);
   }
   return(false);
}


/**
 * Whether a new MA tunnel crossing occurred.
 *
 * @param  _Out_ int &signal - variable receiving the signal identifier: SIGNAL_LONG | SIGNAL_SHORT
 *
 * @return bool
 */
bool IsMaTunnelSignal(int &signal) {
   if (last_error != NULL) return(false);
   signal = NULL;

   static int lastTick, lastResult;

   if (Ticks == lastTick) {
      signal = lastResult;
   }
   else {
      if (IsBarOpen()) {
         int trend = icMaTunnel(NULL, Tunnel.Definition, MaTunnel.MODE_BAR_TREND, 1);
         if      (trend == +1) signal = SIGNAL_LONG;
         else if (trend == -1) signal = SIGNAL_SHORT;

         if (signal != NULL) {
            if (IsLogNotice()) logNotice("IsMaTunnelSignal(1)  "+ instance.name +" "+ ifString(signal==SIGNAL_LONG, "long", "short") +" crossing (market: "+ NumberToStr(Bid, PriceFormat) +"/"+ NumberToStr(Ask, PriceFormat) +")");
         }
      }
      lastTick = Ticks;
      lastResult = signal;
   }
   return(signal != NULL);
}


/**
 * Whether a new ZigZag reversal occurred.
 *
 * @param  _Out_ int &signal - variable receiving the signal identifier: SIGNAL_LONG | SIGNAL_SHORT
 *
 * @return bool
 */
bool IsZigZagSignal(int &signal) {
   if (last_error != NULL) return(false);
   signal = NULL;

   static int lastTick, lastResult, lastSignal, lastSignalBar;
   int trend, reversal;

   if (Ticks == lastTick) {
      signal = lastResult;
   }
   else {
      // TODO: error on triple-crossing at bar 0 or 1
      //  - extension down, then reversal up, then reversal down           e.g. ZigZag(20), GBPJPY,M5 2023.12.18 00:00
      if (!GetZigZagData(0, trend, reversal)) return(!logError("IsZigZagSignal(1)  "+ instance.name +" GetZigZagData(0) => FALSE", ERR_RUNTIME_ERROR));
      int absTrend = Abs(trend);

      // The same value denotes a regular reversal, reversal==0 && absTrend==1 denotes a double crossing.
      if (absTrend==reversal || (!reversal && absTrend==1)) {
         if (trend > 0) signal = SIGNAL_LONG;
         else           signal = SIGNAL_SHORT;

         if (Time[0]==lastSignalBar && signal==lastSignal) {
            signal = NULL;
         }
         else {
            if (IsLogNotice()) logNotice("IsZigZagSignal(2)  "+ instance.name +" "+ ifString(signal==SIGNAL_LONG, "long", "short") +" reversal (market: "+ NumberToStr(Bid, PriceFormat) +"/"+ NumberToStr(Ask, PriceFormat) +")");
            lastSignal = signal;
            lastSignalBar = Time[0];
         }
      }
      lastTick = Ticks;
      lastResult = signal;
   }
   return(signal != NULL);
}


/**
 * Get ZigZag data at the specified bar offset.
 *
 * @param  _In_  int bar       - bar offset
 * @param  _Out_ int &trend    - combined trend value (buffers MODE_KNOWN_TREND + MODE_UNKNOWN_TREND)
 * @param  _Out_ int &reversal - bar offset of current ZigZag reversal to previous ZigZag extreme
 *
 * @return bool - success status
 */
bool GetZigZagData(int bar, int &trend, int &reversal) {
   trend    = MathRound(icZigZag(NULL, Donchian.Periods, ZigZag.MODE_TREND,    bar));
   reversal = MathRound(icZigZag(NULL, Donchian.Periods, ZigZag.MODE_REVERSAL, bar));
   return(!last_error && trend);
}


/**
 * Update client-side order status and PnL.
 *
 * @param  int signal [optional] - trade signal causing the call (default: none, update status only)
 *
 * @return bool - success status
 */
bool UpdateStatus(int signal = NULL) {
   if (last_error || instance.status!=STATUS_TRADING) return(false);
   bool positionClosed = false;

   // update open position
   if (open.ticket != NULL) {
      if (!SelectTicket(open.ticket, "UpdateStatus(1)")) return(false);
      bool isClosed = (OrderCloseTime() != NULL);
      if (isClosed) {
         double exitPrice=OrderClosePrice(), exitPriceSig=exitPrice;
      }
      else {
         exitPrice = ifDouble(open.type==OP_BUY, Bid, Ask);
         exitPriceSig = Bid;
      }
      open.swap         = NormalizeDouble(OrderSwap(), 2);
      open.commission   = OrderCommission();
      open.grossProfit  = OrderProfit();
      open.netProfit    = open.grossProfit + open.swap + open.commission;
      open.netProfitP   = ifDouble(open.type==OP_BUY, exitPrice-open.price, open.price-exitPrice);
      open.runupP       = MathMax(open.runupP, open.netProfitP);
      open.drawdownP    = MathMin(open.drawdownP, open.netProfitP); if (open.swap || open.commission) open.netProfitP += (open.swap + open.commission)/PointValue(open.lots);
      open.sigProfitP   = ifDouble(open.type==OP_BUY, exitPriceSig-open.priceSig, open.priceSig-exitPriceSig);
      open.sigRunupP    = MathMax(open.sigRunupP, open.sigProfitP);
      open.sigDrawdownP = MathMin(open.sigDrawdownP, open.sigProfitP);

      if (isClosed) {
         int error;
         if (IsError(onPositionClose("UpdateStatus(2)  "+ instance.name +" "+ UpdateStatus.PositionCloseMsg(error), error))) return(false);
         if (!MovePositionToHistory(OrderCloseTime(), exitPrice, exitPriceSig))                                              return(false);
         positionClosed = true;
      }
   }

   // process signal
   if (signal != NULL) {
      instance.status = STATUS_TRADING;

      // close an existing open position
      if (open.ticket != NULL) {
         if (open.type != ifInt(signal==SIGNAL_SHORT, OP_LONG, OP_SHORT)) return(!catch("UpdateStatus(3)  "+ instance.name +" cannot process "+ SignalToStr(signal) +" with open "+ OperationTypeToStr(open.type) +" position", ERR_ILLEGAL_STATE));

         int oeFlags, oe[];
         if (!OrderCloseEx(open.ticket, NULL, NULL, CLR_CLOSED, oeFlags, oe)) return(!SetLastError(oe.Error(oe)));

         double closePrice = oe.ClosePrice(oe);
         open.slippage    += oe.Slippage(oe);
         open.swap         = oe.Swap(oe);
         open.commission   = oe.Commission(oe);
         open.grossProfit  = oe.Profit(oe);
         open.netProfit    = open.grossProfit + open.swap + open.commission;
         open.netProfitP   = ifDouble(open.type==OP_BUY, closePrice-open.price, open.price-closePrice);
         open.runupP       = MathMax(open.runupP, open.netProfitP);
         open.drawdownP    = MathMin(open.drawdownP, open.netProfitP); if (open.swap || open.commission) open.netProfitP += (open.swap + open.commission)/PointValue(open.lots);
         open.sigProfitP   = ifDouble(open.type==OP_BUY, Bid-open.priceSig, open.priceSig-Bid);
         open.sigRunupP    = MathMax(open.sigRunupP, open.sigProfitP);
         open.sigDrawdownP = MathMin(open.sigDrawdownP, open.sigProfitP);

         if (!MovePositionToHistory(oe.CloseTime(oe), closePrice, Bid)) return(false);
      }

      // open new position
      int      type        = ifInt(signal==SIGNAL_LONG, OP_BUY, OP_SELL);
      double   price       = NULL;
      double   stopLoss    = NULL;
      double   takeProfit  = NULL;
      string   comment     = "Vegas."+ StrPadLeft(instance.id, 3, "0");
      int      magicNumber = CalculateMagicNumber(instance.id);
      datetime expires     = NULL;
      color    markerColor = ifInt(signal==SIGNAL_LONG, CLR_OPEN_LONG, CLR_OPEN_SHORT);
               oeFlags     = NULL;

      int ticket = OrderSendEx(NULL, type, Lots, price, order.slippage, stopLoss, takeProfit, comment, magicNumber, expires, markerColor, oeFlags, oe);
      if (!ticket) return(!SetLastError(oe.Error(oe)));

      // store the new position
      open.ticket       = ticket;
      open.type         = type;
      open.lots         = oe.Lots(oe);
      open.time         = oe.OpenTime(oe);
      open.price        = oe.OpenPrice(oe);
      open.priceSig     = Bid;
      open.slippage     = oe.Slippage(oe);
      open.swap         = oe.Swap(oe);
      open.commission   = oe.Commission(oe);
      open.grossProfit  = oe.Profit(oe);
      open.netProfit    = open.grossProfit + open.swap + open.commission;
      open.netProfitP   = ifDouble(open.type==OP_BUY, Bid-open.price, open.price-Ask); if (open.swap || open.commission) open.netProfitP += (open.swap + open.commission)/PointValue(open.lots);
      open.runupP       = ifDouble(open.type==OP_BUY, Bid-open.price, open.price-Ask);
      open.drawdownP    = open.runupP;
      open.sigProfitP   = 0;
      open.sigRunupP    = open.sigProfitP;
      open.sigDrawdownP = open.sigRunupP;
      if (__isChart) SS.OpenLots();
   }

   // update PL numbers
   instance.openNetProfit  = open.netProfit;
   instance.openNetProfitP = open.netProfitP;
   instance.openSigProfitP = open.sigProfitP;

   instance.totalNetProfit  = instance.openNetProfit  + instance.closedNetProfit;
   instance.totalNetProfitP = instance.openNetProfitP + instance.closedNetProfitP;
   instance.totalSigProfitP = instance.openSigProfitP + instance.closedSigProfitP;
   if (__isChart) SS.TotalProfit();

   instance.maxNetProfit    = MathMax(instance.maxNetProfit,    instance.totalNetProfit);
   instance.maxNetDrawdown  = MathMin(instance.maxNetDrawdown,  instance.totalNetProfit);
   instance.maxNetProfitP   = MathMax(instance.maxNetProfitP,   instance.totalNetProfitP);
   instance.maxNetDrawdownP = MathMin(instance.maxNetDrawdownP, instance.totalNetProfitP);
   instance.maxSigProfitP   = MathMax(instance.maxSigProfitP,   instance.totalSigProfitP);
   instance.maxSigDrawdownP = MathMin(instance.maxSigDrawdownP, instance.totalSigProfitP);
   if (__isChart) SS.ProfitStats();

   if (positionClosed || signal)
      return(SaveStatus());
   return(!catch("UpdateStatus(4)"));
}


/**
 * Compose a log message for a closed position. The ticket must be selected.
 *
 * @param  _Out_ int error - error code to be returned from the call (if any)
 *
 * @return string - log message or an empty string in case of errors
 */
string UpdateStatus.PositionCloseMsg(int &error) {
   // #1 Sell 0.1 GBPUSD at 1.5457'2 ("ID.869") was [unexpectedly ]closed [by SL ]at 1.5457'2 (market: Bid/Ask[, so: 47.7%/169.20/354.40])
   error = NO_ERROR;

   int    ticket      = OrderTicket();
   double lots        = OrderLots();
   string sType       = OperationTypeDescription(OrderType());
   string sOpenPrice  = NumberToStr(OrderOpenPrice(), PriceFormat);
   string sClosePrice = NumberToStr(OrderClosePrice(), PriceFormat);
   string sUnexpected = ifString(__isTesting && __CoreFunction==CF_DEINIT, "", "unexpectedly ");
   string message     = "#"+ ticket +" "+ sType +" "+ NumberToStr(lots, ".+") +" "+ OrderSymbol() +" at "+ sOpenPrice +" (\""+ instance.name +"\") was "+ sUnexpected +"closed at "+ sClosePrice;

   string sStopout = "";
   if (StrStartsWithI(OrderComment(), "so:")) {       error = ERR_MARGIN_STOPOUT; sStopout = ", "+ OrderComment(); }
   else if (__isTesting && __CoreFunction==CF_DEINIT) error = NO_ERROR;
   else                                               error = ERR_CONCURRENT_MODIFICATION;

   return(message +" (market: "+ NumberToStr(Bid, PriceFormat) +"/"+ NumberToStr(Ask, PriceFormat) + sStopout +")");
}


/**
 * Event handler for an unexpectedly closed position.
 *
 * @param  string message - error message
 * @param  int    error   - error code
 *
 * @return int - error status, i.e. whether to interrupt program execution
 */
int onPositionClose(string message, int error) {
   if (!error) return(logInfo(message));                    // no error

   if (error == ERR_ORDER_CHANGED)                          // expected in a fast market: a SL was triggered
      return(!logNotice(message, error));                   // continue

   if (__isTesting) return(catch(message, error));          // in tester treat everything else as terminating

   logWarn(message, error);                                 // online
   if (error == ERR_CONCURRENT_MODIFICATION)                // unexpected: most probably manually closed
      return(NO_ERROR);                                     // continue
   return(error);
}


/**
 * Stop a waiting or progressing instance and close open positions (if any).
 *
 * @return bool - success status
 */
bool StopInstance() {
   if (last_error != NULL)                                                 return(false);
   if (instance.status!=STATUS_WAITING && instance.status!=STATUS_TRADING) return(!catch("StopInstance(1)  "+ instance.name +" cannot stop "+ StatusDescription(instance.status) +" instance", ERR_ILLEGAL_STATE));

   // close an open position
   if (instance.status == STATUS_TRADING) {
      if (open.ticket > 0) {
         if (IsLogInfo()) logInfo("StopInstance(2)  "+ instance.name +" stopping");
         int oeFlags, oe[];
         if (!OrderCloseEx(open.ticket, NULL, NULL, CLR_CLOSED, oeFlags, oe)) return(!SetLastError(oe.Error(oe)));

         double closePrice = oe.ClosePrice(oe);
         open.slippage    += oe.Slippage  (oe);
         open.swap         = oe.Swap      (oe);
         open.commission   = oe.Commission(oe);
         open.grossProfit  = oe.Profit    (oe);
         open.netProfit    = open.grossProfit + open.swap + open.commission;
         open.netProfitP   = ifDouble(open.type==OP_BUY, closePrice-open.price, open.price-closePrice);
         open.runupP       = MathMax(open.runupP, open.netProfitP);
         open.drawdownP    = MathMin(open.drawdownP, open.netProfitP); open.netProfitP += (open.swap + open.commission)/PointValue(open.lots);
         open.sigProfitP   = ifDouble(open.type==OP_BUY, Bid-open.priceSig, open.priceSig-Bid);
         open.sigRunupP    = MathMax(open.sigRunupP, open.sigProfitP);
         open.sigDrawdownP = MathMin(open.sigDrawdownP, open.sigProfitP);

         if (!MovePositionToHistory(oe.CloseTime(oe), closePrice, Bid)) return(false);

         // update PL numbers
         instance.openNetProfit  = open.netProfit;
         instance.totalNetProfit = instance.openNetProfit + instance.closedNetProfit;
         instance.maxNetProfit   = MathMax(instance.maxNetProfit,   instance.totalNetProfit);
         instance.maxNetDrawdown = MathMin(instance.maxNetDrawdown, instance.totalNetProfit);

         instance.openNetProfitP  = open.netProfitP;
         instance.totalNetProfitP = instance.openNetProfitP + instance.closedNetProfitP;
         instance.maxNetProfitP   = MathMax(instance.maxNetProfitP,   instance.totalNetProfitP);
         instance.maxNetDrawdownP = MathMin(instance.maxNetDrawdownP, instance.totalNetProfitP);

         instance.openSigProfitP  = open.sigProfitP;
         instance.totalSigProfitP = instance.openSigProfitP + instance.closedSigProfitP;
         instance.maxSigProfitP   = MathMax(instance.maxSigProfitP,   instance.totalSigProfitP);
         instance.maxSigDrawdownP = MathMin(instance.maxSigDrawdownP, instance.totalSigProfitP);
      }
   }

   // update status
   instance.status = STATUS_STOPPED;
   SS.TotalProfit();
   SS.ProfitStats();

   if (IsLogInfo()) logInfo("StopInstance(3)  "+ instance.name +" "+ ifString(__isTesting, "test ", "") +"instance stopped, profit: "+ status.totalProfit +" "+ status.profitStats);
   SaveStatus();

   // pause/stop the tester according to the debug configuration
   if (__isTesting) {
      if      (!IsVisualMode())  Tester.Stop ("StopInstance(4)");
      else if (test.onStopPause) Tester.Pause("StopInstance(5)");
   }
   return(!catch("StopInstance(6)"));
}


/**
 * Restart a stopped instance.
 *
 * @return bool - success status
 */
bool RestartInstance() {
   if (last_error != NULL)                return(false);
   if (instance.status != STATUS_STOPPED) return(!catch("RestartInstance(1)  "+ instance.name +" cannot restart "+ StatusDescription(instance.status) +" instance", ERR_ILLEGAL_STATE));
   return(!catch("RestartInstance(2)", ERR_NOT_IMPLEMENTED));
}


/**
 * Read the status file of an instance and restore inputs and runtime variables. Called only from RestoreInstance().
 *
 * @return bool - success status
 */
bool ReadStatus() {
   if (IsLastError()) return(false);
   if (!instance.id)  return(!catch("ReadStatus(1)  "+ instance.name +" illegal value of instance.id: "+ instance.id, ERR_ILLEGAL_STATE));

   string section="", file=FindStatusFile(instance.id, instance.isTest);
   if (file == "")                 return(!catch("ReadStatus(2)  "+ instance.name +" status file not found", ERR_RUNTIME_ERROR));
   if (!IsFile(file, MODE_SYSTEM)) return(!catch("ReadStatus(3)  "+ instance.name +" file "+ DoubleQuoteStr(file) +" not found", ERR_FILE_NOT_FOUND));

   // [General]
   if (!ReadStatus.General(file)) return(false);

   // [Inputs]
   section = "Inputs";
   Instance.ID              = GetIniStringA(file, section, "Instance.ID",       "");         // string   Instance.ID       = T123
   Tunnel.Definition        = GetIniStringA(file, section, "Tunnel.Definition", "");         // string   Tunnel.Definition = EMA(1), EMA(2), EMA(3)
   Donchian.Periods         = GetIniInt    (file, section, "Donchian.Periods"     );         // int      Donchian.Periods  = 40
   Lots                     = GetIniDouble (file, section, "Lots"                 );         // double   Lots              = 0.1
   if (!ReadStatus.Targets(file)) return(false);
   EA.Recorder              = GetIniStringA(file, section, "EA.Recorder",       "");         // string   EA.Recorder       = 1,2,4

   // [Runtime status]
   section = "Runtime status";
   instance.id              = GetIniInt    (file, section, "instance.id"      );             // int      instance.id              = 123
   instance.name            = GetIniStringA(file, section, "instance.name", "");             // string   instance.name            = V.123
   instance.created         = GetIniInt    (file, section, "instance.created" );             // datetime instance.created         = 1624924800 (Mon, 2021.05.12 13:22:34)
   instance.isTest          = GetIniBool   (file, section, "instance.isTest"  );             // bool     instance.isTest          = 1
   instance.status          = GetIniInt    (file, section, "instance.status"  );             // int      instance.status          = 1 (waiting)
   recorder.stdEquitySymbol = GetIniStringA(file, section, "recorder.stdEquitySymbol", "");  // string   recorder.stdEquitySymbol = GBPJPY.001
   SS.InstanceName();

   // open/closed trades and stats
   if (!ReadStatus.TradeStats(file))   return(false);
   if (!ReadStatus.OpenPosition(file)) return(false);
   if (!ReadStatus.TradeHistory(file)) return(false);

   return(!catch("ReadStatus(4)"));
}


/**
 * Synchronize runtime state and vars with current order status on the trade server. Called only from RestoreInstance().
 *
 * @return bool - success status
 */
bool SynchronizeStatus() {
   if (IsLastError()) return(false);

   // detect & handle dangling open positions
   for (int i=OrdersTotal()-1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;     // FALSE: an open order was closed/deleted in another thread
      if (IsMyOrder(instance.id)) {
         // TODO
      }
   }

   // detect & handle dangling closed positions
   for (i=OrdersHistoryTotal()-1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if (IsPendingOrderType(OrderType()))              continue;    // skip deleted pending orders (atm not supported)

      if (IsMyOrder(instance.id)) {
         // TODO
      }
   }

   SS.All();
   return(!catch("SynchronizeStatus(1)"));
}


/**
 * Write the current instance status to a file.
 *
 * @return bool - success status
 */
bool SaveStatus() {
   if (last_error != NULL)              return(false);
   if (!instance.id || Instance.ID=="") return(!catch("SaveStatus(1)  illegal instance id: "+ instance.id +" (Instance.ID="+ DoubleQuoteStr(Instance.ID) +")", ERR_ILLEGAL_STATE));
   if (__isTesting) {
      if (test.reduceStatusWrites) {                           // in tester skip most writes except file creation, instance stop and test end
         static bool saved = false;
         if (saved && instance.status!=STATUS_STOPPED && __CoreFunction!=CF_DEINIT) return(true);
         saved = true;
      }
   }
   else if (IsTestInstance()) return(true);                    // don't change the status file of a finished test

   string section="", separator="", file=GetStatusFilename();
   bool fileExists = IsFile(file, MODE_SYSTEM);
   if (!fileExists) separator = CRLF;                          // an empty line separator
   SS.All();                                                   // update trade stats and global string representations

   // [General]
   if (!SaveStatus.General(file, fileExists)) return(false);   // account and instrument infos

   // [Inputs]
   section = "Inputs";
   WriteIniString(file, section, "Instance.ID",                /*string  */ Instance.ID);
   WriteIniString(file, section, "Tunnel.Definition",          /*string  */ Tunnel.Definition);
   WriteIniString(file, section, "Donchian.Periods",           /*int     */ Donchian.Periods);
   WriteIniString(file, section, "Lots",                       /*double  */ NumberToStr(Lots, ".+"));
   if (!SaveStatus.Targets(file, true)) return(false);         // StopLoss and TakeProfit targets
   WriteIniString(file, section, "EA.Recorder",                /*string  */ EA.Recorder + separator);

   // trade stats
   if (!SaveStatus.TradeStats(file, fileExists)) return(false);

   // [Runtime status]
   section = "Runtime status";
   WriteIniString(file, section, "instance.id",                /*int     */ instance.id);
   WriteIniString(file, section, "instance.name",              /*string  */ instance.name);
   WriteIniString(file, section, "instance.created",           /*datetime*/ instance.created + GmtTimeFormat(instance.created, " (%a, %Y.%m.%d %H:%M:%S)"));
   WriteIniString(file, section, "instance.isTest",            /*bool    */ instance.isTest);
   WriteIniString(file, section, "instance.status",            /*int     */ instance.status +" ("+ StatusDescription(instance.status) +")" + separator);

   WriteIniString(file, section, "recorder.stdEquitySymbol",   /*string  */ recorder.stdEquitySymbol + separator);

   // open/closed trades
   if (!SaveStatus.OpenPosition(file, fileExists)) return(false);
   if (!SaveStatus.TradeHistory(file, fileExists)) return(false);

   return(!catch("SaveStatus(2)"));
}


// backed-up input parameters
string   prev.Instance.ID = "";
string   prev.Tunnel.Definition = "";
int      prev.Donchian.Periods;
double   prev.Lots;

// backed-up runtime variables affected by changing input parameters
int      prev.instance.id;
datetime prev.instance.created;
bool     prev.instance.isTest;
string   prev.instance.name = "";
int      prev.instance.status;


/**
 * When input parameters are changed at runtime, input errors must be handled gracefully. To enable the EA to continue in
 * case of input errors, it must be possible to restore previous valid inputs. This also applies to programmatic changes to
 * input parameters which do not survive init cycles. The previous input parameters are therefore backed up in deinit() and
 * can be restored in init() if necessary.
 *
 * Called in onDeinitParameters() and onDeinitChartChange().
 */
void BackupInputs() {
   // input parameters, used for comparison in ValidateInputs()
   prev.Instance.ID       = StringConcatenate(Instance.ID, "");         // string inputs are references to internal C literals
   prev.Tunnel.Definition = StringConcatenate(Tunnel.Definition, "");   // and must be copied to break the reference
   prev.Donchian.Periods  = Donchian.Periods;
   prev.Lots              = Lots;

   // affected runtime variables
   prev.instance.id      = instance.id;
   prev.instance.created = instance.created;
   prev.instance.isTest  = instance.isTest;
   prev.instance.name    = instance.name;
   prev.instance.status  = instance.status;

   BackupInputs.Targets();
   BackupInputs.Recorder();
}


/**
 * Restore backed-up input parameters and runtime variables. Called from onInitParameters() and onInitTimeframeChange().
 */
void RestoreInputs() {
   // input parameters
   Instance.ID       = prev.Instance.ID;
   Tunnel.Definition = prev.Tunnel.Definition;
   Donchian.Periods  = prev.Donchian.Periods;
   Lots              = prev.Lots;

   // affected runtime variables
   instance.id      = prev.instance.id;
   instance.created = prev.instance.created;
   instance.isTest  = prev.instance.isTest;
   instance.name    = prev.instance.name;
   instance.status  = prev.instance.status;

   RestoreInputs.Targets();
   RestoreInputs.Recorder();
}


/**
 * Validate all input parameters. Parameters may have been entered through the input dialog, read from a status file or were
 * deserialized and set programmatically by the terminal (e.g. at terminal restart). Called from onInitUser(),
 * onInitParameters() or onInitTemplate().
 *
 * @return bool - whether input parameters are valid
 */
bool ValidateInputs() {
   if (IsLastError()) return(false);
   bool isInitParameters = (ProgramInitReason()==IR_PARAMETERS);  // whether we validate manual or programatic input
   bool hasOpenOrders = false;

   // Instance.ID
   if (isInitParameters) {                                        // otherwise the id was validated in ValidateInputs.ID()
      if (StrTrim(Instance.ID) == "") {                           // the id was deleted or not yet set, restore the internal id
         Instance.ID = prev.Instance.ID;
      }
      else if (Instance.ID != prev.Instance.ID)    return(!onInputError("ValidateInputs(1)  "+ instance.name +" switching to another instance is not supported (unload the EA first)"));
   }

   // Tunnel.Definition
   if (isInitParameters && Tunnel.Definition!=prev.Tunnel.Definition) {
      if (hasOpenOrders)                           return(!onInputError("ValidateInputs(2)  "+ instance.name +" cannot change input parameter Tunnel.Definition with open orders"));
   }
   string sValue, sValues[], sMAs[];
   ArrayResize(sMAs, 0);
   int n=0, size=Explode(Tunnel.Definition, ",", sValues, NULL);
   for (int i=0; i < size; i++) {
      sValue = StrTrim(sValues[i]);
      if (sValue == "") continue;

      string sMethod = StrLeftTo(sValue, "(");
      if (sMethod == sValue)                       return(!onInputError("ValidateInputs(3)  "+ instance.name +" invalid value "+ DoubleQuoteStr(sValue) +" in input parameter Tunnel.Definition: "+ DoubleQuoteStr(Tunnel.Definition) +" (format not \"MaMethod(int)\")"));
      int iMethod = StrToMaMethod(sMethod, F_ERR_INVALID_PARAMETER);
      if (iMethod == -1)                           return(!onInputError("ValidateInputs(4)  "+ instance.name +" invalid MA method "+ DoubleQuoteStr(sMethod) +" in input parameter Tunnel.Definition: "+ DoubleQuoteStr(Tunnel.Definition)));
      if (iMethod > MODE_LWMA)                     return(!onInputError("ValidateInputs(5)  "+ instance.name +" unsupported MA method "+ DoubleQuoteStr(sMethod) +" in input parameter Tunnel.Definition: "+ DoubleQuoteStr(Tunnel.Definition)));

      string sPeriods = StrRightFrom(sValue, "(");
      if (!StrEndsWith(sPeriods, ")"))             return(!onInputError("ValidateInputs(6)  "+ instance.name +" invalid value "+ DoubleQuoteStr(sValue) +" in input parameter Tunnel.Definition: "+ DoubleQuoteStr(Tunnel.Definition) +" (format not \"MaMethod(int)\")"));
      sPeriods = StrTrim(StrLeft(sPeriods, -1));
      if (!StrIsDigits(sPeriods))                  return(!onInputError("ValidateInputs(7)  "+ instance.name +" invalid value "+ DoubleQuoteStr(sValue) +" in input parameter Tunnel.Definition: "+ DoubleQuoteStr(Tunnel.Definition) +" (format not \"MaMethod(int)\")"));
      int iPeriods = StrToInteger(sPeriods);
      if (iPeriods < 1)                            return(!onInputError("ValidateInputs(8)  "+ instance.name +" invalid MA periods "+ iPeriods +" in input parameter Tunnel.Definition: "+ DoubleQuoteStr(Tunnel.Definition) +" (must be > 0)"));

      ArrayResize(sMAs, n+1);
      sMAs[n]  = MaMethodDescription(iMethod) +"("+ iPeriods +")";
      n++;
   }
   if (!n)                                         return(!onInputError("ValidateInputs(9)  "+ instance.name +" missing input parameter Tunnel.Definition (empty)"));
   Tunnel.Definition = JoinStrings(sMAs);

   // Donchian.Periods
   if (isInitParameters && Donchian.Periods!=prev.Donchian.Periods) {
      if (hasOpenOrders)                           return(!onInputError("ValidateInputs(10)  "+ instance.name +" cannot change input parameter Donchian.Periods with open orders"));
   }
   if (Donchian.Periods < 2)                       return(!onInputError("ValidateInputs(11)  "+ instance.name +" invalid input parameter Donchian.Periods: "+ Donchian.Periods +" (must be > 1)"));

   // Lots
   if (LT(Lots, 0))                                return(!onInputError("ValidateInputs(12)  "+ instance.name +" invalid input parameter Lots: "+ NumberToStr(Lots, ".1+") +" (must be > 0)"));
   if (NE(Lots, NormalizeLots(Lots)))              return(!onInputError("ValidateInputs(13)  "+ instance.name +" invalid input parameter Lots: "+ NumberToStr(Lots, ".1+") +" (must be a multiple of MODE_LOTSTEP="+ NumberToStr(MarketInfo(Symbol(), MODE_LOTSTEP), ".+") +")"));

   // Targets
   if (!ValidateInputs.Targets()) return(false);

   // EA.Recorder: on | off* | 1,2,3=1000,...
   if (!Recorder.ValidateInputs(IsTestInstance())) return(false);

   SS.All();
   return(!catch("ValidateInputs(14)"));
}


/**
 * Return a readable representation of a signal constant.
 *
 * @param  int signal
 *
 * @return string - readable constant or an empty string in case of errors
 */
string SignalToStr(int signal) {
   switch (signal) {
      case NULL        : return("no signal"   );
      case SIGNAL_LONG : return("SIGNAL_LONG" );
      case SIGNAL_SHORT: return("SIGNAL_SHORT");
   }
   return(_EMPTY_STR(catch("SignalToStr(1)  "+ instance.name +" invalid parameter signal: "+ signal, ERR_INVALID_PARAMETER)));
}


/**
 * ShowStatus: Update all string representations.
 */
void SS.All() {
   SS.InstanceName();
   SS.MetricDescription();
   SS.OpenLots();
   SS.ClosedTrades();
   SS.TotalProfit();
   SS.ProfitStats();
}


/**
 * ShowStatus: Update the string representation of the instance name.
 */
void SS.InstanceName() {
   instance.name = "V."+ StrPadLeft(instance.id, 3, "0");
}


/**
 * Display the current runtime status.
 *
 * @param  int error [optional] - error to display (default: none)
 *
 * @return int - the same error or the current error status if no error was specified
 */
int ShowStatus(int error = NO_ERROR) {
   if (!__isChart) return(error);

   static bool isRecursion = false;                   // to prevent recursive calls a specified error is displayed only once
   if (error != 0) {
      if (isRecursion) return(error);
      isRecursion = true;
   }
   string sStatus="", sError="";

   switch (instance.status) {
      case NULL:           sStatus = StringConcatenate(instance.name, "  not initialized"); break;
      case STATUS_WAITING: sStatus = StringConcatenate(instance.name, "  waiting");         break;
      case STATUS_TRADING: sStatus = StringConcatenate(instance.name, "  trading");         break;
      case STATUS_STOPPED: sStatus = StringConcatenate(instance.name, "  stopped");         break;
      default:
         return(catch("ShowStatus(1)  "+ instance.name +" illegal instance status: "+ instance.status, ERR_ILLEGAL_STATE));
   }
   if (__STATUS_OFF) sError = StringConcatenate("  [switched off => ", ErrorDescription(__STATUS_OFF.reason), "]");

   string text = StringConcatenate(ProgramName(), "    ", sStatus, sError,                      NL,
                                                                                                NL,
                                   status.metricDescription,                                    NL,
                                   "Open:    ",   status.openLots,                              NL,
                                   "Closed:  ",   status.closedTrades,                          NL,
                                   "Profit:    ", status.totalProfit, "  ", status.profitStats, NL
   );

   // 3 lines margin-top for instrument and indicator legends
   Comment(NL, NL, NL, text);
   if (__CoreFunction == CF_INIT) WindowRedraw();

   // store status in the chart to enable sending of chart commands
   string label = "EA.status";
   if (ObjectFind(label) != 0) {
      ObjectCreate(label, OBJ_LABEL, 0, 0, 0);
      ObjectSet(label, OBJPROP_TIMEFRAMES, OBJ_PERIODS_NONE);
   }
   ObjectSetText(label, StringConcatenate(Instance.ID, "|", StatusDescription(instance.status)));

   error = intOr(catch("ShowStatus(2)"), error);
   isRecursion = false;
   return(error);
}


/**
 * Return a string representation of the input parameters (for logging purposes).
 *
 * @return string
 */
string InputsToStr() {
   return(StringConcatenate("Instance.ID=",          DoubleQuoteStr(Instance.ID),       ";"+ NL +
                            "Tunnel.Definition=",    DoubleQuoteStr(Tunnel.Definition), ";"+ NL +
                            "Donchian.Periods=",     Donchian.Periods,                  ";"+ NL +

                            "Lots=",                 NumberToStr(Lots, ".1+"),          ";"+ NL +
                            "Initial.TakeProfit=",   Initial.TakeProfit,                ";"+ NL +
                            "Initial.StopLoss=",     Initial.StopLoss,                  ";"+ NL +
                            "Target1=",              Target1,                           ";"+ NL +
                            "Target1.ClosePercent=", Target1.ClosePercent,              ";"+ NL +
                            "Target1.MoveStopTo=",   Target1.MoveStopTo,                ";"+ NL +
                            "Target2=",              Target2,                           ";"+ NL +
                            "Target2.ClosePercent=", Target2.ClosePercent,              ";"+ NL +
                            "Target2.MoveStopTo=",   Target2.MoveStopTo,                ";"+ NL +
                            "Target3=",              Target3,                           ";"+ NL +
                            "Target3.ClosePercent=", Target3.ClosePercent,              ";"+ NL +
                            "Target3.MoveStopTo=",   Target3.MoveStopTo,                ";"+ NL +
                            "Target4=",              Target4,                           ";"+ NL +
                            "Target4.ClosePercent=", Target4.ClosePercent,              ";"+ NL +
                            "Target4.MoveStopTo=",   Target4.MoveStopTo,                ";")
   );
}
