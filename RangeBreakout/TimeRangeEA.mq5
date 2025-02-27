//+------------------------------------------------------------------+
//|                                                  TimeRangeEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <trade/trade.mqh>


//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== Trading ====";
static input long InpMagic = 13;    // magic number
static input double InpLots = 0.1;  // lot size
input double InpStopLoss = 130;     // stop loss in % of the range (0% = off)
input double InpTakeProfit = 161.8; // take profit in % of the range (0% = off)
input bool InpBuy = true;
input bool InpSell = true;
input bool InpCloseSiganl = false;

input group "==== Range inputs ====";
input int InpRangeStart = 600;      // range start time in minutes
input int InpRangeDuration = 120;   // range duration in minutes1
input int InpRangeClose = 1200;     // range close time in minutes (-1 = off)

enum BREAKOUT_MODE_ENUM {
   ONE_SIGNAL,                      // one breakout per range
   TWO_SIGNALS                      // high and low breakout
};

input BREAKOUT_MODE_ENUM InpBreakoutMode = ONE_SIGNAL; // breakout mode

input group "=== EMA Indicator ===";
input bool InpEMAIndicator = true;
input int InpEMAPeriod = 5;
input int InpEMAShift=0;
input ENUM_TIMEFRAMES IpnEMATimeFrame = PERIOD_H1;

input group "=== RSI Indicator ==="
input bool InpRsiIndicator = false;
input int InpRSIPeriod = 14;
input ENUM_TIMEFRAMES InpRSITimeFrame = PERIOD_M5;
input double InpRSIOverbought = 80;
input double InpRSIOversold = 20;

input group "==== Day of week filter ====";
input bool InpMonday = true;        // range of monday
input bool InpTuesday = true;       // range of tuesday
input bool InpWednesday = true;     // range of wednesday
input bool InpThursday = true;      // range of thursday
input bool InpFriday = true;        // range of friday
input bool InpSaturday = true;      // range of saturday
input bool InpSunday = true;        // range of sunday

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
struct RANGE_STRUCT {
   datetime start_time; // start of the range
   datetime end_time;   // end of the range
   datetime close_time; // close time
   double high;         // high of the range
   double low;          // low of the range
   bool f_entry;        // flag if the price is inside of the range
   bool f_high_breakout;// flag if a high breakout ocurred
   bool f_low_breakout; // flag if a low breakout ocurred
   
   // Constructor
   RANGE_STRUCT() : start_time(0), end_time(0), close_time(0), high(0), low(DBL_MAX), f_entry(false), f_high_breakout(false), f_low_breakout(false) {}
};

RANGE_STRUCT range;
MqlTick prevTick, lastTick;
CTrade trade;

// EMA
int handle;
double bufferEMA[];

// RSI
int handleRSI = INVALID_HANDLE;
//--- indicator buffer 
double bufferRSI[];

int OnInit() {
   // Validate user inputs
   if (!ValidateInputs()) {
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // set magic number
   trade.SetExpertMagicNumber(InpMagic);
   
   handle = iMA(_Symbol, IpnEMATimeFrame, InpEMAPeriod, InpEMAShift, MODE_EMA, STO_CLOSECLOSE);
   if (handle == INVALID_HANDLE) {
      Alert("Failed to create indicator EMA handle");
      return INIT_FAILED;
   }
   
   // set buffer as series
   ArraySetAsSeries(bufferEMA, true);
   
   handleRSI = iRSI(_Symbol, InpRSITimeFrame, InpRSIPeriod, STO_CLOSECLOSE);
   if (handleRSI == INVALID_HANDLE) {
      Alert("Failed to create indicator RSI handle");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(bufferRSI, true);
   
   // calculated new range if input changed 
   if(_UninitReason == REASON_PARAMETERS && CountOpenPosition() == 0) {
      CalculateRange();
   }
   
   // draw objects
   DrawObjects();
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
  // delete objects
  ObjectsDeleteAll(NULL, "range");
  
  // release indicators handles
  if (handle != INVALID_HANDLE) {
   IndicatorRelease(handle);
  }
  if (handleRSI != INVALID_HANDLE) {
   IndicatorRelease(handleRSI);
  }
}

void OnTick() {
   // Set previous and current tick
   prevTick = lastTick;
   SymbolInfoTick(_Symbol, lastTick);
   
   // range calculation
   if (lastTick.time >= range.start_time && lastTick.time < range.end_time) {
      // set flag
      range.f_entry = true;
      // check for a new high
      if (lastTick.ask > range.high) {
         range.high = lastTick.ask;
         DrawObjects();
      }
      // check for a new low
      if (lastTick.bid < range.low) {
         range.low = lastTick.bid;
         DrawObjects();
      }
   }
   
   // close positions
   if (InpRangeClose >= 0 && lastTick.time >= range.close_time) {
      if(!ClosePositions()) {
         return;
      }
   }
   
   // calculate new range if...
   if (((InpRangeClose >= 0 && lastTick.time >= range.close_time)                       // close time reached
         || (range.f_high_breakout && range.f_low_breakout)                             // both beakout flags are true
         || (range.end_time == 0)                                                       // range not calculated yet
         || (range.end_time != 0 && lastTick.time > range.end_time && !range.f_entry))  // there was a range calculated but no tick inside\
         && CountOpenPosition() == 0) {
      CalculateRange();
   }
   
   // check for breakouts
   CheckBreakouts();
}

// Validate user inputs
bool ValidateInputs() {
   if (InpMagic <= 0) {
      Alert("Magic number <= 0");
      return false;
   }
   if (InpLots <= 0 || InpLots > 4) {
      Alert("Lots <= 0 or Lots > 4");
      return false;
   }
   if (InpStopLoss < 0 || InpLots > 1000) {
      Alert("Stop loss < 0 or > 1000");
      return false;
   }
   if (InpTakeProfit < 0) {
      Alert("Take Profit < 0");
      return false;
   }
   if (InpRangeClose < 0 && InpStopLoss == 0) {
      Alert("Close time and stop loss is off");
      return false;
   }
   if (InpRangeStart < 0 || InpRangeStart >= 1440) {
      Alert("Range start < 0 or Range start >= 1440");
      return false;
   }
   if (InpRangeDuration <= 0 || InpRangeDuration >= 1440) {
      Alert("Range duration <= 0 or Range duration >= 1440");
      return false;
   }
   if (InpRangeClose >= 1440 || (InpRangeStart + InpRangeDuration) % 1440 == InpRangeClose) {
      Alert("Close time >= 1440 or end time == close time");
      return false;
   }
   if (InpEMAPeriod <= 0) {
      Alert("Wrong input: EMA period <= 0");
      return false;
   }
   if (InpEMAShift < 0) {
      Alert("Wrong input: shift of EMA < 0");
      return false;
   }
   if (!InpMonday && !InpTuesday && !InpWednesday && !InpThursday && !InpFriday && !InpSaturday && !InpSunday) {
      Alert("Range is prohibited on all days of the week");
      return false;
   }
   
   return true;
}

// Calculate a new range
void CalculateRange() {
   // reset range variables
   range.start_time = 0;
   range.end_time = 0;
   range.close_time = 0;
   range.high = 0.0;
   range.low = DBL_MAX;
   range.f_entry = false;
   range.f_high_breakout = false;
   range.f_low_breakout = false;
   
   // calculate range start time
   const int time_cycle = 86400; // seconds of one day
   range.start_time = (lastTick.time - (lastTick.time % time_cycle)) + InpRangeStart * 60;
   for (int i = 0; i < 8; i++) {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      const int dow = tmp.day_of_week;
      if (lastTick.time >= range.start_time 
      || (dow == 0 && !InpSunday)
      || (dow == 1 && !InpMonday)
      || (dow == 2 && !InpTuesday)
      || (dow == 3 && !InpWednesday)
      || (dow == 4 && !InpThursday)
      || (dow == 5 && !InpFriday)
      || (dow == 6 && !InpSaturday)) {
         range.start_time += time_cycle;
      } 
   }
   
   // calculate range end time
   range.end_time = range.start_time + InpRangeDuration * 60;
   
   // para forex
   //for(int i = 0; i < 2; i++) {
   //   MqlDateTime tmp;
   //   TimeToStruct(range.start_time, tmp);
   //   int dow = tmp.day_of_week;
   //   if(dow == 6 || dow == 0) {
   //      range.end_time += time_cycle;
   //   } 
   //}
   
   // calculate range close time
   if (InpRangeClose >= 0) {
      range.close_time = (range.end_time - (range.end_time % time_cycle)) + InpRangeClose * 60;
      for (int i = 0; i < 3; i++) {
         MqlDateTime tmp;
         TimeToStruct(range.close_time, tmp);
         const int dow = tmp.day_of_week;
         if (range.close_time <= range.end_time) {
            range.end_time += time_cycle;
         } 
      }
   }
   
   // Draw objects in chart
   DrawObjects();
}

// Count the number of open positions
int CountOpenPosition() {
   int counter = 0;
   int totalPos = PositionsTotal();
   
   for(int i = totalPos - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (ticket <= 0) {
         Print("Failed to get position ticket to counter");
         return -1;
      }
      
      if(!PositionSelectByTicket(ticket)) {
         Print("Failed to select position by ticket");
         return -1;
      }
      
      ulong magicNumber = 0;
      if(!PositionGetInteger(POSITION_MAGIC, magicNumber)) {
         Print("Failet to get magic number");
         return -1;
      }
      
      if(InpMagic == magicNumber) {
         counter++;
      }
   }
   
   return counter;
}

// Check for breakouts
void CheckBreakouts() {
   // check if the price is after the range end
   if (lastTick.time >= range.end_time && range.end_time > 0 && range.f_entry) {
      // check for high breakout
      //if (!range.f_high_breakout && lastTick.ask >= range.high && CheckEMATrend(false) == -1) {
      if (!range.f_high_breakout && lastTick.ask >= range.high) {
         bool goodIndicators = true;
         if (InpEMAIndicator) {
            if (CheckEMATrend(false) != -1) {
               goodIndicators = false;
            }
         } else if (InpRsiIndicator) {
            if (CheckRSILevel(true) != -1) {
               goodIndicators = false;
            }
         }
      //if (!range.f_high_breakout && lastTick.ask >= range.high) {
         if(goodIndicators) {
            range.f_high_breakout = true;
            range.f_low_breakout = InpBreakoutMode == ONE_SIGNAL ? true : range.f_low_breakout;
            
            // calculate SL and TP
            const double sl = InpStopLoss == 0 ? 0 : NormalizeDouble(lastTick.bid - ((range.high - range.low) * InpStopLoss * 0.01), _Digits);
            const double tp = InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.bid + ((range.high - range.low) * InpTakeProfit * 0.01), _Digits);
            
            // open sell position
            if (InpSell) {
               //trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLots, lastTick.ask, sl, tp, "Time range EA: high breakout");
               trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLots, lastTick.bid, tp, sl, "Time range EA: low breakout");
            }
          }
      }
      
      // check for low breakout
      //if (!range.f_low_breakout && lastTick.bid <= range.low && CheckEMATrend(true) == 1 ) {
      if (!range.f_low_breakout && lastTick.bid <= range.low) {
         bool goodIndicators = true;
         if (InpEMAIndicator) {
            if (CheckEMATrend(true) != 1) {
               goodIndicators = false;
            }
         } else if (InpRsiIndicator) {
            if (CheckRSILevel(false) != 1) {
               goodIndicators = false;
            }
         }
         if (goodIndicators) {
            range.f_low_breakout = true;
            range.f_high_breakout = InpBreakoutMode == ONE_SIGNAL ? true : range.f_high_breakout;
            
            // calculate SL and TP
            const double sl = InpStopLoss == 0 ? 0 : NormalizeDouble(lastTick.ask + ((range.high - range.low) * InpStopLoss * 0.01), _Digits);
            const double tp = InpTakeProfit == 0 ? 0 : NormalizeDouble(lastTick.ask - ((range.high - range.low) * InpTakeProfit * 0.01), _Digits);
            
            // open buy position
            if (InpBuy) {
               //trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLots, lastTick.bid, sl, tp, "Time range EA: low breakout");
               trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLots, lastTick.bid, tp, sl, "Time range EA: low breakout"); 
            }
         }
      }
   } 
}

int CheckEMATrend(bool isForUpTrend) {
   if (CopyBuffer(handle, 0, 1, 1, bufferEMA) != 1) {
      Print("Failed to get indicator EMA Values");
      return 0;
   }
   
   if (isForUpTrend) {
      if (bufferEMA[0] < lastTick.bid) {
         return 1;
      }
   } else {
      if (bufferEMA[0] > lastTick.ask) {
         return -1;
      }
   }
   
   return 0;
}

int CheckRSILevel(bool isForOverbought) {
   if (CopyBuffer(handleRSI, 0, 1, 1, bufferRSI) != 1) {
      Print("Failed to get indicator RSI Values");
      return 0;
   }
   
   if (isForOverbought) {
      if (bufferRSI[0] >= InpRSIOverbought) {
         return -1;
      }
   } else {
      if (bufferRSI[0] <= InpRSIOversold) {
         return 1;
      }
   }
   
   return 0;
}

// Close all open positions
bool ClosePositions() {
   int totalPos = PositionsTotal();
   
   for (int i = totalPos - 1; i >= 0; i--) {
      // debido a que podemos tener multiples EA que cierren posiciones, es importante que no nos estemos saltando ninguna posicion, por eso se hace este chequeo.
      if(totalPos != PositionsTotal()) {
         Print("Cambio la cantidad de netradas");
         totalPos = PositionsTotal();
         i = totalPos; continue;
      }
      // select position
      ulong ticket = PositionGetTicket(i);
      
      if (ticket <= 0) {
         Print("Failed tot get position ticket to close");
         return false;
      }
      
      if(!PositionSelectByTicket(ticket)) {
         Print("Failed to select position by ticket to close");
         return false;
      }
      
      long magicNumber = 0;
      
      if(!PositionGetInteger(POSITION_MAGIC, magicNumber)) {
         Print("Failed to get posiiton magic number to close");
         return false;
      }
      
      if (magicNumber == InpMagic) {
         trade.PositionClose(ticket);
         if (trade.ResultRetcode() != TRADE_RETCODE_DONE) {
            Print("Failed to close position. Result: " + (string)trade.ResultRetcode() + trade.ResultRetcodeDescription());
            return false;
         }
      }
   }
   return true;
}

// Draw chart objects
void DrawObjects() {
   // start time
   ObjectDelete(NULL, "range start");
   if (range.start_time > 0) {
      ObjectCreate(NULL, "range start", OBJ_VLINE, 0, range.start_time, 0);
      ObjectSetString(NULL, "range start", OBJPROP_TOOLTIP, "start of the range \n" + TimeToString(range.start_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range start", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range start", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range start", OBJPROP_BACK, true);
   }
   
   // end time
   ObjectDelete(NULL, "range end");
   if (range.end_time > 0) {
      ObjectCreate(NULL, "range end", OBJ_VLINE, 0, range.end_time, 0);
      ObjectSetString(NULL, "range end", OBJPROP_TOOLTIP, "end of the range \n" + TimeToString(range.end_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range end", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range end", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range end", OBJPROP_BACK, true);
   }
   
   // close time
   ObjectDelete(NULL, "range close");
   if (range.close_time > 0) {
      ObjectCreate(NULL, "range close", OBJ_VLINE, 0, range.close_time, 0);
      ObjectSetString(NULL, "range close", OBJPROP_TOOLTIP, "close of the range \n" + TimeToString(range.close_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range close", OBJPROP_COLOR, clrGold);
      ObjectSetInteger(NULL, "range close", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range close", OBJPROP_BACK, true);
   }
   
   // high
   ObjectsDeleteAll(NULL, "range high");
   if (range.high > 0) {
      ObjectCreate(NULL, "range high", OBJ_TREND, 0, range.start_time, range.high, range.end_time, range.high);
      ObjectSetString(NULL, "range high", OBJPROP_TOOLTIP, "high of the range \n" + DoubleToString(range.high, _Digits));
      ObjectSetInteger(NULL, "range high", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range high", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range high", OBJPROP_BACK, true);
      
      ObjectCreate(NULL, "range high ", OBJ_TREND, 0, range.end_time, range.high, InpRangeClose >= 0 ? range.close_time : INT_MAX, range.high);
      ObjectSetString(NULL, "range high ", OBJPROP_TOOLTIP, "high of the range \n" + DoubleToString(range.high, _Digits));
      ObjectSetInteger(NULL, "range high ", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range high ", OBJPROP_BACK, true);
      ObjectSetInteger(NULL, "range     ", OBJPROP_STYLE, STYLE_DOT);
   }
   
   // low
   ObjectsDeleteAll(NULL, "range low");
   if (range.low < DBL_MAX) {
      ObjectCreate(NULL, "range low", OBJ_TREND, 0, range.start_time, range.low, range.end_time, range.low);
      ObjectSetString(NULL, "range low", OBJPROP_TOOLTIP, "low of the range \n" + DoubleToString(range.low, _Digits));
      ObjectSetInteger(NULL, "range low", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range low", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range low", OBJPROP_BACK, true);
      
      ObjectCreate(NULL, "range low ", OBJ_TREND, 0, range.end_time, range.low, InpRangeClose >= 0 ? range.close_time : INT_MAX, range.low);
      ObjectSetString(NULL, "range low ", OBJPROP_TOOLTIP, "low of the range \n" + DoubleToString(range.low, _Digits));
      ObjectSetInteger(NULL, "range low ", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range low ", OBJPROP_BACK, true);
      ObjectSetInteger(NULL, "range low ", OBJPROP_STYLE, STYLE_DOT);
   }
   
   // refresh chart
   ChartRedraw();
}
