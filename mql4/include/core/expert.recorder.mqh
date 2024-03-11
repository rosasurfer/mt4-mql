//
// During runtime an EA can record up to 21 different performance graphs (aka metrics; online and in tester). These recordings
// are saved as regular chart symbols in the history directory of a second MT4 terminal. They can be displayed and analysed
// like regular MT4 symbols.
//
// Metrics to record are configured using input parameter "EA.Recorder". Multiple metric declarations are separated by comma.
//
//  Syntax:
//   off:  Recording is disabled (default).
//   on:   Records a timeseries representing the EA's equity graph as reported by the built-in function AccountEquity().
//   <id>[=<base-value>]:  Records a timeseries representing a custom metric identified by a postive <id> (integer). Specify
//         an appropriate base value (numeric) to ensure that all recorded values are positive (MT4 charts cannot display
//         negative values). Without a value the recorder queries the framework configuration.
//
// During EA initialization the function GetMT4SymbolDefinition() is called for each configured metric to retrieve the
// metric's symbol definition. That function must be implemented by the EA. It has the following signature:
//
// /**
//  * Return a symbol definition for the specified metric to be recorded.
//  *
//  * @param  _In_  int    metricId     - metric id; 0 = standard AccountEquity() symbol, positive integer for custom metrics
//  * @param  _Out_ bool   &ready       - whether metric details are complete and the metric is ready to be recorded
//  * @param  _Out_ string &symbol      - unique MT4 timeseries symbol
//  * @param  _Out_ string &description - symbol description as in the MT4 "Symbols" window (if empty a description is generated)
//  * @param  _Out_ string &group       - symbol group name as in the MT4 "Symbols" window (if empty a name is generated)
//  * @param  _Out_ int    &digits      - symbol digits value
//  * @param  _Out_ double &baseValue   - quotes base value (if EMPTY default settings are used)
//  * @param  _Out_ int    &multiplier  - quotes multiplier
//  *
//  * @return int - error status; especially ERR_INVALID_INPUT_PARAMETER if the passed metric id is unknown or not supported
//  */
// int GetMT4SymbolDefinition(int metricId, bool &ready, string &symbol, string &description, string &group, int &digits, double &baseValue, int &multiplier);
//

// recorder modes
#define RECORDER_OFF          0              // recording off
#define RECORDER_ON           1              // recording of a standard AccountEquity() graph
#define RECORDER_CUSTOM       2              // recording of custom metrics

// recorder settings
int    recorder.mode;
bool   recorder.initialized;
string recorder.stdEquitySymbol = "";        // symbol used with mode = RECORDER_ON
string recorder.hstDirectory    = "";
int    recorder.hstFormat;

string recorder.defaultDescription = "";
string recorder.defaultGroup = "";
double recorder.defaultBaseValue = 10000.0;

// metric details
bool   metric.enabled    [];                 // whether a metric was specified in input "EA.Recorder"
bool   metric.ready      [];                 // whether metric details are complete
string metric.symbol     [];
string metric.description[];
string metric.group      [];
int    metric.digits     [];
double metric.currValue  [];
double metric.baseValue  [];
int    metric.multiplier [];
int    metric.hSet       [];

// backed-up input parameters
string prev.EA.Recorder = "";

// backed-up runtime variables affected by changing input parameters
int    prev.recorder.mode;
bool   prev.recorder.initialized;

bool   prev.metric.enabled    [];
bool   prev.metric.ready      [];
string prev.metric.symbol     [];
string prev.metric.description[];
string prev.metric.group      [];
int    prev.metric.digits     [];
double prev.metric.currValue  [];
double prev.metric.baseValue  [];
int    prev.metric.multiplier [];
int    prev.metric.hSet       [];


/**
 * When input parameters are changed at runtime, input errors must be handled gracefully. To enable the EA to continue in
 * case of input errors, it must be possible to restore previous valid inputs. This also applies to programmatic changes to
 * input parameters which do not survive init cycles. The previous input parameters are therefore backed up in deinit() and
 * can be restored in init() if necessary.
 *
 * Called in onDeinitParameters() and onDeinitChartChange().
 */
void BackupInputs.Recorder() {
   if (!catch("BackupInputs.Recorder(1)")) {
      // input parameters
      prev.EA.Recorder          = StringConcatenate(EA.Recorder, "");   // string inputs are references to internal C literals
      prev.recorder.mode        = recorder.mode;                        // and must be copied to break the reference
      prev.recorder.initialized = recorder.initialized;

      // affected runtime variables
      ArrayResize(prev.metric.enabled,     ArrayCopy(prev.metric.enabled,     metric.enabled    ));
      ArrayResize(prev.metric.ready,       ArrayCopy(prev.metric.ready,       metric.ready      ));
      ArrayResize(prev.metric.symbol,      ArrayCopy(prev.metric.symbol,      metric.symbol     ));
      ArrayResize(prev.metric.description, ArrayCopy(prev.metric.description, metric.description));
      ArrayResize(prev.metric.group,       ArrayCopy(prev.metric.group,       metric.group      ));
      ArrayResize(prev.metric.digits,      ArrayCopy(prev.metric.digits,      metric.digits     ));
      ArrayResize(prev.metric.currValue,   ArrayCopy(prev.metric.currValue,   metric.currValue  ));
      ArrayResize(prev.metric.baseValue,   ArrayCopy(prev.metric.baseValue,   metric.baseValue  ));
      ArrayResize(prev.metric.multiplier,  ArrayCopy(prev.metric.multiplier,  metric.multiplier ));
      ArrayResize(prev.metric.hSet,        ArrayCopy(prev.metric.hSet,        metric.hSet       ));

      // we didn't check ArraySize(source), instead we handle a generated error
      int error = GetLastError();
      if (error && error!=ERR_INVALID_PARAMETER) catch("BackupInputs.Recorder(2)", error);
   }
}


/**
 * Restore backed-up input parameters and runtime variables. Called from onInitParameters() and onInitTimeframeChange().
 */
void RestoreInputs.Recorder() {
   if (!catch("RestoreInputs.Recorder(1)")) {
      // input parameters
      EA.Recorder          = prev.EA.Recorder;
      recorder.mode        = prev.recorder.mode;
      recorder.initialized = prev.recorder.initialized;

      // affected runtime variables
      ArrayResize(metric.enabled,     ArrayCopy(metric.enabled,     prev.metric.enabled    ));
      ArrayResize(metric.ready,       ArrayCopy(metric.ready,       prev.metric.ready      ));
      ArrayResize(metric.symbol,      ArrayCopy(metric.symbol,      prev.metric.symbol     ));
      ArrayResize(metric.description, ArrayCopy(metric.description, prev.metric.description));
      ArrayResize(metric.group,       ArrayCopy(metric.group,       prev.metric.group      ));
      ArrayResize(metric.digits,      ArrayCopy(metric.digits,      prev.metric.digits     ));
      ArrayResize(metric.currValue,   ArrayCopy(metric.currValue,   prev.metric.currValue  ));
      ArrayResize(metric.baseValue,   ArrayCopy(metric.baseValue,   prev.metric.baseValue  ));
      ArrayResize(metric.multiplier,  ArrayCopy(metric.multiplier,  prev.metric.multiplier ));
      ArrayResize(metric.hSet,        ArrayCopy(metric.hSet,        prev.metric.hSet       ));

      // we didn't check ArraySize(source), instead we handle a generated error
      int error = GetLastError();
      if (error && error!=ERR_INVALID_PARAMETER) catch("RestoreInputs.Recorder(2)", error);
   }
}


/**
 * Validate and apply input parameter "EA.Recorder". The parameter may have been entered through the input dialog, read from
 * a status file or was deserialized and set programmatically by the terminal (e.g. at terminal restart).
 *
 * Call this function from your expert's function ValidateInputs().
 *
 * @param  isTest - whether the EA instance represents a test (in tester or on an online chart)
 *
 * @return bool - whether the input parameter is valid
 */
bool Recorder.ValidateInputs(bool isTest) {
   isTest = isTest!=0;
   bool isInitParameters = (ProgramInitReason()==IR_PARAMETERS);  // whether we validate manual or programatic input

   if (!isInitParameters || EA.Recorder!=prev.EA.Recorder) {
      Recorder.ResetMetrics();
      recorder.initialized = false;

      string sValues[], sValue=StrToLower(EA.Recorder);           // syntax: <integer>[=<number>]
      if (Explode(sValue, "*", sValues, 2) > 1) {                 //   <integer>: positive metric id (required)
         int size = Explode(sValues[0], "|", sValues, NULL);      //   <number>:  positive quote base (optional)
         sValue = sValues[size-1];
      }
      sValue = StrTrim(sValue);

      if (sValue == "off" || IsOptimization() || (isTest && !__isTesting)) {
         recorder.mode = RECORDER_OFF;
         EA.Recorder   = sValue;
      }
      else if (sValue == "on") {
         recorder.mode = RECORDER_ON;
         EA.Recorder   = sValue;
      }
      else {
         recorder.mode = RECORDER_CUSTOM;

         int metrics, digits, multiplier;
         double baseValue;
         string symbol="", description="", group="", sInput="";

         size = Explode(sValue, ",", sValues, NULL);
         for (int i=0; i < size; i++) {
            // syntactical metric validation
            sValue = StrTrim(sValues[i]);
            if (sValue == "")    continue;
            if (sValue == "...") continue;
            string sId = StrTrim(StrLeftTo(sValue, "="));
            int iValue = StrToInteger(sId);
            if (!StrIsDigits(sId) || !iValue)            return(!Recorder.onInputError("Recorder.ValidateInputs(1)  invalid parameter EA.Recorder: \""+ EA.Recorder +"\" (metric ids must be positive integers)"));
            int metricId = iValue;
            if (ArraySize(metric.enabled) > metricId) {
               if (metric.enabled[metricId])             return(!Recorder.onInputError("Recorder.ValidateInputs(2)  invalid parameter EA.Recorder: \""+ EA.Recorder +"\" (duplicate metric id "+ metricId +")"));
            }
            double dValue = 0;
            if (StrContains(sValue, "=")) {
               string sBase = StrTrim(StrRightFrom(sValue, "="));
               dValue = StrToDouble(sBase);
               if (!StrIsNumeric(sBase) || dValue <= 0)  return(!Recorder.onInputError("Recorder.ValidateInputs(3)  invalid parameter EA.Recorder: \""+ EA.Recorder +"\" (base values must be positive numbers)"));
            }

            // logical metric validation
            bool ready;
            int error = GetMT4SymbolDefinition(metricId, ready, symbol, description, group, digits, baseValue, multiplier);
            if (IsError(error)) {
               if (error == ERR_INVALID_INPUT_PARAMETER) return(!Recorder.onInputError("Recorder.ValidateInputs(4)  invalid parameter EA.Recorder: \""+ EA.Recorder +"\" (unsupported metric id "+ metricId +")"));
               return(false);                            // a runtime error (already raised)
            }
            if (dValue > 0) baseValue = dValue;

            // store metric details
            if (!Recorder.AddMetric(metricId, ready, symbol, description, group, digits, baseValue, multiplier)) return(false);
            metrics++;
            sInput = StringConcatenate(sInput, ",", metricId, ifString(IsEmpty(baseValue), "", "="+ NumberToStr(baseValue, ".+")));
         }

         if (!metrics) {
            recorder.mode = RECORDER_OFF;
            EA.Recorder = "off";
         }
         else {
            EA.Recorder = StrSubstr(sInput, 1);
         }
      }
      ec_SetRecordMode(__ExecutionContext, recorder.mode);
   }
   return(true);
}


/**
 * Error handler for invalid input parameters. Depending on the execution context a non-/terminating error is set.
 *
 * @param  string message - error message
 *
 * @return int - error status
 */
int Recorder.onInputError(string message) {
   int error = ERR_INVALID_PARAMETER;

   if (ProgramInitReason() == IR_PARAMETERS)
      return(logError(message, error));            // non-terminating error
   return(catch(message, error));                  // terminating error
}


/**
 * Initialize the recorder. Completes metric definitions and creates/updates a raw symbol for each metric.
 *
 * @return bool - success status
 */
bool Recorder.init() {
   if (recorder.mode == RECORDER_OFF || IsOptimization()) {
      recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF);
      return(false);
   }

   if (!recorder.initialized) {
      bool ready;
      int digits, multiplier;
      double baseValue;
      string symbol="", descr="", group="", suffix="";

      suffix                      = ", "+ PeriodDescription() + LocalTimeFormat(GetGmtTime(), ", %d.%m.%Y %H:%M");
      recorder.defaultDescription = StrLeft(ProgramName(), 63-StringLen(suffix)) + suffix;                           // sizeof(SYMBOL.description) = 64 chars (szchar)
      recorder.defaultGroup       = StrTrimRight(StrLeft(ProgramName(), MAX_SYMBOL_GROUP_LENGTH));
      recorder.hstDirectory       = Recorder.GetHstDirectory(); if (!StringLen(recorder.hstDirectory)) { recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF); return(false); }
      recorder.hstFormat          = Recorder.GetHstFormat();    if (!recorder.hstFormat)               { recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF); return(false); }

      if (recorder.mode == RECORDER_ON) {
         // create an internal metric for AccountEquity()
         int error = GetMT4SymbolDefinition(NULL, ready, symbol, descr, group, digits, baseValue, multiplier);
         if (IsError(error)) {
            if (error == ERR_INVALID_INPUT_PARAMETER) catch("Recorder.init(1)  invalid parameter EA.Recorder: \""+ EA.Recorder +"\" (unsupported metric id \"on\")", error);
            recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF);
            return(false);
         }

         if (ready) {
            if (symbol == "") {
               symbol = Recorder.GetNextMetricSymbol(); if (!StringLen(symbol)) { recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF); return(false); }
            }
            if (descr == "") {
               suffix = ", "+ PeriodDescription() +", AccountEquity in "+ AccountCurrency() + LocalTimeFormat(GetGmtTime(), ", %d.%m.%Y %H:%M");
               descr  = StrLeft(ProgramName(), 63-StringLen(suffix)) + suffix;
            }
            if (group == "") {
               group = recorder.defaultGroup;
            }
            if (!Recorder.AddMetric(1, true, symbol, descr, group, 2, 0, 1)) { recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF); return(false); }
            recorder.stdEquitySymbol = symbol;
         }
      }

      // update metric details and create raw MT4 symbols
      int size = ArraySize(metric.enabled);

      for (int id=1; id < size; id++) {
         if (!metric.enabled[id]) continue;

         if (!metric.ready[id]) {
            error = GetMT4SymbolDefinition(id, ready, symbol, descr, group, digits, baseValue, multiplier);
            if (IsError(error)) {
               if (error == ERR_INVALID_INPUT_PARAMETER) catch("Recorder.init(2)  invalid parameter EA.Recorder: \""+ EA.Recorder +"\" (unsupported metric id "+ id +")", error);
               recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF);
               return(false);
            }
            if (!ready) continue;
            metric.ready      [id] = true;
            metric.symbol     [id] = symbol;
            metric.description[id] = descr;
            metric.group      [id] = group;
            metric.digits     [id] = digits;
            metric.currValue  [id] = NULL;
            metric.baseValue  [id] = baseValue;
            metric.multiplier [id] = multiplier;
         }
         if (!StringLen(metric.description[id])) metric.description[id] = recorder.defaultDescription;
         if (!StringLen(metric.group      [id])) metric.group      [id] = recorder.defaultGroup;
         if (   IsEmpty(metric.baseValue  [id])) metric.baseValue  [id] = recorder.defaultBaseValue;
         if (          !metric.multiplier [id])  metric.multiplier [id] = 1;

         if (IsRawSymbol(metric.symbol[id], recorder.hstDirectory)) {
            if (__isTesting) {
               recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF);                                            // TODO: instead update existing properties
               return(!catch("Recorder.init(3)  symbol \""+ metric.symbol[id] +"\" already exists", ERR_ILLEGAL_STATE));
            }
         }
         else {
            int symbolId = CreateRawSymbol(metric.symbol[id], metric.description[id], metric.group[id], metric.digits[id], AccountCurrency(), AccountCurrency(), recorder.hstDirectory);
            if (symbolId < 0) {
               recorder.mode = ec_SetRecordMode(__ExecutionContext, RECORDER_OFF);
               return(false);
            }
         }
      }
      recorder.initialized = true;
   }
   return(true);
}


/**
 * Record performance metrics.
 *
 * @return bool - success status
 */
bool Recorder.start() {
   if (!recorder.initialized) {
      if (!Recorder.init()) return(recorder.mode == RECORDER_OFF);
   }
   /*
    Speed test SnowRoller EURUSD,M15  04.10.2012, Long, GridSize=18
   +---------------------------+------------+-----------+--------------+-------------+-------------+--------------+--------------+--------------+
   | Toshiba Satellite         |     old    | optimized | FindBar opt. | Arrays opt. |  Read opt.  |  Write opt.  |  Valid. opt. |  in library  |
   +---------------------------+------------+-----------+--------------+-------------+-------------+--------------+--------------+--------------+
   | v419 no recording         | 17.613 t/s |           |              |             |             |              |              |              |
   | v225 HST_BUFFER_TICKS=Off |  6.426 t/s |           |              |             |             |              |              |              |
   | v419 HST_BUFFER_TICKS=Off |  5.871 t/s | 6.877 t/s |   7.381 t/s  |  7.870 t/s  |  9.097 t/s  |   9.966 t/s  |  11.332 t/s  |              |
   | v419 HST_BUFFER_TICKS=On  |            |           |              |             |             |              |  15.486 t/s  |  14.286 t/s  |
   +---------------------------+------------+-----------+--------------+-------------+-------------+--------------+--------------+--------------+
   */
   int size=ArraySize(metric.hSet), flags=NULL;
   if (__isTesting) flags = HST_BUFFER_TICKS;
   double value;
   bool success = true;

   for (int i=0; i < size; i++) {
      if (!metric.ready[i]) continue;

      if (!metric.hSet[i]) {
         // online: prefer to continue an existing history
         if (!__isTesting) {
            if      (i <  7) metric.hSet[i] = HistorySet1.Get(metric.symbol[i], recorder.hstDirectory);
            else if (i < 14) metric.hSet[i] = HistorySet2.Get(metric.symbol[i], recorder.hstDirectory);
            else             metric.hSet[i] = HistorySet3.Get(metric.symbol[i], recorder.hstDirectory);
            if      (metric.hSet[i] == -1) metric.hSet[i] = NULL;
            else if (metric.hSet[i] <=  0) return(false);
         }

         // tester or no existing history
         if (!metric.hSet[i]) {
            if      (i <  7) metric.hSet[i] = HistorySet1.Create(metric.symbol[i], metric.description[i], metric.digits[i], recorder.hstFormat, recorder.hstDirectory);
            else if (i < 14) metric.hSet[i] = HistorySet2.Create(metric.symbol[i], metric.description[i], metric.digits[i], recorder.hstFormat, recorder.hstDirectory);
            else             metric.hSet[i] = HistorySet3.Create(metric.symbol[i], metric.description[i], metric.digits[i], recorder.hstFormat, recorder.hstDirectory);
            if (!metric.hSet[i]) return(false);
         }
      }

      if (recorder.mode == RECORDER_ON) value = AccountEquity() - AccountCredit();
      else                              value = metric.baseValue[i] + metric.currValue[i] * metric.multiplier[i];

      if      (i <  7) success = HistorySet1.AddTick(metric.hSet[i], Tick.time, value, flags);
      else if (i < 14) success = HistorySet2.AddTick(metric.hSet[i], Tick.time, value, flags);
      else             success = HistorySet3.AddTick(metric.hSet[i], Tick.time, value, flags);
      if (!success) break;
   }
   return(success);
}


/**
 * Deinitialize the recorder.
 *
 * @return bool - success status
 */
bool Recorder.deinit() {
   // close history sets
   int size = ArraySize(metric.hSet);
   for (int i=0; i < size; i++) {
      if (metric.hSet[i] > 0) {
         int tmp = metric.hSet[i];
         metric.hSet[i] = NULL;
         if      (i <  7) { if (!HistorySet1.Close(tmp)) return(false); }
         else if (i < 14) { if (!HistorySet2.Close(tmp)) return(false); }
         else             { if (!HistorySet3.Close(tmp)) return(false); }
      }
   }
   return(true);
}


/**
 * Add a metric to the recorder arrays. Prevents overwriting of existing metrics.
 *
 * @param  int    id          - metric id
 * @param  bool   ready       - whether metric details are complete and the metric is ready to be recorded
 * @param  string symbol      - symbol
 * @param  string description - symbol description
 * @param  string group       - symbol group (if empty the program name is used)
 * @param  int    digits      - symbol digits
 * @param  double baseValue   - quotes base value (EMPTY: use recorder settings)
 * @param  int    multiplier  - quotes multiplier
 *
 * @return bool - success status
 */
bool Recorder.AddMetric(int id, bool ready, string symbol, string description, string group, int digits, double baseValue, int multiplier) {
   ready = ready!=0;
   if (id < 1 || id > 21) return(!catch("Recorder.AddMetric(1)  invalid parameter id: "+ id +" (allowed range: 1 to 21)", ERR_INVALID_PARAMETER));

   int size = ArraySize(metric.enabled);
   if (id >= size) {
      size = id + 1;
      ArrayResize(metric.enabled,     size);
      ArrayResize(metric.ready,       size);
      ArrayResize(metric.symbol,      size);
      ArrayResize(metric.description, size);
      ArrayResize(metric.group,       size);
      ArrayResize(metric.digits,      size);
      ArrayResize(metric.currValue,   size);
      ArrayResize(metric.baseValue,   size);
      ArrayResize(metric.multiplier,  size);
      ArrayResize(metric.hSet,        size);
   }
   if (metric.enabled[id]) return(!catch("Recorder.AddMetric(2)  invalid parameter id: "+ id +" (metric exists) ", ERR_INVALID_PARAMETER));

   metric.enabled    [id] = true;
   metric.ready      [id] = ready;
   metric.symbol     [id] = symbol;
   metric.description[id] = description;
   metric.group      [id] = group;
   metric.digits     [id] = digits;
   metric.currValue  [id] = NULL;
   metric.baseValue  [id] = baseValue;
   metric.multiplier [id] = multiplier;
   metric.hSet       [id] = NULL;

   return(!catch("Recorder.AddMetric(3)"));
}


/**
 * Remove all metrics currently registered in the recorder.
 */
void Recorder.ResetMetrics() {
   ArrayResize(metric.enabled,     0);
   ArrayResize(metric.ready,       0);
   ArrayResize(metric.symbol,      0);
   ArrayResize(metric.description, 0);
   ArrayResize(metric.group,       0);
   ArrayResize(metric.digits,      0);
   ArrayResize(metric.currValue,   0);
   ArrayResize(metric.baseValue,   0);
   ArrayResize(metric.multiplier,  0);
   ArrayResize(metric.hSet,        0);
}


/**
 * Resolve the next available MT4 symbol for metric recordings.
 *
 * @return string - symbol or an empty string in case of errors
 */
string Recorder.GetNextMetricSymbol() {
   if (recorder.hstDirectory == "") {
      recorder.hstDirectory = Recorder.GetHstDirectory(); if (!StringLen(recorder.hstDirectory)) return("");
   }
   string filename = recorder.hstDirectory +"/symbols.raw";
   string prefix = StrLeft(Symbol(), 6) +".";
   int maxId = 0;

   if (IsFile(filename, MODE_MQL)) {
      // open "symbols.raw" and read existing symbols
      int hFile = FileOpen(filename, FILE_READ|FILE_BIN);
      if (hFile <= 0)                                      return(_EMPTY_STR(catch("Recorder.GetNextMetricSymbol(1)->FileOpen(\""+ filename +"\", FILE_READ) => "+ hFile, intOr(GetLastError(), ERR_RUNTIME_ERROR))));

      int fileSize = FileSize(hFile);
      if (fileSize % SYMBOL_size != 0) { FileClose(hFile); return(_EMPTY_STR(catch("Recorder.GetNextMetricSymbol(2)  invalid size of \""+ filename +"\" (not an even SYMBOL size, "+ (fileSize % SYMBOL_size) +" trailing bytes)", intOr(GetLastError(), ERR_RUNTIME_ERROR)))); }
      int symbolsSize = fileSize/SYMBOL_size;

      int symbols[]; InitializeByteBuffer(symbols, fileSize);
      if (fileSize > 0) {
         int ints = FileReadArray(hFile, symbols, 0, fileSize/4);
         if (ints!=fileSize/4) { FileClose(hFile);         return(_EMPTY_STR(catch("Recorder.GetNextMetricSymbol(3)  error reading \""+ filename +"\" ("+ (ints*4) +" of "+ fileSize +" bytes read)", intOr(GetLastError(), ERR_RUNTIME_ERROR)))); }
      }
      FileClose(hFile);

      // iterate over all symbols and determine the max counter matching "<prefix>[0-9]{3}"
      string symbol="", sId="";
      for (int i=0; i < symbolsSize; i++) {
         symbol = symbols_Name(symbols, i);
         if (StrStartsWithI(symbol, prefix)) {
            sId = StrRight(symbol, -StringLen(prefix));
            sId = StrLeft(sId, 3);
            if (StrIsDigits(sId)) {
               maxId = MathMax(maxId, StrToInteger(sId));
            }
         }
      }
   }
   return(prefix + StrPadLeft(""+ (maxId+1), 3, "0"));
}


/**
 * Resolve the history directory for recorded timeseries.
 *
 * @return string - directory or an empty string in case of errors
 */
string Recorder.GetHstDirectory() {
   string section = ifString(__isTesting, "Tester.", "") + WindowExpertName();
   string key = "Recorder.HistoryDirectory", sValue="";

   if (IsConfigKey(section, key)) {
      sValue = GetConfigString(section, key, "");
   }
   else {
      section = ifString(__isTesting, "Tester.", "") +"Experts";
      if (IsConfigKey(section, key)) {
         sValue = GetConfigString(section, key, "");
      }
   }
   if (!StringLen(sValue)) return(_EMPTY_STR(catch("Recorder.GetHstDirectory(1)  missing config value ["+ section +"]->"+ key, ERR_INVALID_CONFIG_VALUE)));
   return(sValue);
}


/**
 * Resolve the history format for recorded timeseries.
 *
 * @return int - history format or NULL (0) in case of errors
 */
int Recorder.GetHstFormat() {
   string section = ifString(__isTesting, "Tester.", "") + WindowExpertName();
   string key = "Recorder.HistoryFormat";

   if (IsConfigKey(section, key)) {
      int iValue = GetConfigInt(section, key, 0);
   }
   else {
      section = ifString(__isTesting, "Tester.", "") +"Experts";
      if (IsConfigKey(section, key)) {
         iValue = GetConfigInt(section, key, 0);
      }
   }
   if (iValue!=400 && iValue!=401) return(!catch("Recorder.GetHstFormat(1)  invalid config value ["+ section +"]->"+ key +": "+ iValue +" (must be 400 or 401)", ERR_INVALID_CONFIG_VALUE));
   return(iValue);

   // suppress compiler warnings
   BackupInputs.Recorder();
   RestoreInputs.Recorder();
   Recorder.ResetMetrics();
   Recorder.ValidateInputs(NULL);
}


#import "rsfMT4Expander.dll"
   int GetMT4SymbolDefinition(int id, bool &ready, string &symbol, string &description, string &group, int &digits, double &baseValue, int &multiplier);
#import
