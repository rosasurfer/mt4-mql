/**
 * Gibt alle verf�gbaren MarketInfos des aktuellen Instruments aus.
 */
#include <stdtypes.mqh>
#define     __TYPE__    T_SCRIPT
int   __INIT_FLAGS__[];
int __DEINIT_FLAGS__[];
#include <stdlib.mqh>


/**
 * Main-Funktion
 *
 * @return int - Fehlerstatus
 */
int onStart() {
   DebugMarketInfo();
   return(catch("onStart()"));
}
