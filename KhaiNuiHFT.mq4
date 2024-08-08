//+------------------------------------------------------------------+
//|                                                   KhaiNuiHFT.mq4 |
//|                              Copyright 2024, The Market Survivor |
//|                       https://www.facebook.com/TheMarketSurvivor |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, The Market Survivor"
#property link      "https://www.facebook.com/TheMarketSurvivor"
#property version   "1.00"
#property strict

string EA_NAME = "KhaiNuiHFT";
string Owner = "The Market Survivor";
string OwnerLink = "https://www.facebook.com/TheMarketSurvivor";
string eaInfo = EA_NAME + "\n" + Owner + "\n" + OwnerLink;

// Variables for Buy orders
input string BuySetting = "----- Buy Orders Settings -----"; // Buy Orders Settings
input bool    EnableBuy            = true;   // Enable Buy Orders
input double  BuyLotSize           = 1;    // Lot Size for Buy Orders
input int     BuySL_Distance       = 50;     // Stop Loss Distance for Buy Orders (points)
input int     BuyTrailing_Distance = 50;     // Trailing Stop Distance for Buy Orders (points)

// Variables for Sell orders
input string SellSetting = "----- Sell Orders Settings -----"; // Sell Orders Settings
input bool    EnableSell           = true;   // Enable Sell Orders
input double  SellLotSize          = 1;    // Lot Size for Sell Orders
input int     SellSL_Distance      = 50;     // Stop Loss Distance for Sell Orders (points)
input int     SellTrailing_Distance = 50;     // Trailing Stop Distance for Sell Orders (points)

// Variables for Other Setting
input string OtherSetting = "----- Other settings -----"; // Other settings
input bool isFollowTrend = true; // True to follow the trend, false to trade against it
input int     MovingAverageType    = MODE_EMA; // Moving Average Type (SMA, EMA, etc.)
input int     MovingAveragePeriod  = 27;     // Period for Moving Average
input int     MagicNumber          = 123456; // Magic Number for Orders
input int     Slippage             = 3;      // Slippage (points)

//--- Global Variables
double MovingAverageValue;

//--- Calculate Moving Average
double CalculateMovingAverage()
  {
   return iMA(NULL, 0, MovingAveragePeriod, 0, MovingAverageType, PRICE_CLOSE, 0);
  }

//--- Function to Check for Open Orders with the Same Magic Number
bool NoOpenOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderMagicNumber() == MagicNumber)
           {
            return false; // An order with the same MagicNumber is open
           }
        }
     }
   return true; // No open orders with the same MagicNumber
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
   MovingAverageValue = CalculateMovingAverage();

//--- Check Buy Condition and No Open Orders
   if(EnableBuy && NoOpenOrders())
     {
      bool buyCondition;
      if(isFollowTrend)
        {
         buyCondition = Ask > MovingAverageValue;  // Follow trend: Buy when Ask > Moving Average
        }
      else
        {
         buyCondition = Ask < MovingAverageValue;  // Against trend: Buy when Ask < Moving Average
        }

      if(buyCondition)
        {
         //--- Place Buy Order
         double BuyPrice = Ask;
         double BuySL = BuyPrice - BuySL_Distance * Point;
         int Ticket = OrderSend(Symbol(), OP_BUY, BuyLotSize, BuyPrice, Slippage, BuySL, 0, "Buy Order", MagicNumber, 0, Blue);
         if(Ticket > 0)
           {
            Print("Buy Order Placed Successfully!");
           }
         else
           {
            Print("Buy Order Failed: ", GetLastError());
           }
        }
     }

//--- Check Sell Condition and No Open Orders
   if(EnableSell && NoOpenOrders())
     {
      bool sellCondition;
      if(isFollowTrend)
        {
         sellCondition = Bid < MovingAverageValue;  // Follow trend: Sell when Bid < Moving Average
        }
      else
        {
         sellCondition = Bid > MovingAverageValue;  // Against trend: Sell when Bid > Moving Average
        }

      if(sellCondition)
        {
         //--- Place Sell Order
         double SellPrice = Bid;
         double SellSL = SellPrice + SellSL_Distance * Point;
         int Ticket = OrderSend(Symbol(), OP_SELL, SellLotSize, SellPrice, Slippage, SellSL, 0, "Sell Order", MagicNumber, 0, Red);
         if(Ticket > 0)
           {
            Print("Sell Order Placed Successfully!");
           }
         else
           {
            Print("Sell Order Failed: ", GetLastError());
           }
        }
     }

//--- Trailing Stop Logic (Buy)
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderType() == OP_BUY && EnableBuy && OrderMagicNumber() == MagicNumber)
           {
            double NewSL = Bid - BuyTrailing_Distance * Point;
            if(NewSL > OrderStopLoss())
               if(OrderModify(OrderTicket(), OrderOpenPrice(), NewSL, OrderTakeProfit(), 0, Blue))
                 {
                  Print("Buy Order Modified Successfully!");
                 }
               else
                 {
                  Print("Buy Order Modification Failed: ", GetLastError());
                 }
           }

         //--- Trailing Stop Logic (Sell)
         if(OrderType() == OP_SELL && EnableSell && OrderMagicNumber() == MagicNumber)
           {
            double NewSL = Ask + SellTrailing_Distance * Point;
            if(NewSL < OrderStopLoss())
               if(OrderModify(OrderTicket(), OrderOpenPrice(), NewSL, OrderTakeProfit(), 0, Red))
                 {
                  Print("Sell Order Modified Successfully!");
                 }
               else
                 {
                  Print("Sell Order Modification Failed: ", GetLastError());
                 }
           }
        }
     }

// Display results on the screen
   Comment(
      "\n" +
      "--------------------" +
      "\n" +
      eaInfo +
      "\n" +
      "--------------------"
   );
  }

//+------------------------------------------------------------------+
