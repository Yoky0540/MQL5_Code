//+------------------------------------------------------------------+
//|                                               Simple_RSI_BOT.mq5 |
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
//| Input Path                                                       |
//+------------------------------------------------------------------+
static input long InpMagicNumber = 546812; // Magic Number For RSI_Bot
static input double InpLotSize = 0.01;     // Lot Size
input int InpRSIPeriod = 21;               // RSI Period
input int InpRSILevel = 70;                // RSI Level (Upper)
input int InpStopLoss = 200;               // Stop loss in points (0 = off)
input int InpTakeProfit = 100;             // Take profit in points (0 = off)
input bool InpCloseSignal = false;         // Close trades by opposite signal

//+------------------------------------------------------------------+
//| Global variables Path                                            |
//+------------------------------------------------------------------+
int rsiHandle;
double rsiBuffer[];
MqlTick currentTick;
CTrade trades;
datetime openTimeBuy = 0, openTimeSell = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  Alert("RSI EA Bot");
  // Check user input
  bool isInValidInputs = CheckValidInputs();
  if (isInValidInputs)
    return INIT_PARAMETERS_INCORRECT;

  // Set magic number
  trades.SetExpertMagicNumber(InpMagicNumber);

  // create rsi handle
  rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
  if (rsiHandle == INVALID_HANDLE)
  {
    Alert("Error creating RSI handle");
    return INIT_FAILED;
  }

  // set buffer as series
  ArraySetAsSeries(rsiBuffer, true);

  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Release rsi handle
  if (rsiHandle != INVALID_HANDLE)
    IndicatorRelease(rsiHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  // get current tick
  if (!SymbolInfoTick(_Symbol, currentTick))
  {
    Print("Error getting current tick");
    return;
  }

  // get rsi values
  int rsiValues = CopyBuffer(rsiHandle, 0, 0, 2, rsiBuffer);
  if (rsiValues != 2)
  {
    Print("Error getting RSI values");
    return;
  }

  Comment("RSI: ", rsiBuffer[0], "\n", "buffer[1]: ", rsiBuffer[1]);

  // count open positions
  int cntBuy, cntSell;
  if (!CheckOpenPositions(cntBuy, cntSell))
  {
    return;
  }

  // check for buy position
  bool isRsiBuySignal = rsiBuffer[1] >= (100 - InpRSILevel) && rsiBuffer[0] < (100 - InpRSILevel);
  bool isOpenTimeBuyCorrect = openTimeBuy != iTime(_Symbol, PERIOD_CURRENT, 0);
  if (cntBuy == 0 && isRsiBuySignal && isOpenTimeBuyCorrect)
  {
    openTimeBuy = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (InpCloseSignal)
    {
      bool completeClose = CheckClosePositions(2);
      if (!completeClose)
        return;
    }
    double sl = InpStopLoss == 0 ? 0 : currentTick.bid - InpStopLoss * _Point;
    double tp = InpTakeProfit == 0 ? 0 : currentTick.bid + InpTakeProfit * _Point;

    if (!CheckNormalizePrice(sl))
      return;
    if (!CheckNormalizePrice(tp))
      return;

    trades.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentTick.ask, sl, tp, "RSI EA Buy");
  }

  // check for sell position
  bool isRsiSellSignal = rsiBuffer[1] <= InpRSILevel && rsiBuffer[0] > InpRSILevel;
  bool isOpenTimeSellCorrect = openTimeSell != iTime(_Symbol, PERIOD_CURRENT, 0);
  if (cntSell == 0 && isRsiSellSignal && isOpenTimeSellCorrect)
  {
    openTimeSell = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (InpCloseSignal)
    {
      bool completeClose = CheckClosePositions(1);
      if (!completeClose)
        return;

    }
      double sl = InpStopLoss == 0 ? 0 : currentTick.ask + InpStopLoss * _Point;
      double tp = InpTakeProfit == 0 ? 0 : currentTick.ask - InpTakeProfit * _Point;

      if (!CheckNormalizePrice(sl))
        return;
      if (!CheckNormalizePrice(tp))
        return;

      trades.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, currentTick.bid, sl, tp, "RSI EA Sell");
  }
}

//+------------------------------------------------------------------+
//| Customize function                                               |
//+------------------------------------------------------------------+
bool CheckValidInputs()
{
  if (InpMagicNumber <= 0)
  {
    Alert("Magic number must be more than 0");
    return true;
  }

  if (InpLotSize <= 0 || InpLotSize > 10)
  {
    Alert("Your lot size must be between 0.01 and 10");
    return true;
  }
  if (InpRSIPeriod <= 1)
  {
    Alert("Your RSI period must be more than 1");
    return true;
  }
  if (InpRSILevel >= 100 || InpRSILevel <= 0)
  {
    Alert("Your RSI level must be between 0 and 100");
    return true;
  }
  if (InpStopLoss < 0)
  {
    Alert("Your stop loss must be more than 0");
    return true;
  }
  if (InpTakeProfit < 0)
  {
    Alert("Your take profit must be more than 0");
    return true;
  }

  return false;
}

bool CheckOpenPositions(int &cntBuy, int &cntSell)
{
  cntBuy = 0;
  cntSell = 0;
  int total = PositionsTotal();

  for (int i = total - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);

    if (ticket <= 0)
    {
      Print("Error getting ticket number");
      return false;
    }

    if (!PositionSelectByTicket(ticket))
    {
      Print("Error selecting position");
      return false;
    }

    long magic;
    if (!PositionGetInteger(POSITION_MAGIC, magic))
    {
      Print("Error getting magic number");
      return false;
    }

    if (magic == InpMagicNumber)
    {
      long type;
      if (!PositionGetInteger(POSITION_TYPE, type))
      {
        Print("Error getting position type");
        return false;
      }

      if (type == POSITION_TYPE_BUY)
      {
        cntBuy++;
      }

      if (type == POSITION_TYPE_SELL)
      {
        cntSell++;
      }
    }
  }
  return true;
}

bool CheckNormalizePrice(double &price)
{
  double ticketSize = 0;
  if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, ticketSize))
  {
    Print("Error getting symbol info");
    return false;
  }
  price = NormalizeDouble(MathRound(price / ticketSize) * ticketSize, _Digits);
  return true;
}

bool CheckClosePositions(int all_buy_sell)
{
  int total = PositionsTotal();
  for (int i = total - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (ticket <= 0)
    {
      Print("Error getting ticket number");
      return false;
    }
    if (!PositionSelectByTicket(ticket))
    {
      Print("Error selecting position");
      return false;
    }
    long magic;
    if (!PositionGetInteger(POSITION_MAGIC, magic))
    {
      Print("Error getting magic number");
      return false;
    }
    if (magic == InpMagicNumber)
    {
      long type;
      if (!PositionGetInteger(POSITION_TYPE, type))
      {
        Print("Error getting position type");
        return false;
      }

      if (all_buy_sell == 1 && type == POSITION_TYPE_SELL)
      {
        continue;
      }
      if (all_buy_sell == 2 && type == POSITION_TYPE_BUY)
      {
        continue;
      }

      trades.PositionClose(ticket);

      if (trades.ResultRetcode() != TRADE_RETCODE_DONE)
      {
        Print("Error closing position the ticket number:", (string)ticket, " Result:", (string)trades.CheckResultRetcodeDescription());
        return false;
      }
    }
  }
  return true;
}
//+------------------------------------------------------------------+
