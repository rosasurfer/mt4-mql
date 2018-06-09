/**
 * Volume Delta compact
 *
 * Displays volume delta in a compact form as received from the BankersFX data feed.
 *
 * Indicator buffers to use with iCustom():
 *  � VolumeDelta.MODE_MAIN:   all volume delta values
 *  � VolumeDelta.MODE_SIGNAL: signal level direction and duration since last crossing of the opposite level
 *    - direction: positive values represent a volume delta above the negative signal level (+1...+n),
 *                 negative values represent a volume delta below the positive signal level (-1...-n)
 *    - length:    the absolute direction value is the histogram section length since the last crossing of the opposite
 *                 signal level
 */
#include <stddefine.mqh>
int   __INIT_FLAGS__[];
int __DEINIT_FLAGS__[];

////////////////////////////////////////////////////// Configuration ////////////////////////////////////////////////////////

extern color  Histogram.Color.Long  = LimeGreen;
extern color  Histogram.Color.Short = Red;
extern int    Histogram.Style.Width = 2;

extern int    Max.Values            = 3000;                    // max. number of values to display: -1 = all

extern string __________________________;

extern int    Signal.Level          = 20;
extern string Signal.onLevelCross   = "auto* | off | on";
extern string Signal.Sound          = "auto* | off | on";
extern string Signal.Mail.Receiver  = "auto* | off | on | {email-address}";
extern string Signal.SMS.Receiver   = "auto* | off | on | {phone-number}";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <core/indicator.mqh>
#include <stdfunctions.mqh>
#include <stdlibs.mqh>
#include <functions/Configure.Signal.mqh>
#include <functions/Configure.Signal.Mail.mqh>
#include <functions/Configure.Signal.SMS.mqh>
#include <functions/Configure.Signal.Sound.mqh>
#include <functions/EventListener.BarOpen.mqh>

#define MODE_VOLUME_MAIN      VolumeDelta.MODE_MAIN            // indicator buffer ids
#define MODE_VOLUME_SIGNAL    VolumeDelta.MODE_SIGNAL
#define MODE_VOLUME_LONG      2
#define MODE_VOLUME_SHORT     3

#property indicator_separate_window
#property indicator_minimum   0

#property indicator_buffers   4

#property indicator_width1    0
#property indicator_width2    0
#property indicator_width3    2
#property indicator_width4    2

double bufferMain  [];                                         // all values:           invisible, displayed in "Data" window
double bufferSignal[];                                         // direction and length: invisible
double bufferLong  [];                                         // long values:          visible
double bufferShort [];                                         // short values:         visible

string indicatorBankersFxName = "BFX Core Volumes";            // BankersFX indicator name
string indicatorShortName;                                     // "Data" window and signal notification name

bool   signals;

bool   signal.sound;
string signal.sound.levelCross.long  = "Signal-Up.wav";
string signal.sound.levelCross.short = "Signal-Down.wav";

bool   signal.mail;
string signal.mail.sender   = "";
string signal.mail.receiver = "";

bool   signal.sms;
string signal.sms.receiver = "";


/**
 * Initialization
 *
 * @return int - error status
 */
int onInit() {
   // (1) input validation
   // Colors                                                   // after deserialization the terminal might turn CLR_NONE (0xFFFFFFFF) into Black (0xFF000000)
   if (Histogram.Color.Long  == 0xFF000000) Histogram.Color.Long  = CLR_NONE;
   if (Histogram.Color.Short == 0xFF000000) Histogram.Color.Short = CLR_NONE;

   // Styles
   if (Histogram.Style.Width < 1) return(catch("onInit(1)  Invalid input parameter Histogram.Style.Width = "+ Histogram.Style.Width, ERR_INVALID_INPUT_PARAMETER));
   if (Histogram.Style.Width > 5) return(catch("onInit(2)  Invalid input parameter Histogram.Style.Width = "+ Histogram.Style.Width, ERR_INVALID_INPUT_PARAMETER));

   // Max.Values
   if (Max.Values < -1)           return(catch("onInit(3)  Invalid input parameter Max.Values = "+ Max.Values, ERR_INVALID_INPUT_PARAMETER));

   // Signals
   if (!Configure.Signal("VolumeDelta", Signal.onLevelCross, signals))                                          return(last_error);
   if (signals) {
      if (!Configure.Signal.Sound(Signal.Sound,         signal.sound                                         )) return(last_error);
      if (!Configure.Signal.Mail (Signal.Mail.Receiver, signal.mail, signal.mail.sender, signal.mail.receiver)) return(last_error);
      if (!Configure.Signal.SMS  (Signal.SMS.Receiver,  signal.sms,                      signal.sms.receiver )) return(last_error);
      if (!signal.sound && !signal.mail && !signal.sms)
         signals = false;
   }


   // (2) check existence of BankersFX indicator
   string mqlDir = ifString(GetTerminalBuild()<=509, "\\experts", "\\mql4");
   string indicatorFile = TerminalPath() + mqlDir +"\\indicators\\"+ indicatorBankersFxName +".ex4";
   if (!IsFile(indicatorFile)) return(catch("onInit(5)  BankersFX indicator not found: "+ DoubleQuoteStr(indicatorFile), ERR_FILE_NOT_FOUND));


   // (3) indicator buffer management
   IndicatorBuffers(4);
   SetIndexBuffer(MODE_VOLUME_MAIN,   bufferMain  );           // all values:           invisible, displayed in "Data" window
   SetIndexBuffer(MODE_VOLUME_SIGNAL, bufferSignal);           // direction and length: invisible
   SetIndexBuffer(MODE_VOLUME_LONG,   bufferLong  );           // long values:          visible
   SetIndexBuffer(MODE_VOLUME_SHORT,  bufferShort );           // short values:         visible

   // names and labels
   indicatorShortName = "Volume Delta";
   string signalInfo = ifString(signals, "   onLevel("+ Signal.Level +")="+ StringRight(ifString(signal.sound, ", Sound", "") + ifString(signal.mail, ", Mail", "") + ifString(signal.sms, ", SMS", ""), -2), "");
   string subName    = indicatorShortName + signalInfo +"  ";
   IndicatorShortName(subName);                                // indicator subwindow and context menu
   SetIndexLabel(MODE_VOLUME_MAIN,   indicatorShortName);      // "Data" window and tooltips
   SetIndexLabel(MODE_VOLUME_SIGNAL, NULL);
   SetIndexLabel(MODE_VOLUME_LONG,   NULL);
   SetIndexLabel(MODE_VOLUME_SHORT,  NULL);
   IndicatorDigits(2);


   // (4) drawing options and styles
   int startDraw = 0;
   if (Max.Values >= 0) startDraw += Bars - Max.Values;
   if (startDraw  <  0) startDraw  = 0;
   SetIndexDrawBegin(MODE_VOLUME_LONG,  startDraw);
   SetIndexDrawBegin(MODE_VOLUME_SHORT, startDraw);
   SetIndicatorStyles();

   return(catch("onInit(6)"));
}


/**
 * Main function
 *
 * @return int - error status
 */
int onTick() {
   // wait for initialized account number (needed for BankersFX license validation)
   if (!AccountNumber())
      return(log("onInit(1)  waiting for account number initialization", SetLastError(ERS_TERMINAL_NOT_YET_READY)));

   // check for finished buffer initialization (may be needed on terminal start)
   if (!ArraySize(bufferMain))
      return(log("onTick(2)  size(bufferMain) = 0", SetLastError(ERS_TERMINAL_NOT_YET_READY)));

   // reset all buffers and delete garbage behind Max.Values before doing a full recalculation
   if (!ValidBars) {
      ArrayInitialize(bufferMain,   EMPTY_VALUE);
      ArrayInitialize(bufferSignal,            0);
      ArrayInitialize(bufferLong,   EMPTY_VALUE);
      ArrayInitialize(bufferShort,  EMPTY_VALUE);
      SetIndicatorStyles();                                          // fix for various terminal bugs
   }

   // synchronize buffers with a shifted offline chart (if applicable)
   if (ShiftedBars > 0) {
      ShiftIndicatorBuffer(bufferMain,   Bars, ShiftedBars, EMPTY_VALUE);
      ShiftIndicatorBuffer(bufferSignal, Bars, ShiftedBars,           0);
      ShiftIndicatorBuffer(bufferLong,   Bars, ShiftedBars, EMPTY_VALUE);
      ShiftIndicatorBuffer(bufferShort,  Bars, ShiftedBars, EMPTY_VALUE);
   }


   // (1) calculate start bar
   int changedBars = ChangedBars;
   if (Max.Values >= 0) /*&&*/ if (changedBars > Max.Values)
      changedBars = Max.Values;
   int startBar = changedBars-1;

   double delta;


   // (2) recalculate invalid bars
   for (int bar=startBar; bar >= 0; bar--) {
      bufferLong [bar] = GetBankersFxVolume(bar, BankersFx.MODE_VOLUME_LONG);  if (last_error != NO_ERROR) return(last_error);
      bufferShort[bar] = GetBankersFxVolume(bar, BankersFx.MODE_VOLUME_SHORT); if (last_error != NO_ERROR) return(last_error);

      if (bufferLong [bar] != EMPTY_VALUE) delta =  bufferLong [bar];
      if (bufferShort[bar] != EMPTY_VALUE) delta = -bufferShort[bar];
      bufferMain[bar] = delta;

      // update signal level and duration since last crossing of the opposite level
      if (bar < Bars-1) {
         // if the last signal was up
         if (bufferSignal[bar+1] > 0) {
            if (delta > -Signal.Level) bufferSignal[bar] = bufferSignal[bar+1] + 1; // up continuation
            else                       bufferSignal[bar] = -1;                      // opposite signal (down)
         }

         // if the last signal was down
         else if (bufferSignal[bar+1] < 0) {
            if (delta < Signal.Level) bufferSignal[bar] = bufferSignal[bar+1] - 1;  // down continuation
            else                      bufferSignal[bar] = 1;                        // opposite signal (up)
         }

         // if there was no signal yet
         else /*(bufferSignal[bar+1] == 0)*/ {
            if      (delta >=  Signal.Level) bufferSignal[bar] =  1;                // first signal up
            else if (delta <= -Signal.Level) bufferSignal[bar] = -1;                // first signal down
            else                             bufferSignal[bar] =  0;                // still no signal
         }
      }
   }


   // 3) notify of new signals
   if (!IsSuperContext()) {
      if (signals) /*&&*/ if (EventListener.BarOpen()) {                            // current timeframe
         if      (bufferSignal[1] ==  1) onLevelCross(MODE_UPPER);
         else if (bufferSignal[1] == -1) onLevelCross(MODE_LOWER);
      }
   }
   return(catch("onTick(3)"));
}


/**
 * Event handler called on BarOpen if the volume delta crossed the signal level.
 *
 * @param  int mode - direction identifier: MODE_UPPER | MODE_LOWER
 *
 * @return bool - success status
 */
bool onLevelCross(int mode) {
   string message = "";
   int    success = 0;

   if (mode == MODE_UPPER) {
      message = indicatorShortName +" crossed level "+ Signal.Level;
      log("onLevelCross(1)  "+ message);
      message = Symbol() +","+ PeriodDescription(Period()) +": "+ message;

      if (signal.sound) success &= _int(PlaySoundEx(signal.sound.levelCross.long));
      if (signal.mail)  success &= !SendEmail(signal.mail.sender, signal.mail.receiver, message, "");   // subject only (empty mail body)
      if (signal.sms)   success &= !SendSMS(signal.sms.receiver, message);
      return(success != 0);
   }

   if (mode == MODE_LOWER) {
      message = indicatorShortName +" crossed level -"+ Signal.Level;
      log("onLevelCross(2)  "+ message);
      message = Symbol() +","+ PeriodDescription(Period()) +": "+ message;

      if (signal.sound) success &= _int(PlaySoundEx(signal.sound.levelCross.short));
      if (signal.mail)  success &= !SendEmail(signal.mail.sender, signal.mail.receiver, message, "");   // subject only (empty mail body)
      if (signal.sms)   success &= !SendSMS(signal.sms.receiver, message);
      return(success != 0);
   }

   return(!catch("onLevelCross(3)  invalid parameter mode = "+ mode, ERR_INVALID_PARAMETER));
}


/**
 * Return a "BFX Core Volume" value.
 *
 * @param  int bar    - bar index of the value to return
 * @param  int buffer - buffer index of the value to return
 *
 * @return double - indicator value or NULL in case of errors
 */
double GetBankersFxVolume(int bar, int buffer) {
   if (bar < 0) return(!catch("GetBankersFxVolume(1)  invalid parameter bar: "+ bar, ERR_INVALID_PARAMETER));

   string separator      = "�����������������������������������";    // indicator init() error if empty string
   int    serverId       = 0;
   int    loginTries     = 1;                                        // minimum 1 (in fact tries, not retries)
   string symbolPrefix   = "";
   string symbolSuffix   = "";
   color  colorLong      = Red;
   color  colorShort     = Green;
   color  colorLevel     = Gray;
   int    histogramWidth = 2;
   bool   signalAlert    = false;
   bool   signalPopup    = false;
   bool   signalSound    = false;
   bool   signalMobile   = false;
   bool   signalEmail    = false;

   // initialize the license key
   static string license; if (!StringLen(license)) {
      string section = "bankersfx.com", key = "CoreVolumes.License";
      license = GetConfigString(section, key);
      if (!StringLen(license)) return(!catch("GetBankersFxVolume(2)  missing configuration value ["+ section +"]->"+ key, ERR_INVALID_CONFIG_PARAMVALUE));
   }
   int error;

   // check indicator initialization with MODE_VOLUME_LEVEL on bar 0
   static bool initialized = false; if (!initialized) {
      double level = iCustom(NULL, NULL, indicatorBankersFxName,
                             separator, license, serverId, loginTries, symbolPrefix, symbolSuffix, colorLong, colorShort, colorLevel, histogramWidth, signalAlert, signalPopup, signalSound, signalMobile, signalEmail,
                             BankersFx.MODE_VOLUME_LEVEL, 0);
      if (IsEmptyValue(level)) {
         error = GetLastError();
         if (!error) return(!debug("GetBankersFxVolume(3)  indicator initialization failed", SetLastError(ERR_CUSTOM_INDICATOR_ERROR)));
         else        return(!catch("GetBankersFxVolume(4)  indicator initialization failed", error));
      }
      initialized = true;
   }

   // get the requested value
   double value = iCustom(NULL, NULL, indicatorBankersFxName,
                          separator, license, serverId, loginTries, symbolPrefix, symbolSuffix, colorLong, colorShort, colorLevel, histogramWidth, signalAlert, signalPopup, signalSound, signalMobile, signalEmail,
                          buffer, bar);

   error = GetLastError();
   if (error != NO_ERROR) return(!catch("GetBankersFxVolume(5)", error));

   return(value);
}


/**
 * Set indicator styles. Workaround for various terminal bugs when setting styles or levels. Usually styles are applied in
 * init(). However after recompilation styles must be applied in start() to not get ignored.
 */
void SetIndicatorStyles() {
   SetIndexStyle(MODE_VOLUME_MAIN,   DRAW_NONE,      EMPTY, EMPTY,                 CLR_NONE             );
   SetIndexStyle(MODE_VOLUME_SIGNAL, DRAW_NONE,      EMPTY, EMPTY,                 CLR_NONE             );
   SetIndexStyle(MODE_VOLUME_LONG,   DRAW_HISTOGRAM, EMPTY, Histogram.Style.Width, Histogram.Color.Long );
   SetIndexStyle(MODE_VOLUME_SHORT,  DRAW_HISTOGRAM, EMPTY, Histogram.Style.Width, Histogram.Color.Short);
   SetLevelValue(0, Signal.Level);
}


/**
 * Return a string representation of the input parameters. Used for logging iCustom() calls.
 *
 * @return string
 */
string InputsToStr() {
   return(StringConcatenate("input: ",

                            "Histogram.Color.Long=",  ColorToStr(Histogram.Color.Long),     "; ",
                            "Histogram.Color.Short=", ColorToStr(Histogram.Color.Short),    "; ",
                            "Histogram.Style.Width=", Histogram.Style.Width,                "; ",

                            "Max.Values=",            Max.Values,                           "; ",

                            "Signal.Level=",          Signal.Level,                         "; ",
                            "Signal.onLevelCross=",   DoubleQuoteStr(Signal.onLevelCross),  "; ",
                            "Signal.Sound=",          DoubleQuoteStr(Signal.Sound),         "; ",
                            "Signal.Mail.Receiver=",  DoubleQuoteStr(Signal.Mail.Receiver), "; ",
                            "Signal.SMS.Receiver=",   DoubleQuoteStr(Signal.SMS.Receiver),  "; ")
   );
}
