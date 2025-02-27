//+------------------------------------------------------------------+
//|                                                 CountMaxLoss.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input double InpInterval = 500; // interval in minutes

int MaxTicks = 0;
int CurrentTicks = 0;
int CurrentIntervalTicks = 0;
double MaxNegativePointsInterval = 0;

MqlTick prevTick, lastTick;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("Max ticks ", MaxTicks);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   // Set previous and current tick
   prevTick = lastTick;
   SymbolInfoTick(_Symbol, lastTick);
   
   //if (CurrentTicks >= InpInterval) {
      if (CurrentTicks > MaxTicks) {
         MaxTicks = CurrentTicks;
      }
   //}
   
   if (prevTick.ask > lastTick.ask) {
      CurrentTicks += 1;
   } else {
      CurrentTicks = 0;
   }
   
  }
//+------------------------------------------------------------------+
