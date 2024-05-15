/**
 * Framework struct EXECUTION_CONTEXT
 *
 * A shared storage context for runtime variables, data exchange and communication between MQL modules and MT4Expander DLL.
 *
 * @link  https://github.com/rosasurfer/mt4-expander/blob/master/header/struct/rsf/ExecutionContext.h
 *
 *
 * TODO:
 *  - indicators loaded in a library must use a temporary copy of the main module context for their init() cycles
 *  - integrate __STATUS_OFF and __STATUS_OFF.reason
 */
#import "rsfMT4Expander.dll"
   // getters
   int      ec_Pid                  (int ec[]);
   int      ec_PreviousPid          (int ec[]);

   int      ec_ProgramType          (int ec[]);
   string   ec_ProgramName          (int ec[]);
   int      ec_ProgramCoreFunction  (int ec[]);
   int      ec_ProgramInitReason    (int ec[]);
   int      ec_ProgramUninitReason  (int ec[]);
   int      ec_ProgramInitFlags     (int ec[]);
   int      ec_ProgramDeinitFlags   (int ec[]);

   int      ec_ModuleType           (int ec[]);
   string   ec_ModuleName           (int ec[]);
   int      ec_ModuleCoreFunction   (int ec[]);
   int      ec_ModuleUninitReason   (int ec[]);
   int      ec_ModuleInitFlags      (int ec[]);
   int      ec_ModuleDeinitFlags    (int ec[]);

   string   ec_Symbol               (int ec[]);
   int      ec_Timeframe            (int ec[]);
   //       ec.newSymbol
   //       ec.newTimeframe
   //       ec.rates
   int      ec_Bars                 (int ec[]);
   int      ec_ValidBars            (int ec[]);
   int      ec_ChangedBars          (int ec[]);
   int      ec_Ticks                (int ec[]);
   //       ec.cycleTicks
   datetime ec_CurrTickTime         (int ec[]);
   datetime ec_PrevTickTime         (int ec[]);
   double   ec_Bid                  (int ec[]);
   double   ec_Ask                  (int ec[]);

   int      ec_Digits               (int ec[]);
   int      ec_PipDigits            (int ec[]);
   double   ec_Pip                  (int ec[]);
   double   ec_Point                (int ec[]);
   int      ec_PipPoints            (int ec[]);
   string   ec_PriceFormat          (int ec[]);
   string   ec_PipPriceFormat       (int ec[]);

   bool     ec_SuperContext         (int ec[], int target[]);
   string   ec_SuperProgramName     (int pid);
   int      ec_SuperLoglevel        (int pid);
   int      ec_SuperLoglevelTerminal(int pid);
   int      ec_SuperLoglevelAlert   (int pid);
   int      ec_SuperLoglevelDebug   (int pid);
   int      ec_SuperLoglevelFile    (int pid);
   int      ec_SuperLoglevelMail    (int pid);
   int      ec_SuperLoglevelSMS     (int pid);

   int      ec_ThreadId             (int ec[]);
   int      ec_hChart               (int ec[]);
   int      ec_hChartWindow         (int ec[]);

   bool     ec_Testing              (int ec[]);
   bool     ec_VisualMode           (int ec[]);
   bool     ec_Optimization         (int ec[]);
   int      ec_Recorder             (int ec[]);

   string   ec_AccountServer        (int ec[]);
   int      ec_AccountNumber        (int ec[]);

   int      ec_MqlError             (int ec[]);
   int      ec_DllError             (int ec[]);
   //       ec.dllErrorMsg
   int      ec_DllWarning           (int ec[]);
   //       ec.dllWarningMsg

   int      ec_Loglevel             (int ec[]);
   int      ec_LoglevelTerminal     (int ec[]);
   int      ec_LoglevelAlert        (int ec[]);
   int      ec_LoglevelDebug        (int ec[]);
   int      ec_LoglevelFile         (int ec[]);
   int      ec_LoglevelMail         (int ec[]);
   int      ec_LoglevelSMS          (int ec[]);
   //       ec.logger
   //       ec.logBuffer
   string   ec_LogFilename          (int ec[]);


   // used setters
   int      ec_SetProgramCoreFunction(int ec[], int id   );
   int      ec_SetRecorder           (int ec[], int mode );
   int      ec_SetMqlError           (int ec[], int error);
   int      ec_SetDllError           (int ec[], int error);
   int      ec_SetLoglevel           (int ec[], int level);
   int      ec_SetLoglevelTerminal   (int ec[], int level);
   int      ec_SetLoglevelAlert      (int ec[], int level);
   int      ec_SetLoglevelDebug      (int ec[], int level);
   int      ec_SetLoglevelFile       (int ec[], int level);
   int      ec_SetLoglevelMail       (int ec[], int level);
   int      ec_SetLoglevelSMS        (int ec[], int level);


   // helpers
   string   EXECUTION_CONTEXT_toStr  (int ec[]);
   string   lpEXECUTION_CONTEXT_toStr(int lpEc);
#import