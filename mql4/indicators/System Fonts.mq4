/**
 * Zeigt einen Schriftzug in unterschiedlichen Gr��en und Schriften an.
 */
#include <stdlib.mqh>

#property indicator_chart_window


string text            = "jagt im komplett verwahrl. Taxi 1234,567,890.50 | ";
//string text            = "WDRW-MB-4692: USD 4.95 buy limit | ";

color  backgroundColor = C'212,208,200';
color  fontColor       = Blue;
string fontNames[]     = { "", "System", "Arial", "Arial Kursiv", "Arial Fett", "Arial Black", "Arial Narrow", "Arial Narrow Fett", "Century Gothic", "Century Gothic Fett", "Comic Sans MS", "Comic Sans MS Fett", "Eurostile", "Franklin Gothic Medium", "Lucida Console", "Lucida Sans", "Microsoft Sans Serif", "MS Sans Serif", "Tahoma", "Tahoma Fett", "Trebuchet MS", "Verdana", "Verdana Fett", "Vrinda", "Courier", "Courier New", "Courier New Fett", "FOREXTools", "MS Serif" };
string chartObjects[];


/**
 * Initialisierung
 *
 * @return int - Fehlerstatus
 */
int init() {
   if (onInit(T_INDICATOR) != NO_ERROR)
      return(last_error);

   // Datenanzeige ausschalten
   SetIndexLabel(0, NULL);

   CreateLabels();
   return(catch("init()"));
}


/**
 * Deinitialisierung
 *
 * @return int - Fehlerstatus
 */
int deinit() {
   RemoveChartObjects(chartObjects);
   return(catch("deinit()"));
}


/**
 * Main-Funktion
 *
 * @return int - Fehlerstatus
 */
int onTick() {
   return(catch("onTick()"));
}


/**
 *
 */
int CreateLabels() {
   int fromFontSize = 8;
   int toFontSize   = 14;

   int names = ArraySize(fontNames);
   int c = 100;

   for (int fontSize=fromFontSize; fontSize < toFontSize; fontSize++) {
      // Backgrounds
      c++;
      string label = StringConcatenate(__SCRIPT__, ".", c, ".Background");
      if (ObjectFind(label) > -1)
         ObjectDelete(label);
      if (ObjectCreate(label, OBJ_LABEL, 0, 0, 0)) {
         ObjectSet(label, OBJPROP_CORNER, CORNER_TOP_LEFT);
         ObjectSet(label, OBJPROP_XDISTANCE, (fontSize-fromFontSize)*520 + 14);
         ObjectSet(label, OBJPROP_YDISTANCE, 90);
         ObjectSetText(label, "g", 390, "Webdings", backgroundColor);
         ArrayPushString(chartObjects, label);
      }
      else GetLastError();

      // Textlabel
      int yCoord = 100;
      for (int i=0; i < names; i++) {
         c++;
         label = StringConcatenate(__SCRIPT__, ".", c, ".", fontNames[i]);
         if (ObjectFind(label) > -1)
            ObjectDelete(label);
         if (ObjectCreate(label, OBJ_LABEL, 0, 0, 0)) {
            ObjectSet(label, OBJPROP_CORNER, CORNER_TOP_LEFT);
            ObjectSet(label, OBJPROP_XDISTANCE, (fontSize-fromFontSize)*520 + 20);
            ObjectSet(label, OBJPROP_YDISTANCE, i*17 + yCoord);
            ObjectSetText(label, StringConcatenate(text, ifString(fontNames[i]=="", fontSize, fontNames[i])), fontSize, fontNames[i], fontColor);
            ArrayPushString(chartObjects, label);
         }
         else GetLastError();
      }
   }

   return(catch("CreateLabels()"));
}
