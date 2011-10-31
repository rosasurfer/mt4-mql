/**
 *
 */
#include <stddefine.mqh>


#import "stdlib.ex4"

   // Laufzeitfunktionen
   void     stdlib_init(string scriptName);
   void     stdlib_onTick(int unchangedBars);
   int      stdlib_GetLastError();
   int      stdlib_PeekLastError();


   // Arrays
   int      ArrayPushInt(int array[], int value);
   int      ArrayPushDouble(double array[], double value);
   int      ArrayPushString(string array[], string value);

   int      ArrayShiftInt(int array[]);
   double   ArrayShiftDouble(double array[]);
   string   ArrayShiftString(string array[]);

   bool     IntInArray(int needle, int haystack[]);
   bool     DoubleInArray(double needle, double haystack[]);
   bool     StringInArray(string needle, string haystack[]);

   int      ArraySearchInt(int needle, int haystack[]);
   int      ArraySearchDouble(double needle, double haystack[]);
   int      ArraySearchString(string needle, string haystack[]);

   bool     ReverseIntArray(int array[]);
   bool     ReverseDoubleArray(double array[]);
   bool     ReverseStringArray(string array[]);

   bool     IsReverseIndexedIntArray(int array[]);
   bool     IsReverseIndexedDoubleArray(double array[]);
   bool     IsReverseIndexedSringArray(string array[]);

   string   JoinBools(bool values[], string separator);
   string   JoinInts(int values[], string separator);
   string   JoinDoubles(double values[], string separator);
   string   JoinStrings(string values[], string separator);


   // Buffer-Funktionen
   int      InitializeBuffer(int buffer[], int length);
   int      InitializeStringBuffer(string buffer[], int length);

   string   BufferToStr(int buffer[]);
   string   BufferToHexStr(int buffer[]);

   int      BufferGetChar(int buffer[], int pos);
   //int    BufferSetChar(int buffer[], int pos, int char);

   string   BufferCharsToStr(int buffer[], int from, int length);    //string BufferGetStringA(int buffer[], int from, int length); // Alias
   string   BufferWCharsToStr(int buffer[], int from, int length);   //string BufferGetStringW(int buffer[], int from, int length); // Alias

   //int    BufferSetStringA(int buffer[], int pos, string value);   //int BufferSetString(int buffer[], int pos, string value);    // Alias
   //int    BufferSetStringW(int buffer[], int pos, string value);

   int      ExplodeStringsA(int buffer[], string results[]);   int ExplodeStrings(int buffer[], string results[]);   // Alias
   int      ExplodeStringsW(int buffer[], string results[]);


   // Conditional Statements
   int      ifInt(bool condition, int iThen, int iElse);
   double   ifDouble(bool condition, double dThen, double dElse);
   string   ifString(bool condition, string strThen, string strElse);


   // Configuration
   string   GetLocalConfigPath();
   string   GetGlobalConfigPath();

   bool     IsConfigKey(string section, string key);
   bool     IsLocalConfigKey(string section, string key);
   bool     IsGlobalConfigKey(string section, string key);

   bool     GetConfigBool(string section, string key, bool defaultValue);
   int      GetConfigInt(string section, string key, int defaultValue);
   double   GetConfigDouble(string section, string key, double defaultValue);
   string   GetConfigString(string section, string key, string defaultValue);

   bool     GetLocalConfigBool(string section, string key, bool defaultValue);
   int      GetLocalConfigInt(string section, string key, int defaultValue);
   double   GetLocalConfigDouble(string section, string key, double defaultValue);
   string   GetLocalConfigString(string section, string key, string defaultValue);

   bool     GetGlobalConfigBool(string section, string key, bool defaultValue);
   int      GetGlobalConfigInt(string section, string key, int defaultValue);
   double   GetGlobalConfigDouble(string section, string key, double defaultValue);
   string   GetGlobalConfigString(string section, string key, string defaultValue);


   // Date/Time
   datetime EasternToGMT(datetime easternTime);
 //datetime EasternToLocalTime(datetime easternTime);
   datetime EasternToServerTime(datetime easternTime);
   datetime GmtToEasternTime(datetime gmtTime);
 //datetime GmtToLocalTime(datetime gmtTime);
   datetime GmtToServerTime(datetime gmtTime);
 //datetime LocalToEasternTime(datetime localTime);
 //datetime LocalToGMT(datetime localTime);
 //datetime LocalToServerTime(datetime localTime);
   datetime ServerToEasternTime(datetime serverTime);
   datetime ServerToGMT(datetime serverTime);
 //datetime ServerToLocalTime(datetime serverTime);

   int      GetEasternToGmtOffset(datetime easternTime);
 //int      GetEasternToLocalTimeOffset(datetime easternTime);
   int      GetEasternToServerTimeOffset(datetime easternTime);
   int      GetGmtToEasternTimeOffset(datetime gmtTime);
 //int      GetGmtToLocalTimeOffset(datetime gmtTime);
   int      GetGmtToServerTimeOffset(datetime gmtTime);
 //int      GetLocalToEasternTimeOffset();
   int      GetLocalToGmtOffset(datetime localTime);
 //int      GetLocalToServerTimeOffset();
   int      GetServerToEasternTimeOffset(datetime serverTime);
   int      GetServerToGmtOffset(datetime serverTime);
 //int      GetServerToLocalTimeOffset(datetime serverTime);

   datetime GetEasternNextSessionEndTime(datetime easternTime);
   datetime GetEasternNextSessionStartTime(datetime easternTime);
   datetime GetEasternPrevSessionEndTime(datetime easternTime);
   datetime GetEasternPrevSessionStartTime(datetime easternTime);
   datetime GetEasternSessionEndTime(datetime easternTime);
   datetime GetEasternSessionStartTime(datetime easternTime);

   datetime GetGmtNextSessionEndTime(datetime gtmTime);
   datetime GetGmtNextSessionStartTime(datetime gtmTime);
   datetime GetGmtPrevSessionEndTime(datetime gtmTime);
   datetime GetGmtPrevSessionStartTime(datetime gtmTime);
   datetime GetGmtSessionEndTime(datetime gmtTime);
   datetime GetGmtSessionStartTime(datetime gmtTime);

 //datetime GetLocalNextSessionEndTime(datetime localTime);
 //datetime GetLocalNextSessionStartTime(datetime localTime);
 //datetime GetLocalPrevSessionEndTime(datetime localTime);
 //datetime GetLocalPrevSessionStartTime(datetime localTime);
 //datetime GetLocalSessionEndTime(datetime localTime);
 //datetime GetLocalSessionStartTime(datetime localTime);

   datetime GetServerNextSessionEndTime(datetime serverTime);
   datetime GetServerNextSessionStartTime(datetime serverTime);
   datetime GetServerPrevSessionEndTime(datetime serverTime);
   datetime GetServerPrevSessionStartTime(datetime serverTime);
   datetime GetServerSessionEndTime(datetime serverTime);
   datetime GetServerSessionStartTime(datetime serverTime);

   string   GetDayOfWeek(datetime time, bool format);
   string   GetTradeServerTimezone();
   datetime TimeGMT();


   // Eventlistener
   bool     EventListener(int event, int results[], int flags);
   bool     EventListener.BarOpen(int results[], int flags);

   bool     EventListener.AccountChange(int results[], int flags);
   bool     EventListener.AccountPayment(int results[], int flags);
   bool     EventListener.HistoryChange(int results[], int flags);

   bool     EventListener.OrderPlace(int results[], int flags);
   bool     EventListener.OrderChange(int results[], int flags);
   bool     EventListener.OrderCancel(int results[], int flags);

   bool     EventListener.PositionOpen(int results[], int flags);
   bool     EventListener.PositionClose(int results[], int flags);


   // Eventhandler
   int      onBarOpen(int details[]);
   int      onAccountChange(int details[]);
   int      onAccountPayment(int tickets[]);
   int      onHistoryChange(int tickets[]);

   int      onOrderPlace(int tickets[]);
   int      onOrderChange(int tickets[]);
   int      onOrderCancel(int tickets[]);

   int      onPositionOpen(int tickets[]);
   int      onPositionClose(int tickets[]);


   // Farben
   color    RGB(int red, int green, int blue);

   int      RGBToHSVColor(color rgb, double hsv[]);
   int      RGBValuesToHSVColor(int red, int green, int blue, double hsv[]);

   color    HSVToRGBColor(double hsv[3]);
   color    HSVValuesToRGBColor(double hue, double saturation, double value);

   color    Color.ModifyHSV(color rgb, double hue, double saturation, double value);

   string   ColorToRGBStr(color rgb);
   string   ColorToHtmlStr(color rgb);


   // Files, I/O
   bool     IsFile(string pathName);
   bool     IsDirectory(string pathName);

   int      FileReadLines(string filename, string lines[], bool skipEmptyLines);
   string   GetPrivateProfileString(string fileName, string section, string key, string defaultValue);
   string   GetShortcutTarget(string lnkFile);


   // MagicNumbers
   int      StrategyId(int magicNumber);
   string   LFX.Currency(int magicNumber);
   int      LFX.CurrencyId(int magicNumber);
   int      LFX.Counter(int magicNumber);
   double   LFX.Units(int magicNumber);
   int      LFX.Instance(int magicNumber);


   // Math, Numbers
   bool     EQ(double a, double b);    bool CompareDoubles(double a, double b);  // MetaQuotes-Alias
   bool     NE(double a, double b);

   bool     LT(double a, double b);
   bool     LE(double a, double b);

   bool     GT(double a, double b);
   bool     GE(double a, double b);

   double   MathModFix(double a, double b);
   double   MathRoundFix(double number, int decimals);
   int      MathSign(double number);

   int      CountDecimals(double number);

   string   DecimalToHex(int number);


   // Strings
   string   CreateString(int length);

   bool     StringIsDigit(string value);
   bool     StringIsInteger(string value);
   bool     StringIsNumeric(string value);

   bool     StringContains(string object, string substring);
   bool     StringIContains(string object, string substring);

   bool     StringStartsWith(string object, string prefix);
   bool     StringEndsWith(string object, string postfix);
   bool     StringIStartsWith(string object, string prefix);
   bool     StringIEndsWith(string object, string postfix);
   bool     StringICompare(string string1, string string2);

   string   StringLeft(string value, int n);
   string   StringRight(string value, int n);

   string   StringTrim(string value);
   string   StringLeftPad(string input, int length, string pad_string);
   string   StringRightPad(string input, int length, string pad_string);

   string   StringToLower(string value);
   string   StringToUpper(string value);

   int      StringFindR(string object, string search);
   string   StringRepeat(string input, int times);
   string   StringReplace(string object, string search, string replace);
   string   StringSubstrFix(string object, int start, int length);

   int      Explode(string object, string separator, string results[], int limit);
   string   UrlEncode(string value);


   // Orderhandling-/Tradefunktionen
   bool     IsTradeOperationType(int value);
   bool     IsTemporaryTradeError(int error);
   bool     IsPermanentTradeError(int error);

   int      OrderSendEx(string symbol, int type, double lots, double price, double slippage, double stopLoss, double takeProfit, string comment, int magicNumber, datetime expires, color markerColor);
   bool     OrderCloseEx(int ticket, double lots, double price, double slippage, color markerColor);
   bool     OrderCloseByEx(int ticket, int opposite, int remainder[], color markerColor);
   bool     OrderMultiClose(int tickets[], double slippage, color markerColor);


   // sonstiges
   string   GetTerminalVersion();
   int      GetTerminalBuild();
   int      GetTerminalWindow();

   int      GetAccountNumber();
   int      GetAccountHistory(int account, string results[]);
   int      GetBalanceHistory(int account, datetime times[], double values[]);
   int      ChronologicalSortTickets(int tickets[]);
   string   ShortAccountCompany();
   string   GetTradeServerDirectory();

   string   GetCurrency(int id);
   int      GetCurrencyId(string currency);

   string   GetStandardSymbol(string symbol);                              // Alias f�r GetStandardSymbolOrAlt(symbol, symbol)
   string   GetStandardSymbolOrAlt(string symbol, string altValue);
   string   GetStandardSymbolStrict(string symbol);

   string   GetSymbolName(string symbol);                                  // Alias f�r GetSymbolNameOrAlt(symbol, symbol)
   string   GetSymbolNameOrAlt(string symbol, string altName);
   string   GetSymbolNameStrict(string symbol);

   string   GetLongSymbolName(string symbol);                              // Alias f�r GetLongSymbolNameOrAlt(symbol, symbol)
   string   GetLongSymbolNameOrAlt(string symbol, string altValue);
   string   GetLongSymbolNameStrict(string symbol);

   int      IncreasePeriod(int period);
   int      DecreasePeriod(int period);

   int      MovingAverageMethodToId(string method);
   int      PeriodFlag(int period);
   int      PeriodToId(string description);

   string   AppliedPriceDescription(int appliedPrice);
   string   ErrorDescription(int error);
   string   MovingAverageMethodDescription(int method);
   string   OperationTypeDescription(int type);
   string   PeriodDescription(int period);
   string   UninitializeReasonDescription(int reason);

   string   CreateLegendLabel(string name);
   int      RepositionLegend();
   int      RemoveChartObjects(string objects[]);

   int      iAccountBalance(int account, double buffer[], int bar);
   int      iAccountBalanceSeries(int account, double buffer[]);
   int      iBarShiftNext(string symbol, int period, datetime time);
   int      iBarShiftPrevious(string symbol, int period, datetime time);

   int      SendTextMessage(string receiver, string message);
   int      SendTick(bool sound);
   int      SwitchExperts(bool enable);
   double   GetAverageSpread(string symbol);

   string   GetComputerName();
   string   GetWindowText(int hWnd);
   int      SetWindowText(int hWnd, string text);
   int      WinExecAndWait(string cmdLine, int cmdShow);
   int      GetPrivateProfileSectionNames(string fileName, string names[]);
   int      DeletePrivateProfileKey(string lpFileName, string lpSection, string lpKey);


   // toString-Funktionen
   string   BoolToStr(bool value);
   string   IntToHexStr(int integer);                 string IntegerToHexStr(int integer);                              // MetaQuotes-Alias
   string   DoubleToStrEx(double value, int digits);  string DoubleToStrMorePrecision(double number, int precision);    // MetaQuotes-Alias

   string   BoolArrayToStr(bool values[], string separator);
   string   IntArrayToStr(int values[], string separator);
   string   DateTimeArrayToStr(int values[], string separator);
   string   OperationTypeArrayToStr(int values[], string separator);
   string   DoubleArrayToStr(double values[], string separator);
   string   MoneyArrayToStr(double values[], string separator);
   string   PriceArrayToStr(double values[], string format, string separator);
   string   StringArrayToStr(string values[], string separator);

   string   AppliedPriceToStr(int appliedPrice);
   string   ErrorToStr(int error);
   string   EventToStr(int event);
   string   MessageBoxCmdToStr(int cmd);
   string   MovingAverageMethodToStr(int method);
   string   NumberToStr(double number, string format);
   string   OperationTypeToStr(int type);
   string   PeriodFlagToStr(int flag);
   string   PeriodToStr(int period);
   string   ShellExecuteErrorToStr(int error);
   string   UninitializeReasonToStr(int reason);
   string   WaitForSingleObjectValueToStr(int value);


   // Win32-Structs Getter und Setter
   int      pi.hProcess                   (/*PROCESS_INFORMATION*/int pi[]);
   int      pi.hThread                    (/*PROCESS_INFORMATION*/int pi[]);
   int      pi.ProcessId                  (/*PROCESS_INFORMATION*/int pi[]);
   int      pi.ThreadId                   (/*PROCESS_INFORMATION*/int pi[]);

   int      sa.Length                     (/*SECURITY_ATTRIBUTES*/int sa[]);
   int      sa.SecurityDescriptor         (/*SECURITY_ATTRIBUTES*/int sa[]);
   bool     sa.InheritHandle              (/*SECURITY_ATTRIBUTES*/int sa[]);

   int      si.cb                         (/*STARTUPINFO*/int si[]);
   int      si.Desktop                    (/*STARTUPINFO*/int si[]);
   int      si.Title                      (/*STARTUPINFO*/int si[]);
   int      si.X                          (/*STARTUPINFO*/int si[]);
   int      si.Y                          (/*STARTUPINFO*/int si[]);
   int      si.XSize                      (/*STARTUPINFO*/int si[]);
   int      si.YSize                      (/*STARTUPINFO*/int si[]);
   int      si.XCountChars                (/*STARTUPINFO*/int si[]);
   int      si.YCountChars                (/*STARTUPINFO*/int si[]);
   int      si.FillAttribute              (/*STARTUPINFO*/int si[]);
   int      si.Flags                      (/*STARTUPINFO*/int si[]);
   string   si.FlagsToStr                 (/*STARTUPINFO*/int si[]);
   int      si.ShowWindow                 (/*STARTUPINFO*/int si[]);
   string   si.ShowWindowToStr            (/*STARTUPINFO*/int si[]);
   int      si.hStdInput                  (/*STARTUPINFO*/int si[]);
   int      si.hStdOutput                 (/*STARTUPINFO*/int si[]);
   int      si.hStdError                  (/*STARTUPINFO*/int si[]);

   int      si.setCb                      (/*STARTUPINFO*/int si[], int size);
   int      si.setFlags                   (/*STARTUPINFO*/int si[], int flags);
   int      si.setShowWindow              (/*STARTUPINFO*/int si[], int cmdShow);

   int      st.Year                       (/*SYSTEMTIME*/int st[]);
   int      st.Month                      (/*SYSTEMTIME*/int st[]);
   int      st.DayOfWeek                  (/*SYSTEMTIME*/int st[]);
   int      st.Day                        (/*SYSTEMTIME*/int st[]);
   int      st.Hour                       (/*SYSTEMTIME*/int st[]);
   int      st.Minute                     (/*SYSTEMTIME*/int st[]);
   int      st.Second                     (/*SYSTEMTIME*/int st[]);
   int      st.MilliSec                   (/*SYSTEMTIME*/int st[]);

   int      tzi.Bias                      (/*TIME_ZONE_INFORMATION*/int tzi[]);
   string   tzi.StandardName              (/*TIME_ZONE_INFORMATION*/int tzi[]);
   void     tzi.StandardDate              (/*TIME_ZONE_INFORMATION*/int tzi[], /*SYSTEMTIME*/int st[]);
   int      tzi.StandardBias              (/*TIME_ZONE_INFORMATION*/int tzi[]);
   string   tzi.DaylightName              (/*TIME_ZONE_INFORMATION*/int tzi[]);
   void     tzi.DaylightDate              (/*TIME_ZONE_INFORMATION*/int tzi[], /*SYSTEMTIME*/int st[]);
   int      tzi.DaylightBias              (/*TIME_ZONE_INFORMATION*/int tzi[]);

   int      wfd.FileAttributes            (/*WIN32_FIND_DATA*/int wfd[]);
   string   wdf.FileAttributesToStr       (/*WIN32_FIND_DATA*/int wdf[]);
   bool     wfd.FileAttribute.ReadOnly    (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Hidden      (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.System      (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Directory   (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Archive     (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Device      (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Normal      (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Temporary   (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.SparseFile  (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.ReparsePoint(/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Compressed  (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Offline     (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.NotIndexed  (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Encrypted   (/*WIN32_FIND_DATA*/int wfd[]);
   bool     wfd.FileAttribute.Virtual     (/*WIN32_FIND_DATA*/int wfd[]);
   string   wfd.FileName                  (/*WIN32_FIND_DATA*/int wfd[]);
   string   wfd.AlternateFileName         (/*WIN32_FIND_DATA*/int wfd[]);

#import


// ShowWindow()-Konstanten f�r WinExecWait()
#define SW_SHOW                           5        // Details zu den Werten in win32api.mqh
#define SW_SHOWNA                         8
#define SW_HIDE                           0
#define SW_SHOWMAXIMIZED                  3
#define SW_MAXIMIZE        SW_SHOWMAXIMIZED
#define SW_SHOWMINIMIZED                  2
#define SW_SHOWMINNOACTIVE                7
#define SW_MINIMIZE                       6
#define SW_FORCEMINIMIZE                 11
#define SW_MAX             SW_FORCEMINIMIZE
#define SW_SHOWNORMAL                     1
#define SW_NORMAL             SW_SHOWNORMAL
#define SW_SHOWNOACTIVATE                 4
#define SW_RESTORE                        9
#define SW_SHOWDEFAULT                   10
