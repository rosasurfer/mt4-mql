/**
 * Default init() functions for standard EAs.
 */


/**
 * Initialization preprocessing.
 *
 * @return int - error status
 */
int onInit() {
   CreateStatusBox();

   int digits = MathMax(Digits, 2);                // transform Digits=1 to 2 (for some indices)
   if (digits > 2) {
      pUnit       = "pip";
      pDigits     = 1;
      pMultiplier = MathRound(1/Pip);
   }
   else {
      pUnit       = "point";
      pDigits     = 2;
      pMultiplier = 1;
   }
   return(catch("onInit(1)"));
}


/**
 * Called after the expert was manually loaded by the user. Also in tester with both "VisualMode=On|Off".
 * There was an input dialog.
 *
 * @return int - error status
 */
int onInitUser() {
   if (ValidateInputs.ID()) {                      // TRUE: a valid instance id was specified
      if (RestoreInstance()) {                     // try to reload the given instance
         logInfo("onInitUser(1)  "+ instance.name +" restored in status \""+ StatusDescription(instance.status) +"\" from file \""+ GetStatusFilename(true) +"\"");
      }
   }
   else if (StrTrim(Instance.ID) == "") {          // no instance id was specified
      if (ValidateInputs()) {
         instance.isTest  = __isTesting;
         instance.id      = CreateInstanceId();
         Instance.ID      = ifString(instance.isTest, "T", "") + StrPadLeft(instance.id, 3, "0"); SS.InstanceName();
         instance.created = GetLocalTime();
         instance.status  = STATUS_WAITING;
         logInfo("onInitUser(2)  instance "+ instance.name +" created");
         SaveStatus();
      }
   }
   //else {}                                       // an invalid instance id was specified
   return(last_error);
}


/**
 * Called after the input parameters were changed through the input dialog.
 *
 * @return int - error status
 */
int onInitParameters() {
   if (!ValidateInputs()) {
      RestoreInputs();
      return(last_error);
   }
   SaveStatus();
   return(last_error);
}


/**
 * Called after the chart timeframe has changed. There was no input dialog.
 *
 * @return int - error status
 */
int onInitTimeframeChange() {
   RestoreInputs();
   return(NO_ERROR);
}


/**
 * Called after the chart symbol has changed. There was no input dialog.
 *
 * @return int - error status
 */
int onInitSymbolChange() {
   return(catch("onInitSymbolChange(1)", ERR_ILLEGAL_STATE));
}


/**
 * Called after the expert was loaded by a chart template. Also at terminal start. There was no input dialog.
 *
 * @return int - error status
 */
int onInitTemplate() {
   if (RestoreVolatileStatus()) {                  // an instance id was found and restored
      if (RestoreInstance()) {                     // the instance was restored
         logInfo("onInitTemplate(1)  "+ instance.name +" restored in status \""+ StatusDescription(instance.status) +"\" from file \""+ GetStatusFilename(true) +"\"");
      }
      return(last_error);
   }
   return(catch("onInitTemplate(2)  could not restore instance id from anywhere, aborting...", ERR_RUNTIME_ERROR));
}


/**
 * Called after the expert was recompiled. There was no input dialog.
 *
 * @return int - error status
 */
int onInitRecompile() {
   if (RestoreVolatileStatus()) {                  // same as for onInitTemplate()
      if (RestoreInstance()) {
         logInfo("onInitRecompile(1)  "+ instance.name +" restored in status \""+ StatusDescription(instance.status) +"\" from file \""+ GetStatusFilename(true) +"\"");
      }
      return(last_error);
   }
   return(catch("onInitRecompile(2)  could not restore instance id from anywhere, aborting...", ERR_RUNTIME_ERROR));
}


/**
 * Initialization postprocessing. Not called if the reason-specific init handler returned with an error.
 *
 * @return int - error status
 */
int afterInit() {
   if (__isTesting || !IsTestInstance()) {         // open the log file (flushes the log buffer) except if a finished test
      if (!SetLogfile(GetLogFilename())) return(catch("afterInit(1)"));
   }
   if (__isTesting) ReadTestConfiguration();

   StoreVolatileStatus();                          // store the instance id for template reload/restart/recompilation etc.
   return(catch("afterInit(2)"));
}