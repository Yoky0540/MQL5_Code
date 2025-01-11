//+------------------------------------------------------------------+
//|                                         Simple_Stochastic_EA.mq5 |
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
input group "=== General ===";
static input ulong InpMagicNumber = 546814; // Magic Number For Simple_Stochastic
static input double InpLotSize = 0.01;      // Lot Size

input group "=== Trading ===";
input int InpStopLoss = 200;       // Stop loss in points (0 = off)
input int InpTakeProfit = 0;       // Take profit in points (0 = off)
input bool InpCloseSignal = false; // Close trades by opposite signal

input group "=== Stochastic ===";
input int InpKPeriod = 9;    // %K Period
input int InpDPeriod = 3;    // %D Period
input int InpSlowing = 3;    // Slowing
input int InpStocLevel = 80; // Stochastic Level (Upper)

//+------------------------------------------------------------------+
//| Global Variables Path                                            |
//+------------------------------------------------------------------+
int stochasticHandle;
double stochasticBufferMain[], stochasticBufferSignal[];
MqlTick currentTick;
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  // Check user input
  bool isInValidInputs = CheckInvalidInputs();
  if (isInValidInputs)
    return INIT_PARAMETERS_INCORRECT;

  // Set magic number
  trade.SetExpertMagicNumber(InpMagicNumber);

  // create stochastic handle
  stochasticHandle = iStochastic(_Symbol, PERIOD_CURRENT, InpKPeriod, InpDPeriod, InpSlowing, MODE_SMA, STO_LOWHIGH);

  if (stochasticHandle == INVALID_HANDLE)
  {
    Alert("Error creating Stochastic handle");
    return INIT_FAILED;
  }

  ArraySetAsSeries(stochasticBufferMain, true);

  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  if (stochasticHandle != INVALID_HANDLE)
    IndicatorRelease(stochasticHandle);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  //---Check for bar open tick
  bool isNewBar = CheckNewBar();
  if (!isNewBar)
    return;

  // Check curent tick is a new bar open tick
  if (!SymbolInfoTick(_Symbol, currentTick))
  {
    Print("Error getting current tick");
    return;
  }

  // get stochastic values
  int stochasticValues = CopyBuffer(stochasticHandle, 0, 1, 2, stochasticBufferMain);
  if (stochasticValues != 2)
  {
    Print("Error getting Stochastic values");
    return;
  }

  // count open positions
  int cntBuy, cntSell;
  if (!CheckOpenPositions(cntBuy, cntSell))
  {
    Alert("Error checking open positions");
    return;
  }

  // check for buy position
  bool isStochasticBuySignal = stochasticBufferMain[0] <= (100 - InpStocLevel) &&
                               stochasticBufferMain[1] > (100 - InpStocLevel);
  if (cntBuy == 0 && isStochasticBuySignal)
  {
    Print("Buy Signal");
    if (InpCloseSignal)
    {
      bool completeClose = CheckClosePositions(2);
      if (!completeClose)
      {
        return;
      }
    }

    double sl = InpStopLoss == 0 ? 0 : currentTick.bid - InpStopLoss * _Point;
    double tp = InpTakeProfit == 0 ? 0 : currentTick.bid + InpTakeProfit * _Point;

    if (!CheckNormalizePrice(sl))
      return;
    if (!CheckNormalizePrice(tp))
      return;

    trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentTick.ask, sl, tp, "Stochastic EA Buy");
  }

  // check for sell position
  bool isStochasticSellSignal = stochasticBufferMain[0] >= InpStocLevel &&
                                stochasticBufferMain[1] < InpStocLevel;
  if (cntSell == 0 && isStochasticSellSignal)
  {
    Print("Sell Signal");
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

    trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, currentTick.bid, sl, tp, "Stochastic EA Sell");
  }
}

//+------------------------------------------------------------------+
//| Customize function                                               |
//+------------------------------------------------------------------+
bool CheckInvalidInputs()
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
  if (InpKPeriod <= 0)
  {
    Alert("%K Period must be more than 0");
    return true;
  }
  if (InpDPeriod <= 0)
  {
    Alert("%D Period must be more than 0");
    return true;
  }
  if (InpSlowing <= 0)
  {
    Alert("Slowing must be more than 0");
    return true;
  }
  if (InpStocLevel <= 50 || InpStocLevel >= 100)
  {
    Alert("Stochastic Level must be between 50 and 100");
    return true;
  }
  if (InpStopLoss < 0)
  {
    Alert("Stop Loss must be more than 0");
    return true;
  }
  if (InpTakeProfit < 0)
  {
    Alert("Take Profit must be more than 0");
    return true;
  }

  if (!InpCloseSignal && InpStopLoss == 0)
  {
    Alert("Stop Loss must be more than 0 if Close Signal is false");
    return true;
  }
  return false;
}

bool CheckNewBar()
{
  static datetime previousTime = 0;
  datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
  if (previousTime != currentTime)
  {
    previousTime = currentTime;
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

      trade.PositionClose(ticket);

      if (trade.ResultRetcode() != TRADE_RETCODE_DONE)
      {
        Print("Error closing position the ticket number:", (string)ticket, " Result:", (string)trade.CheckResultRetcodeDescription());
        return false;
      }
    }
  }
  return true;
}
//+------------------------------------------------------------------+
