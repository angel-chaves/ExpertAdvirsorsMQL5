//+------------------------------------------------------------------+
//|                                    Basic Harmonic Pattern EA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, mutiiriallan.forex@gmail.com."
#property link      "mutiiriallan.forex@gmail.com"
#property description "Incase of anything with this Version of EA, Contact:\n"
                      "\nEMAIL: mutiiriallan.forex@gmail.com"
                      "\nWhatsApp: +254 782 526088"
                      "\nTelegram: https://t.me/Forex_Algo_Trader"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade obj_Trade;

int handle_BHP = INVALID_HANDLE; // -1
int handleStochastic = INVALID_HANDLE;

//--- BHP parameters
input string PatternSettings="=====================";
input int MaxBars=1000;
input bool Delay=false;
input bool ShowLogo=true;
input bool showOnlyLast=false;
input bool hidePrevNumbers=false;
input string GartleySettings="=====================";
input bool Gartley=true;
input double Gartley_dev=0.0;
input long Gartley_Bull=16760576;
input long Gartley_Bear=255;
input double Gartley_Trans=70.0;
input string ButterflySettings="=====================";
input bool Butterfly=true;
input double Butterfly_dev=0.0;
input long Butterfly_Bull=16776960;
input long Butterfly_Bear=9639167;
input double Butterfly_Trans=70.0;
input string BatSettings="=====================";
input bool Bat=true;
input double Bat_dev=0.0;
input long Bat_Bull=65535;
input long Bat_Bear=17919;
input double Bat_Trans=70.0;
input string CrabSettings="=====================";
input bool Crab=true;
input double Crab_dev=0.0;
input long Crab_Bull=65280;
input long Crab_Bear=16711935;
input double Crab_Trans=70.0;
input string SharkSettings="=====================";
input bool Shark=false;
input double Shark_dev=0.0;
input long Shark_Bull=10156544;
input long Shark_Bear=8421616;
input double Shark_Trans=70.0;
input string CypherSettings="=====================";
input bool Cypher=false;
input double Cypher_dev=0.0;
input long Cypher_Bull=13959039;
input long Cypher_Bear=12180223;
input double Cypher_Trans=70.0;
input string ABCDSettings="=====================";
input bool ABCD=true;
input double ABCD_dev=0.0;
input long ABCD_Bull=9498256;
input long ABCD_Bear=12695295;
input double ABCD_Trans=70.0;
input string ZigZagWaveSettings="=====================";
input int Depth=12;
input int Deviation=5;
input int Backstep=3;
input string AlarmSettings="=====================";
input bool alert=true;
input bool push=true;
input bool mail=true;
input string ColorsSettings="=====================";
input bool showEntryExit=true;
input long BEntryColor=16776960;
input long SEntryColor=42495;
input long SLColor=255;
input long TP1Color=65280;
input long TP2Color=3329330;
input long TP3Color=32768;
input bool ShowSingalArrow=true;
input long BuySignalColor=16776960;
input long SellSignalColor=42495;
input int ArrowSize=2;

// Parámetros de la EMA
input int EMAPeriod = 200;
input int EMAShift=0;
input ENUM_TIMEFRAMES EMATimeFrame = PERIOD_H1;

// 
input double maxLoss = 0.02;

input double minLotSize = 0.1;

input ulong Magic = 1;

input double minRR = 1;

input bool buyOperations = true;

input bool sellOperations = true;

// Parámetros del Stochastic Oscillator
input int K = 5;
input int D = 3;
input int Slowing = 3;

// Nivel del Stochastic para validar la compra
input double StochasticLevel = 20;

// VARIABLES GLOBALES

double signalBuy[], signalSell[];
double tp1[], tp2[], tp3[], sl0[];

double currBuy, currSell;
double currSl, currTP1, currTP2, currTP3;

double lastBuy, lastSell;
double lastSl, lastTP1, lastTP2, lastTP3;
double lastPosType = 0;

int lastPatternBar = -1;

static datetime lastTradeTime = 0;

int previousPositions = 0; // Variable global para almacenar el número de posiciones abiertas

// EMA
int handleEMA = INVALID_HANDLE;

double EMABuffer[];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   obj_Trade.SetExpertMagicNumber(Magic);
   
    handle_BHP = iCustom(_Symbol,_Period,"Market//Basic Harmonic Pattern MT5", PatternSettings, MaxBars, Delay, ShowLogo, showOnlyLast, hidePrevNumbers, 
    GartleySettings, Gartley, Gartley_dev, Gartley_Bull, Gartley_Bear, Gartley_Trans, ButterflySettings, Butterfly, Butterfly_dev, Butterfly_Bull, 
    Butterfly_Bear, Butterfly_Trans, BatSettings, Bat, Bat_dev, Bat_Bull, Bat_Bear, Bat_Trans, CrabSettings, Crab, Crab_dev, Crab_Bull, Crab_Bear, 
    Crab_Trans, SharkSettings, Shark, Shark_dev, Shark_Bull, Shark_Bear, Shark_Trans, CypherSettings, Cypher, Cypher_dev, Cypher_Bull, Cypher_Bear, 
    Cypher_Trans, ABCDSettings, ABCD, ABCD_dev, ABCD_Bull, ABCD_Bear, ABCD_Trans, ZigZagWaveSettings, Depth, Deviation, Backstep, AlarmSettings, 
    alert, push, mail);
   
   //handle_BHP = iCustom(_Symbol,_Period,"Market//Basic Harmonic Pattern MT5");
   
   if (handle_BHP == INVALID_HANDLE){
      Print("UNABLE TO INITIALIZE THE IND CORRECTLY. REVERTING NOW.");
      return (INIT_FAILED);
   }
   
   ArraySetAsSeries(signalBuy,true);
   ArraySetAsSeries(signalSell,true);
   
   // Crear el handle del indicador Stochastic
   handleStochastic = iStochastic(_Symbol, _Period, K, D, Slowing, MODE_SMA, STO_CLOSECLOSE);
   
   if (handleStochastic == INVALID_HANDLE){
      Print("UNABLE TO INITIALIZE THE STOCHASTIC IND CORRECTLY. REVERTING NOW.");
      return (INIT_FAILED);
   }
   
   // Crear el handle del indicador EMA
   handleEMA = iMA(_Symbol, EMATimeFrame, EMAPeriod, EMAShift, MODE_EMA, STO_CLOSECLOSE);
   
   if (handleEMA == INVALID_HANDLE){
      Print("UNABLE TO INITIALIZE THE EMA IND CORRECTLY. REVERTING NOW.");
      return (INIT_FAILED);
   }
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   int currentPositions = PositionsTotal(); // Número actual de posiciones abiertas

   // Verificar si se ha cerrado una posición
   if (currentPositions < previousPositions) {
      Print("Una posición ha sido cerrada.");
      CheckClosedPositions(); // Función para manejar el evento de cierre
   }
   
   // Actualizar el estado previo
   previousPositions = currentPositions;

   if (currentPositions == 0) {
      const int currBars = iBars(_Symbol,_Period);
      static int prevBars = currBars;
      if (prevBars == currBars) return;
      prevBars = currBars;
      //Print(PositionsTotal());
      if (CopyBuffer(handle_BHP,0,1,1,signalBuy) < 1){ // buy buffer = 6
         Print("UNABLE TO GET ENOUGH REQUESTED DATA FOR BUY SIG'. REVERTING.");
         return;
      }
      if (CopyBuffer(handle_BHP,1,1,1,signalSell) < 1){ // sell buffer = 7
         Print("UNABLE TO GET ENOUGH REQUESTED DATA FOR SELL SIG'. REVERTING.");
         return;
      }
      
      if (CopyBuffer(handle_BHP,2,1,1,sl0) < 1){
         Print("UNABLE TO GET ENOUGH REQUESTED DATA FOR SL. REVERTING.");
         return;
      }
      
      if (CopyBuffer(handle_BHP,3,1,1,tp1) < 1){
         Print("UNABLE TO GET ENOUGH REQUESTED DATA FOR TP1. REVERTING.");
         return;
      }
      if (CopyBuffer(handle_BHP,4,1,1,tp2) < 1){
         Print("UNABLE TO GET ENOUGH REQUESTED DATA FOR TP2. REVERTING.");
         return;
      }
      if (CopyBuffer(handle_BHP,5,1,1,tp3) < 1){
         Print("UNABLE TO GET ENOUGH REQUESTED DATA FOR TP3. REVERTING.");
         return;
      }
      
      if (CopyBuffer(handleEMA,0,1,1,EMABuffer) < 1) {
            Print("UNABLE TO GET ENOUGH EMA BUFFER DATA'. REVERTING.");
            return;
         }
      const double EMAValue  = EMABuffer[0];
      
      //Print(signalBuy[0]," > ",signalSell[0]);
      //Print(DBL_MAX);
      //Print(EMPTY_VALUE);
      
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if (signalBuy[0] != EMPTY_VALUE && signalBuy[0] != currBuy && buyOperations && ask > EMAValue){
         currBuy = signalBuy[0];
         currSl = sl0[0]; currTP1 = tp1[0]; currTP2 = tp2[0]; currTP3 = tp3[0];
         
         if(!isRepintedPattern(lastBuy, currBuy, lastTradeTime, true, 7200)) {
         
            const bool oneToOneTP1 = (MathAbs(currBuy - currSl) * minRR) <= MathAbs(currBuy - currTP1);
            
            //const bool oneToOneTP2 = (MathAbs(currBuy - currSl) * minRR) <= MathAbs(currBuy - currTP2);
            
            if (oneToOneTP1) {
               double KValue[], DValue[];
               // CopyBuffer obtiene el buffer de nuestro indicador
               // buffer num indica el buffer que queremos, en este caso el de la posición 0 ya que solo tiene un buffer este indicador.
               // start pos indica a cuál candela queremos saber el valor de su indicador, la 0 es la útlima, la 1 es la de la izuqierda y así.
               // count cantidad de barras a la izquierda que vamos a analizar
               // double_array: direccion de memoria del array donde vamos a almacenar los valores, en este caso solo se almacena 1
               // Retorna el count o 0 en caso de error
               if (CopyBuffer(handleStochastic, /*buffer_num*/ 0, /*start_pos*/ 0, /*count*/ 1, /*double_array*/KValue) != 0) {
                  if (CopyBuffer(handleStochastic, /*buffer_num*/ 1, /*start_pos*/ 0, /*count*/ 1, /*double_array*/DValue) != 0) {
                     // Verificar condición del Stochastic
                     if (KValue[0] < StochasticLevel && DValue[0] < StochasticLevel)
                     {
                        // Ejecutar compra
                        const double lotSize = computeLotSize(maxLoss, currBuy, currSl, minLotSize);
                        
                        Print("BUY = ",signalBuy[0], " Relacion 1:1 con TP1");
                        Print("SL = ",sl0[0],", TP1 = ",tp1[0],", TP2 = ",tp2[0],", TP3 = ",tp3[0], ", LotSize = ", lotSize);
                        
                        if (!obj_Trade.Buy(lotSize, _Symbol, currBuy, currSl)) {
                            Print("Error al abrir operación de compra: ", GetLastError());
                        } else {
                           lastTP1 = currTP1; lastTP2 = currTP2; lastTP3 = currTP3;
                           lastBuy = currBuy;
                           lastPosType = POSITION_TYPE_BUY;
                        }
                      }
                  }
               } else {
                  Print("It wasnt possible coppy the buffer for Stochastic indicator");
               }
            }
            //} else if (oneToOneTP2) {
//               const double lotSize = computeLotSize(maxLoss, currBuy, currSl, minLotSize);
//               
//               Print("BUY = ",signalBuy[0], " Relacion 1:1 con TP2");
//               Print("SL = ",sl0[0],", TP1 = ",tp1[0],", TP2 = ",tp2[0],", TP3 = ",tp3[0], ", LotSize = ", lotSize);
//               
//               if (!obj_Trade.Buy(lotSize, _Symbol, currBuy, currSl)) {
//                   Print("Error al abrir operación de compra: ", GetLastError());
//               } else {
//                  lastTP1 = currTP2; lastTP2 = currTP3; lastTP3 = currTP3;
//                  lastBuy = currBuy;
//                  lastPosType = POSITION_TYPE_BUY;
//               }
//            }
         } else {
            Print("Operación reciente detectada y Cambio insignificante en el patrón. Ignorando nueva señal.");
         }
      }
   } else {
      ApplyDynamicTrailingStop(lastTP1, lastTP2, lastTP3);
   }
}

double computeLotSize(double maxPctLoss, double entryPrice, double stopLoss, double minVolumeSize) {
   const double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   const double lotSize = MathMax(minVolumeSize, NormalizeDouble((maxPctLoss * accountBalance) / (MathAbs(entryPrice - stopLoss) / _Point), 2));
   //const double lotSize = MathMax(minVolumeSize, NormalizeDouble(20.0 / (MathAbs(entryPrice - stopLoss) / _Point), 2));
   return lotSize;
   
   //if (lotSize > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX) || lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
   // Print("Tamaño de lote fuera de los límites permitidos.");
   // return 0;
}

bool isRepintedPattern(double lastEntryPrice, double newEntryPrice, double lastTradeDatetime, bool isBuy /*1 para compra*/, int secondsDelay) {
   if (lastPosType == (isBuy? POSITION_TYPE_BUY: POSITION_TYPE_SELL)) {
      if (MathAbs(lastEntryPrice - newEntryPrice) < _Point * 20) {
         return (TimeCurrent() - lastTradeDatetime) < secondsDelay;
      }
      
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if (MathAbs(ask - newEntryPrice) >= _Point * 3) {
         return true;
      }
   }
   return false;
}

// Función para manejar las posiciones cerradas
void CheckClosedPositions() {
   // Actualizar hora en que se cerró la última operación
   lastTradeTime = TimeCurrent();
}

/* Break-even: Cuando el precio alcance el TP1, el SL se ajusta al precio de entrada.
Ajuste al TP1: Cuando el precio alcance el TP2, el SL se mueve al nivel de TP1.
Cierre en TP3: Cuando el precio alcance el TP3, se cierra la operación.
*/
// Función para aplicar el trailing stop dinámico
void ApplyDynamicTrailingStop(double currentTP1, double currentTP2, double currentTP3)
{
   //Print(", TP1 = ",currentTP1,", TP2 = ",currentTP2,", TP3 = ",currentTP3);
   // Obtener el número total de posiciones abiertas
   const int total_positions = PositionsTotal();
   //Print(total_positions);

   // Recorrer todas las posiciones abiertas
   for (int i = 0; i < total_positions; i++)
   {
      const ulong ticket = PositionGetTicket(i); // Obtener el ticket de la posición
      if (ticket == 0) continue;

      // Seleccionar la posición actual
      if (PositionSelectByTicket(ticket))
      {
         // Verificar que la posición pertenezca al EA usando el Magic Number
         if (PositionGetInteger(POSITION_MAGIC) != Magic) continue;

         // Obtener los datos de la posición
         const string symbol = PositionGetString(POSITION_SYMBOL);          // Símbolo
         const double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);   // Precio de entrada
         const double stopLoss = PositionGetDouble(POSITION_SL);            // Stop Loss actual
         const double takeProfit = PositionGetDouble(POSITION_TP);          // Take Profit actual
         const double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);  // Precio actual para BUY

         // Identificar el tipo de operación (BUY o SELL)
         const long positionType = PositionGetInteger(POSITION_TYPE);

         // Lógica para operaciones de compra (BUY)
         if (positionType == POSITION_TYPE_BUY)
         {
            // 1. Mover SL al precio de entrada (Break-even) si alcanza TP1
            if (currentPrice >= ((currentPrice + currentTP1) / 2) && stopLoss < openPrice)
            {
               //if (!obj_Trade.PositionClose(ticket))
               //   Print("Error al cerrar posición en TP1 para BUY: ", GetLastError());
               //Print("Moviendo a breakeven");
               if (!obj_Trade.PositionModify(ticket, openPrice, takeProfit))
                  Print("Error al mover SL a Break-even para BUY: ", GetLastError());
            }
            // 2. Mover SL a TP1 si alcanza TP2
            else if (currentPrice >= currentTP1 && stopLoss < currentTP1)
            {
               //Print("Moviendo SL a TP1");
               //if (!obj_Trade.PositionModify(ticket, currentTP1, takeProfit))
               //   Print("Error al mover SL a TP1 para BUY: ", GetLastError());
                  Print("Cerrando posicion");
               if (!obj_Trade.PositionClose(ticket))
                  Print("Error al cerrar posición en TP3 para BUY: ", GetLastError());
            }
            // 2. Mover SL a TP1 si alcanza TP2
            else if (currentPrice >= currentTP2 && stopLoss < currentTP1)
            {
               //Print("Moviendo SL a TP1");
               //if (!obj_Trade.PositionModify(ticket, currentTP1, takeProfit))
               //   Print("Error al mover SL a TP1 para BUY: ", GetLastError());
                  Print("Cerrando posicion");
               if (!obj_Trade.PositionClose(ticket))
                  Print("Error al cerrar posición en TP3 para BUY: ", GetLastError());
            }
            // 3. Cerrar la posición si alcanza TP3
            else if (currentPrice >= currentTP3)
            {
               Print("Cerrando posicion");
               if (!obj_Trade.PositionClose(ticket))
                  Print("Error al cerrar posición en TP3 para BUY: ", GetLastError());
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
