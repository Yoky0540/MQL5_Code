//+------------------------------------------------------------------+
//|                                                   SuperOrder.mq5 |
//|                                                        Yok'Naron |
//+------------------------------------------------------------------+
#property copyright "Yok'Naron"
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

CTrade trade;

input double lotSize = 0.01; // Insert your default lot size
input int getPoint = 100;    // Insert your default point that need to get/loss

string positionType = "buy"; // Current position direction

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if (PositionsTotal() == 0)
     {
      string lastResult = GetLastProfit(); // Get last closed trade result
      OpenPositionTrade();                // Open a new position
      Comment("Last Trade Result:\n", lastResult, "\nCurrent Position Type: ", positionType);
     }
  }

//+------------------------------------------------------------------+
//| Opens a new trade                                                |
//+------------------------------------------------------------------+
void OpenPositionTrade()
  {
   if (positionType == "buy")
     {
      double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      trade.Buy(lotSize, _Symbol, ask, ask - getPoint * _Point, ask + getPoint * _Point);
     }
   else
     {
      double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      trade.Sell(lotSize, _Symbol, bid, bid + getPoint * _Point, bid - getPoint * _Point);
     }
  }

//+------------------------------------------------------------------+
//| Get last closed trade profit and details                        |
//+------------------------------------------------------------------+
string GetLastProfit()
  {
   if (!HistorySelect(0, TimeCurrent())) // Ensure history is available
     {
      Print("Error: Unable to select deal history.");
      return "No history found";
     }

   int totalDeals = HistoryDealsTotal();
   if (totalDeals == 0)
     {
      return "No closed trades found";
     }

   // Retrieve the most recent deal
   ulong lastTicket = HistoryDealGetTicket(totalDeals - 1);
   if (lastTicket <= 0)
     {
      Print("Error: Unable to retrieve last deal ticket.");
      return "Error retrieving last deal";
     }

   double profit = HistoryDealGetDouble(lastTicket, DEAL_PROFIT);
   ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(lastTicket, DEAL_ENTRY);
   ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(lastTicket, DEAL_TYPE);

   string result = "Profit: " + DoubleToString(profit, 2) + "\n";
   result += "Ticket: " + IntegerToString(lastTicket) + "\n";

   if (dealEntry == DEAL_ENTRY_OUT) // Only check closed deals
     {
      if (profit < 0) // Loss occurred
        {
         result += "Loss detected. Switching direction.\n";
         positionType = (positionType == "buy") ? "sell" : "buy"; // Switch direction
        }
      else
        {
         result += "Profit detected. Keeping current direction.\n";
        }

      result += (dealType == DEAL_TYPE_BUY ? "Last trade was a Buy.\n" : "Last trade was a Sell.\n");
     }
   else
     {
      result += "Deal not closed (Entry Type: " + IntegerToString(dealEntry) + ")\n";
     }

   return result;
  }
