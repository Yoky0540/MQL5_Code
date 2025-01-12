//+------------------------------------------------------------------+
//|                                                    FiboTrade.mq5 |
//|                                                        Yok'Naron |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yok'Naron"
#property link "https://www.mql5.com"
#property version "1.00"
//+------------------------------------------------------------------+
//| Include Path                                                     |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
//+------------------------------------------------------------------+
//| Input path                                                       |
//+------------------------------------------------------------------+
input double InpLotSize = 0.01;    // Lot Size
input double InpStopLoss = 0.00;   // Stop loss in points (0 = off)
input double InpTakeProfit = 0.00; // Take profit in points (0 = off)

input double InpFiboRetracementLevel = 61.8; // Fibo Retracement
input int expirationHour = 9;                // Expiration hour

int barsTotal;
//+------------------------------------------------------------------+
//| Global Variables Path                                            |
//+------------------------------------------------------------------+
CTrade trade;
#define FIBO_OBJ "Fibo Retracement"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //---

  //---
  return (INIT_SUCCEEDED);
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
  int bars = iBars(_Symbol, PERIOD_D1);
  if (barsTotal != bars)
  {
    barsTotal = bars;

    ObjectDelete(0, FIBO_OBJ);

    double high = iHigh(_Symbol, PERIOD_D1, 1);
    double low = iLow(_Symbol, PERIOD_D1, 1);

    double close = iClose(_Symbol, PERIOD_D1, 1);
    double open = iOpen(_Symbol, PERIOD_D1, 1);

    datetime timeStart = iTime(_Symbol, PERIOD_D1, 1);
    datetime timeEnd = iTime(_Symbol, PERIOD_D1, 0) - 1;

    datetime expiration = iTime(_Symbol, PERIOD_D1, 0) + expirationHour * PeriodSeconds(PERIOD_H1);

    double entryLevel;
    if (close > open)
    {
      ObjectCreate(0, FIBO_OBJ, OBJ_FIBO, 0, timeStart, low, timeEnd, high);
      entryLevel = high - (high - low) * InpFiboRetracementLevel / 100;

      double entry = NormalizeDouble(entryLevel, _Digits);
      double tp = NormalizeDouble(entry + InpTakeProfit * _Point, _Digits);
      double sl = NormalizeDouble(entry - InpStopLoss * _Point, _Digits);

      trade.BuyLimit(InpLotSize, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration, "Fibo Trade Buy");
    }
    else
    {
      ObjectCreate(0, FIBO_OBJ, OBJ_FIBO, 0, timeStart, high, timeEnd, low);
      entryLevel = low + (high - low) * InpFiboRetracementLevel / 100;

      double entry = NormalizeDouble(entryLevel, _Digits);
      double tp = NormalizeDouble(entry - InpTakeProfit * _Point, _Digits);
      double sl = NormalizeDouble(entry + InpStopLoss * _Point, _Digits);

      trade.SellLimit(InpLotSize, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration, "Fibo Trade Sell");
    }

    // ObjectSetDouble(0, FIBO_OBJ, OBJPROP_LEVELVALUE, 1, 3.618);
    // Print("3.618 : ", ObjectGetDouble(0, FIBO_OBJ, OBJPROP_PRICE,0));

    ObjectSetInteger(0, FIBO_OBJ, OBJPROP_COLOR, clrRed);

    for (int i = 0; i < ObjectGetInteger(0, FIBO_OBJ, OBJPROP_LEVELS); i++)
    {
      ObjectSetInteger(0, FIBO_OBJ, OBJPROP_LEVELCOLOR, i, clrRed);
    }
  }
}

//+------------------------------------------------------------------+
