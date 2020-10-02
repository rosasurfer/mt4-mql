/**
 * Reopen the alert dialog window.
 */
#include <stddefines.mqh>
int   __InitFlags[] = {INIT_NO_BARS_REQUIRED};
int __DeinitFlags[];
#include <core/script.mqh>
#include <stdfunctions.mqh>


/**
 * Main function
 *
 * @return int - error status
 */
int onStart() {
   if (!ReopenAlertDialog(true)) {
      PlaySoundEx("Plonk.wav");
      logInfo("onStart(1)  \"Alert\" dialog window not found.");
   }
   return(catch("onStart(2)"));
}
