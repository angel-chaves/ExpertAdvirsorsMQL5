//+------------------------------------------------------------------+
//|                                         PatternRecognitionEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Math/Stat/Stat.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "=== General ==="
input ulong InpMagic = 83736;    // magic number
input double InpLots = 0.01;     // lot size
input group "=== Pattern ==="
static input string InpFileName = "pattern_stepindex.csv";   // file name
input double InpMinCorrel = 0.8;                      // min pattern correlation
input int InpMinSizePct = 80;                         // min pattern size in %
input bool InpOperateNegCorrel = true;                          // operate negative correlation too
input group "=== Trading ==="
input ENUM_ORDER_TYPE InpOrderType = ORDER_TYPE_BUY;  // order type
input int InpOrderLevelPct = 20;                      // order level in %
input int InpStopLossPct = 120;                       // stop loss in %
input int InpTakeProfitPct = 200;                     // take profit in %
input int InpExpirationDays = 1;
input group "=== Thecnical Indicators ==="
input int InpRSIPeriod = 14;  // Periodo del RSI
input int InpEMAPeriod = 50;  // Periodo de la EMA

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
MqlTick tick;
CTrade trade;
double pattern[];
int patternBars = 0;
int patternSizePts = 0;

// RSI
int handleRSI = INVALID_HANDLE;
double RSIBuffer[];
// ema
//int handleEMA = INVALID_HANDLE;
//double EMABuffer[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // check user inputs
   if (!CheckInputs()) { return INIT_PARAMETERS_INCORRECT; }
   
   // set magicnumber to trade object
   trade.SetExpertMagicNumber(InpMagic);
  
   // load pattern into global pattern array
   if (!LoadPattern()) { return INIT_FAILED;}
   
   // Crear el handle del indicador Stochastic
   handleRSI = iRSI(_Symbol, _Period, InpRSIPeriod, STO_CLOSECLOSE);
   
   if (handleRSI == INVALID_HANDLE){
      Print("UNABLE TO INITIALIZE THE STOCHASTIC IND CORRECTLY. REVERTING NOW.");
      return (INIT_FAILED);
   }
   
   // Crear el handle del indicador Stochastic
   //handleEMA = iMA(_Symbol, EMATimeFrame, EMAPeriod, EMAShift, MODE_EMA, STO_CLOSECLOSE);
   
   //if (handleEMA == INVALID_HANDLE){
   //   Print("UNABLE TO INITIALIZE THE STOCHASTIC IND CORRECTLY. REVERTING NOW.");
   //   return (INIT_FAILED);
   //}
   
   // draw pattern
   //DrawPattern();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
      ObjectsDeleteAll(NULL, "patternBar");
      ObjectsDeleteAll(NULL, "mark");
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      if (!isNewBar()) { return;}
      
      // get current symbol tick
      if(!SymbolInfoTick(_Symbol, tick)) { 
         Print("Failed to get symbol tick");
         return;
      }
      
      // get close prices
      double closeArr[];
      CopyClose(_Symbol, _Period, 1, patternBars, closeArr);
      
      // calculate correlation
      double correl;
      if (!MathCorrelationPearson(pattern, closeArr, correl)) {
         Print("Failed to calculate correlation");
         return;
      }
      
      int sizePts = (int)((closeArr[ArrayMaximum(closeArr)] - closeArr[ArrayMinimum(closeArr)]) / _Point);
      double sizePct = sizePts / (double)patternSizePts * 100;
      
      //Print("Correlation: ", correl, ", size in points: ", sizePts, ", % of search pattern: ", DoubleToString(sizePct, 2));
      
      //DrawPattern();
      
      // check correlation threshold
      if ((correl > InpMinCorrel || (correl < -InpMinCorrel && InpOperateNegCorrel)) && sizePct >= InpMinSizePct) {
         //DrawMark(correl > InpMinCorrel);
         if (PositionsTotal() == 0 && OrdersTotal() == 0) {
            if (CopyBuffer(handleRSI,0,1,1,RSIBuffer) < 1) {
               Print("UNABLE TO GET ENOUGH RSI BUFFER DATA'. REVERTING.");
               return;
            }
            //if (CopyBuffer(handleEMA,0,1,1,EMABuffer) < 1) {
            //   Print("UNABLE TO GET ENOUGH EMA BUFFER DATA'. REVERTING.");
            //   return;
            //}
            
            const double RSILevel = RSIBuffer[0];
            //const double EMAValue  = EMABuffer[0];
            
            bool placeOrder = true;
            if (InpOrderType == ORDER_TYPE_BUY &&
                RSILevel > 30) {
               placeOrder = false;
            }  else if (InpOrderType == ORDER_TYPE_SELL && RSILevel < 70) {
               placeOrder = false;
            }
            if (placeOrder) {
               PlaceOrder(correl > InpMinCorrel, closeArr);
            }
         }
      }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

// check user inputs
bool CheckInputs() {
   if(InpMagic <= 0) {
      Alert("Wrong input: Magicnumber <= 0");
      return false;
   }
   if(InpLots <= 0) {
      Alert("Wrong input: Lots <= 0");
      return false;
   }
   if(!FileIsExist(InpFileName, FILE_COMMON)) {
      Alert("Wrong input: File "+ InpFileName + " does not exist");
      return false;
   }
   if(InpMinCorrel < 0) {
      Alert("Wrong input: Min correlation < 0");
      return false;
   }
   if(InpMinSizePct < 0) {
      Alert("Wrong input: Min pattern size filter < 0");
      return false;
   }
   
   return true;
}

// 
bool LoadPattern() {
   int handle = FileOpen(InpFileName, FILE_READ|FILE_ANSI|FILE_CSV|FILE_COMMON, '\t');
   if (handle == INVALID_HANDLE) {
      Alert("Failed to open csv file: ", GetLastError());
      return false;
   }
   
   int line = 0;
   int col = 0;
   
   while(!FileIsEnding(handle)) {
      string str = FileReadString(handle);
      
      // filter to avoid header line and only read close prices
      if (line > 0 && col == 6) {
         int size = ArraySize(pattern);
         ArrayResize(pattern, size + 1);
         pattern[size] = StringToDouble(str);
      }
      
      if (FileIsLineEnding(handle)) {
         line++;
         col = 0;
      }
      
      col++;
   }
   
   FileClose(handle);
   
   ArrayPrint(pattern);
   
   // set pattern properties
   patternBars = ArraySize(pattern);
   
   patternSizePts = (int)((pattern[ArrayMaximum(pattern)] - pattern[ArrayMinimum(pattern)]) / _Point);
   Print("Search pattern size in pts: ", patternSizePts, ", Search pattern bars: ", patternBars);
   
   return true;
}

// draw pattern
void DrawPattern() {
   for (int i = 0; i < patternBars; i++) {
      string name = "patternBar" + (string)i;
      ObjectCreate(NULL, name, OBJ_ARROW, 0, iTime(_Symbol, _Period, patternBars - i), 
                     pattern[i] - (pattern[patternBars - 1] - iClose(_Symbol, _Period, 1)));
      ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, name, OBJPROP_ARROWCODE, 159);
   }
   
   ChartRedraw();
}

// draw a mark on the chart
void DrawMark(bool buy_sell) {
   // draw vertical line
   string name = "mark" + TimeToString(TimeCurrent());
   ObjectCreate(NULL, name, OBJ_VLINE, 0, TimeCurrent(), 0);
   ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrBlue);
   
   // draw pattern
   for (int i = 0; i < patternBars; i++) {
      double offset = pattern[patternBars - 1] - iClose(_Symbol, _Period, 1);
      string name = "patternBar" +TimeToString(TimeCurrent()) + (string)i;
      ObjectCreate(NULL, name, OBJ_ARROW, 0, iTime(_Symbol, _Period, patternBars - i), 
                     buy_sell ? pattern[i] - offset 
                     : pattern[i] - offset + 2 * (iClose(_Symbol, _Period, 1) - (pattern[i] - offset)));
      ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, name, OBJPROP_ARROWCODE, 159);
   }
}

// check for new bar open tick
bool isNewBar() {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, _Period, 0);// the current bar oper time
   if (previousTime!=currentTime) {
      previousTime = currentTime;
      return true;
   }
   return false;
}

void PlaceOrder(bool buy_sell, double &closeArr[]) {
   // set pending order price, calculate stop loss and take profit
   double price, sl, tp;
   const double max = closeArr[ArrayMaximum(closeArr)];
   const double min = closeArr[ArrayMinimum(closeArr)];
   const double span = max - min;

   price = buy_sell ? min + InpOrderLevelPct * 0.01 * span : max - InpOrderLevelPct * 0.01 * span;
   sl = InpStopLossPct * 0.01 * span;
   tp = InpTakeProfitPct * 0.01 * span;
   
   
   //place order
   switch(InpOrderType) {
      case ORDER_TYPE_BUY:
         if (buy_sell) { 
            trade.Buy(InpLots, _Symbol, tick.ask, tick.bid - sl, tick.bid + tp);
         } else {
            trade.Sell(InpLots, _Symbol, tick.bid, tick.ask + sl, tick.ask - tp);
         }
         break;
      case ORDER_TYPE_SELL:
         if (buy_sell) { 
            trade.Sell(InpLots, _Symbol, tick.bid, tick.ask + sl, tick.ask - tp);
         } else {
            trade.Buy(InpLots, _Symbol, tick.ask, tick.bid - sl, tick.bid + tp);
         }
         break;
      case ORDER_TYPE_BUY_LIMIT:
         if (buy_sell) { 
            trade.BuyLimit(InpLots, price, _Symbol, price - sl, price + tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         } else {
            trade.SellLimit(InpLots, price, _Symbol, price + sl, price - tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         }
         break;
      case ORDER_TYPE_SELL_LIMIT:
         if (buy_sell) { 
            trade.SellLimit(InpLots, price, _Symbol, price - sl, price + tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         } else {
            trade.BuyLimit(InpLots, price, _Symbol, price + sl, price - tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         }
         break;
      case ORDER_TYPE_BUY_STOP:
         if (buy_sell) { 
            trade.BuyStop(InpLots, price, _Symbol, price - sl, price + tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         } else {
            trade.SellStop(InpLots, price, _Symbol, price + sl, price - tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         }
         break;
      case ORDER_TYPE_SELL_STOP:
         if (buy_sell) { 
            trade.SellStop(InpLots, price, _Symbol, price + sl, price - tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         } else {
            trade.BuyStop(InpLots, price, _Symbol, price - sl, price + tp, ORDER_TIME_SPECIFIED, TimeCurrent() + 86400*InpExpirationDays);
         }
         break;
      default: Print("Unknown order type");
   }
}