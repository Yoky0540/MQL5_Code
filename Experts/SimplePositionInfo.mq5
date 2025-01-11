//+------------------------------------------------------------------+
//|                                           SimplePositionInfo.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include path                                                     |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//Create instance for CTrade
CTrade trade;

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
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   // if positions for this currency pair exist
   if(PositionSelect(_Symbol) == true){
      
      //count down the number of position until 0 with for loop
      for(int i = PositionsTotal()-1; i>=0; i--){
         
         // calculate the ticket number
         ulong PositionTicket = PositionGetTicket(i);
         
         //calculate the currency pair
         string PositionSymbol = PositionGetString(POSITION_SYMBOL);
         
         //calculate the open price for the position
         double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         
         //calculate the current price for the position
         double PositionPriceCurrent = PositionGetDouble(POSITION_PRICE_CURRENT);
         
         //calculate the profit for the position
         double PositionProfit = PositionGetDouble(POSITION_PROFIT);
         
         //calculate the swap price for the position
         int PositionSwap = (int)PositionGetDouble(POSITION_SWAP);
         
         //calculate profit net for the position
         double PositionNetProfit = PositionProfit + PositionSwap;
         
         if(PositionSymbol == _Symbol){
            Comment(
               "Position Number: ",i,"\n",
               "Position Ticket: ",PositionTicket,"\n",
               "Position Symbol: ",PositionSymbol,"\n",
               "Position Profit: ",PositionProfit,"\n",
               "Position Swap: ",PositionSwap,"\n",
               "Position net Profit: ",PositionNetProfit,"\n",
               "Position Price Open: ",PositionPriceOpen,"\n",
               "Position Price Current: ",PositionPriceCurrent,"\n"
            );
         }
      }
   }
   
   // if no order, let open test position
   if(PositionsTotal() == 0){
      OpenTestPosition();
   }
   
  }

void OpenTestPosition(){
   
   //calculate the ask price
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   
   //buy 1 micro lot
   trade.Buy(0.01,_Symbol,Ask,(Ask-100*_Point),(Ask+100*_Point),NULL);
}
//+------------------------------------------------------------------+
