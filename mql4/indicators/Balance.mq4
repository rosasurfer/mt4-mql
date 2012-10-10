/**
 * Balance-Verlauf des aktuellen Accounts als Linienchart im Indikator-Subfenster
 */
#include <core.define.mqh>
#define     __TYPE__   T_INDICATOR
int   __INIT_FLAGS__[];
int __DEINIT_FLAGS__[];
#include <stddefine.mqh>
#include <stdlib.mqh>

#include <core.indicator.mqh>

#property indicator_separate_window

#property indicator_buffers 1
#property indicator_color1  Blue


double iBalance[];


/**
 * Initialisierung
 *
 * @return int - Fehlerstatus
 */
int onInit() {
   // ERR_TERMINAL_NOT_YET_READY abfangen
   if (!GetAccountNumber())
      return(SetLastError(stdlib_PeekLastError()));

   SetIndexBuffer(0, iBalance);
   SetIndexLabel (0, "Balance");
   IndicatorShortName("Balance");
   IndicatorDigits(2);

   return(catch("onInit()"));
}


/**
 * Main-Funktion
 *
 * @return int - Fehlerstatus
 */
int onTick() {
   // Abschlu� der Buffer-Initialisierung �berpr�fen
   if (ArraySize(iBalance) == 0)                                     // kann bei Terminal-Start auftreten
      return(SetLastError(ERR_TERMINAL_NOT_YET_READY));

   // Alle Werte komplett ...
   if (ValidBars == 0) {
      ArrayInitialize(iBalance, EMPTY_VALUE);      // vor Neuberechnung alte Werte zur�cksetzen
      last_error = iAccountBalanceSeries(AccountNumber(), iBalance);
   }
   else {                                          // ... oder nur die fehlenden Werte berechnen
      for (int bar=ChangedBars-1; bar >= 0; bar--) {
         last_error = iAccountBalance(AccountNumber(), iBalance, bar);
         if (last_error != NO_ERROR)
            break;
      }
   }

   return(catch("onTick()"));
}


