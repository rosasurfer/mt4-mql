/**
 * STRUCT_intSize    = ceil(sizeof(STRUCT)/sizeof(int))    => 4
 * STRUCT_doubleSize = ceil(sizeof(STRUCT)/sizeof(double)) => 8
 */

// MT4 structs
#define FXT_HEADER_size                    728
#define FXT_HEADER_intSize                 182

#define FXT_TICK_size                       52
#define FXT_TICK_intSize                    13

#define HISTORY_HEADER_size                148
#define HISTORY_HEADER_intSize              37

#define HISTORY_BAR_400_size                44
#define HISTORY_BAR_400_intSize             11

#define HISTORY_BAR_401_size                60
#define HISTORY_BAR_401_intSize             15

#define SYMBOL_size                       1936
#define SYMBOL_intSize                     484

#define SYMBOL_GROUP_size                   80
#define SYMBOL_GROUP_intSize                20

#define SYMBOL_SELECTED_size               128
#define SYMBOL_SELECTED_intSize             32

#define TICK_size                           40
#define TICK_intSize                        10


// Framework structs
#define BAR_size                            48
#define BAR_doubleSize                       6

#define EXECUTION_CONTEXT_size             740
#define EXECUTION_CONTEXT_intSize          185

#define EC.pid                               0     // offsets must be in sync with MT4Expander::header/struct/rsf/ExecutionContext.h
#define EC.previousPid                       1
#define EC.programType                       2
#define EC.programCoreFunction              67
#define EC.programInitReason                68
#define EC.programUninitReason              69
#define EC.programInitFlags                 70
#define EC.programDeinitFlags               71
#define EC.moduleType                       72
#define EC.moduleCoreFunction              137
#define EC.moduleUninitReason              138
#define EC.moduleInitFlags                 139
#define EC.moduleDeinitFlags               140
#define EC.timeframe                       144
#define EC.rates                           145
#define EC.bars                            146
#define EC.validBars                       147
#define EC.changedBars                     148
#define EC.ticks                           149
#define EC.cycleTicks                      150
#define EC.currTickTime                    151
#define EC.prevTickTime                    152
#define EC.digits                          153
#define EC.pipDigits                       154
#define EC.superContext                    159
#define EC.threadId                        160
#define EC.chartWindow                     161
#define EC.chart                           162
#define EC.testing                         163
#define EC.visualMode                      164
#define EC.optimization                    165
#define EC.recorder                        166
#define EC.accountServer                   167
#define EC.accountNumber                   168
#define EC.dllWarning                      169
#define EC.dllError                        171
#define EC.mqlError                        173
#define EC.debugOptions                    174
#define EC.loglevel                        175
#define EC.loglevelDebug                   176
#define EC.loglevelTerminal                177
#define EC.loglevelAlert                   178
#define EC.loglevelFile                    179
#define EC.loglevelMail                    180
#define EC.loglevelSMS                     181

#define LFX_ORDER_size                     120
#define LFX_ORDER_intSize                   30

#define ORDER_EXECUTION_size               136
#define ORDER_EXECUTION_intSize             34


// Win32 structs
#define PROCESS_INFORMATION_size            16
#define PROCESS_INFORMATION_intSize          4

#define RECT_size                           16
#define RECT_intSize                         4

#define RECT.left                            0
#define RECT.top                             1
#define RECT.right                           2
#define RECT.bottom                          3

#define SECURITY_ATTRIBUTES_size            12
#define SECURITY_ATTRIBUTES_intSize          3

#define STARTUPINFO_size                    68
#define STARTUPINFO_intSize                 17

#define WIN32_FIND_DATA_size               318     // doesn't end on an int boundary
#define WIN32_FIND_DATA_intSize             80