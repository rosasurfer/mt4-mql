/**
 * Deinitialisierung Preprocessing-Hook
 *
 * @return int - Fehlerstatus
 */
int onDeinit() {
   RemoveChartObjects();
   QC.StopChannels();
   return(last_error);
}


/**
 * außerhalb iCustom(): bei Parameteränderung
 * innerhalb iCustom(): nie
 *
 * @return int - Fehlerstatus
 */
int onDeinitParameterChange() {
   string symbol[1]; symbol[0] = Symbol();

   // LFX-Orders in Library zwischenspeichern
   int error = ChartInfos.CopyLfxOrders(true, symbol, lfxOrders);
   if (IsError(error))
      return(SetLastError(error));
   return(NO_ERROR);
}


/**
 * außerhalb iCustom(): bei Symbol- oder Timeframewechsel
 * innerhalb iCustom(): nie
 *
 * @return int - Fehlerstatus
 */
int onDeinitChartChange() {
   string symbol[1]; symbol[0] = Symbol();

   // LFX-Orders in Library zwischenspeichern
   int error = ChartInfos.CopyLfxOrders(true, symbol, lfxOrders);
   if (IsError(error))
      return(SetLastError(error));
   return(NO_ERROR);
}


/**
 * außerhalb iCustom(): Indikator von Hand entfernt oder Chart geschlossen, auch vorm Laden eines Profils oder Templates
 * innerhalb iCustom(): in allen deinit()-Fällen
 *
 * @return int - Fehlerstatus
 */
int onDeinitRemove() {
   // LFX-Orders in Datei speichern
   if (!LFX.SaveOrders(lfxOrders))
         return(last_error);
   return(NO_ERROR);
}


/**
 * außerhalb iCustom(): bei Recompilation
 * innerhalb iCustom(): nie
 *
 * @return int - Fehlerstatus
 */
int onDeinitRecompile() {
   // LFX-Orders in Datei speichern
   if (!LFX.SaveOrders(lfxOrders))
         return(last_error);
   return(NO_ERROR);
}


/**
 * Deinitialisierung Postprocessing-Hook
 *
 * @return int - Fehlerstatus
 *
int afterDeinit() {
   return(NO_ERROR);
}
*/
