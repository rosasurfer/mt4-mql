/**
 * Return a string representation of a history record suitable for SaveStatus().
 *
 * @param  int index - index of the history record
 *
 * @return string
 */
string HistoryRecordToStr(int index) {
   // result: ticket,type,lots,openTime,openPrice,openPriceSig,closeTime,closePrice,closePriceSig,slippage,swap,commission,grossProfit,netProfit,netProfitP,runupP,drawdownP,sigProfitP,sigRunupP,sigDrawdownP

   int      ticket        = history[index][H_TICKET        ];
   int      type          = history[index][H_TYPE          ];
   double   lots          = history[index][H_LOTS          ];
   datetime openTime      = history[index][H_OPENTIME      ];
   double   openPrice     = history[index][H_OPENPRICE     ];
   double   openPriceSig  = history[index][H_OPENPRICE_SIG ];
   datetime closeTime     = history[index][H_CLOSETIME     ];
   double   closePrice    = history[index][H_CLOSEPRICE    ];
   double   closePriceSig = history[index][H_CLOSEPRICE_SIG];
   double   slippage      = history[index][H_SLIPPAGE      ];
   double   swap          = history[index][H_SWAP          ];
   double   commission    = history[index][H_COMMISSION    ];
   double   grossProfit   = history[index][H_GROSSPROFIT   ];
   double   netProfit     = history[index][H_NETPROFIT     ];
   double   netProfitP    = history[index][H_NETPROFIT_P   ];
   double   runupP        = history[index][H_RUNUP_P       ];
   double   drawdownP     = history[index][H_DRAWDOWN_P    ];
   double   sigProfitP    = history[index][H_SIG_PROFIT_P  ];
   double   sigRunupP     = history[index][H_SIG_RUNUP_P   ];
   double   sigDrawdownP  = history[index][H_SIG_DRAWDOWN_P];

   return(StringConcatenate(ticket, ",", type, ",", DoubleToStr(lots, 2), ",", openTime, ",", DoubleToStr(openPrice, Digits), ",", DoubleToStr(openPriceSig, Digits), ",", closeTime, ",", DoubleToStr(closePrice, Digits), ",", DoubleToStr(closePriceSig, Digits), ",", DoubleToStr(slippage, Digits), ",", DoubleToStr(swap, 2), ",", DoubleToStr(commission, 2), ",", DoubleToStr(grossProfit, 2), ",", DoubleToStr(netProfit, 2), ",", NumberToStr(netProfitP, ".1+"), ",", DoubleToStr(runupP, Digits), ",", DoubleToStr(drawdownP, Digits), ",", DoubleToStr(sigProfitP, Digits), ",", DoubleToStr(sigRunupP, Digits), ",", DoubleToStr(sigDrawdownP, Digits)));
}

