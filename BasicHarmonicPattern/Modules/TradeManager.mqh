//+------------------------------------------------------------------+
//|                       TradeManager.mqh                           |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

class TradeManager {
private:
    CTrade trade;
    ulong magicNumber;

public:
    void Initialize(CTrade &tradeObject, ulong magic) {
        trade = tradeObject;
        magicNumber = magic;
    }

    bool ExecuteBuy(double price, double stopLoss, double takeProfit, double lotSize) {
        if (!trade.Buy(lotSize, _Symbol, price, stopLoss, takeProfit)) {
            Print("Error executing Buy order: ", GetLastError());
            return false;
        }
        Print("Buy order executed: Lot Size=", lotSize, ", Price=", price);
        return true;
    }

    bool ExecuteSell(double price, double stopLoss, double takeProfit, double lotSize) {
        if (!trade.Sell(lotSize, _Symbol, price, stopLoss, takeProfit)) {
            Print("Error executing Sell order: ", GetLastError());
            return false;
        }
        Print("Sell order executed: Lot Size=", lotSize, ", Price=", price);
        return true;
    }
};

