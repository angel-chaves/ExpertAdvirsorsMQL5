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


// 
input double maxLoss = 0.02;

input double minLotSize = 0.1;

input ulong Magic = 1;

input double minRR = 1;

input bool buyOperations = true;

input bool sellOperations = true;


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
void OnTick(){

   int currentPositions = PositionsTotal(); // Número actual de posiciones abiertas

   // Verificar si se ha cerrado una posición
   if (currentPositions < previousPositions) {
      Print("Una posición ha sido cerrada.");
      CheckClosedPositions(); // Función para manejar el evento de cierre
   }
   
   // Actualizar el estado previo
   previousPositions = currentPositions;

   if (currentPositions == 0) {
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
      
      int currBars = iBars(_Symbol,_Period);
      static int prevBars = currBars;
      if (prevBars == currBars) return;
      prevBars = currBars;
      
      
      //Print(signalBuy[0]," > ",signalSell[0]);
      //Print(DBL_MAX);
      //Print(EMPTY_VALUE);
      
      if (signalBuy[0] != EMPTY_VALUE && signalBuy[0] != currBuy && buyOperations){
         currBuy = signalBuy[0];
         currSl = sl0[0]; currTP1 = tp1[0]; currTP2 = tp2[0]; currTP3 = tp3[0];
         
         bool samePattern = false;
         
         if (lastPosType == POSITION_TYPE_SELL) {
            if (MathAbs(lastBuy - currBuy) < _Point * 20) {
               if (TimeCurrent() - lastTradeTime < 7200) { // Delay de una hora
                  Print("Operación reciente detectada y Cambio insignificante en el patrón. Ignorando nueva señal.");
                  samePattern = true;
               }
            }
         }
         
         if((MathAbs(currBuy - currSl) * minRR) <= MathAbs(currBuy - currTP1) && !samePattern) {
         
            const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            
            // Precio de venta actual
            const double sellSl = currBuy + ((currBuy - currSl) / 2);
            
            double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            double lotSize = NormalizeDouble((maxLoss * accountBalance) / (MathAbs(currBuy - sellSl) / _Point), 2);
            
            Print("BUY = ",signalBuy[0], ", Bid = ", bid);
            Print("SL = ",sl0[0],", TP1 = ",tp1[0],", TP2 = ",tp2[0],", TP3 = ",tp3[0], ", LotSize = ", lotSize);
            
            lotSize = MathMax(lotSize, minLotSize);
            
            if (!obj_Trade.Sell(lotSize, _Symbol, currBuy, sellSl, currSl)) {
                Print("Error al abrir operación de compra: ", GetLastError());
            } else {
               lastTP1 = currSl; lastTP2 = currTP2; lastTP3 = currTP3;
               lastBuy = currBuy;
               lastPosType = POSITION_TYPE_SELL;
            }
         }
      }  
      
      else if (signalSell[0] != EMPTY_VALUE && signalSell[0] != currSell && sellOperations){
         currSell = signalSell[0];
         currSl = sl0[0]; currTP1 = tp1[0]; currTP2 = tp2[0]; currTP3 = tp3[0];
         
         // Verificar si es el patrón repintado
         bool samePattern = false;
         
         // Primero si es el mismo tipo de posición
         if (lastPosType == POSITION_TYPE_SELL) {
            // Luego chequeamos si hay un cambio poco signficativo en el punto de entrada.
            if (MathAbs(lastSell - currSell) < _Point * 20) {
               // Luego si la última entrada se cerró hace menos de 2 horas.
               if (TimeCurrent() - lastTradeTime < 7200) { // Delay de 2 horas
                  Print("Operación reciente detectada y Cambio insignificante en el patrón. Ignorando nueva señal.");
                  samePattern = true;
               }
            }
         }
         
  
         if((MathAbs(currSell - currSl) * minRR) <= MathAbs(currSell - currTP1) && !samePattern) {

            // Precio de compra actual
            const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            const double sell_sl = ask + maxLoss;
            
            double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            double lotSize = NormalizeDouble((maxLoss * accountBalance) / (MathAbs(currSl - currSell) / _Point), 2);
            
            Print("SELL = ",signalSell[0], " ASK = ", ask);
            Print("SL = ",sl0[0],", TP1 = ",tp1[0],", TP2 = ",tp2[0],", TP3 = ",tp3[0], ", LotSize = ", lotSize);
            
            lotSize = MathMax(lotSize, minLotSize);
            
            if (!obj_Trade.Sell(lotSize, _Symbol, currSell, currSl)) {
                Print("Error al abrir operación de compra: ", GetLastError());
            } else {
               lastTP1 = currSl; lastTP2 = currTP2; lastTP3 = currTP3;
               lastSell = currSell;
               lastPosType = POSITION_TYPE_SELL;
            }
         }
      }
   } else {
      //ApplyDynamicTrailingStop(lastTP1, lastTP2, lastTP3);
   }
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
   int total_positions = PositionsTotal();
   //Print(total_positions);

   // Recorrer todas las posiciones abiertas
   for (int i = 0; i < total_positions; i++)
   {
      ulong ticket = PositionGetTicket(i); // Obtener el ticket de la posición
      if (ticket == 0) continue;

      // Seleccionar la posición actual
      if (PositionSelectByTicket(ticket))
      {
         // Verificar que la posición pertenezca al EA usando el Magic Number
         if (PositionGetInteger(POSITION_MAGIC) != Magic) continue;

         // Obtener los datos de la posición
         string symbol = PositionGetString(POSITION_SYMBOL);          // Símbolo
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);   // Precio de entrada
         double stopLoss = PositionGetDouble(POSITION_SL);            // Stop Loss actual
         double takeProfit = PositionGetDouble(POSITION_TP);          // Take Profit actual
         double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);  // Precio actual para BUY

         // Identificar el tipo de operación (BUY o SELL)
         long positionType = PositionGetInteger(POSITION_TYPE);

         // Lógica para operaciones de compra (BUY)
         if (positionType == POSITION_TYPE_BUY)
         {
            // 1. Mover SL al precio de entrada (Break-even) si alcanza TP1
            if (currentPrice >= currentTP1 && stopLoss < openPrice)
            {
               if (!obj_Trade.PositionClose(ticket))
                  Print("Error al cerrar posición en TP1 para BUY: ", GetLastError());
               //Print("Moviendo a breakeven");
               //if (!obj_Trade.PositionModify(ticket, openPrice, takeProfit))
               //   Print("Error al mover SL a Break-even para BUY: ", GetLastError());
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
         // Lógica para operaciones de venta (SELL)
         else if (positionType == POSITION_TYPE_SELL)
         {
            currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK); // Precio actual para SELL

            // 1. Mover SL al precio de entrada (Break-even) si alcanza TP1
            if (currentPrice <= currentTP1 && stopLoss > openPrice)
            {
               Print("Cerrando posicion");
               if (!obj_Trade.PositionClose(ticket))
                  Print("Error al cerrar posición en TP3 para BUY: ", GetLastError());
               //Print("Moviendo a breakeven");
               //if (!obj_Trade.PositionModify(ticket, openPrice, takeProfit))
               //   Print("Error al mover SL a Break-even para SELL: ", GetLastError());
            }
            // 2. Mover SL a TP1 si alcanza TP2
            else if (currentPrice <= currentTP2 && stopLoss > currentTP1)
            {
               //Print("Moviendo SL a TP2");
               //if (!obj_Trade.PositionModify(ticket, currentTP1, takeProfit))
               //   Print("Error al mover SL a TP1 para SELL: ", GetLastError());
               Print("Cerrando posicion");
               if (!obj_Trade.PositionClose(ticket))
                  Print("Error al cerrar posición en TP3 para BUY: ", GetLastError());
            }
            // 3. Cerrar la posición si alcanza TP3
            else if (currentPrice <= currentTP3)
            {
               Print("Cerrando posicion");
               if (!obj_Trade.PositionClose(ticket))
                  Print("Error al cerrar posición en TP3 para SELL: ", GetLastError());
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
