
#property strict
#property version   "2.00"

#include <Trade\Trade.mqh>

CTrade Trade;



enum ENUM_RISK_TYPE{
   RISK_TYPE_FIXED_LOTS,       //Fixed Lots
   RISK_TYPE_EQUITY_PERCENT,   //Percent Of Equity
};

//+------------------------------------------------------------------+
//| Inputs                                                           
//+------------------------------------------------------------------+
// Time Range
input int InpRangeStartHour = 1;    //Range Start Hour
input int InpRangeStartMinute = 0;  //Range Start Minute
input int InpRangeEndHour = 5;      //Range End Hour
input int InpRangeEndminute = 0;    //Range End Minute

// Entry Inputs
input double InpRangeGapPips = 7.0;    //Entry Gap Pip
input double InpStopLossPips = 25.0;   //Stop Loss in Pips
input double InpTakeProfit1Pips = 15;  //Take Profit 1 in Pips
input double InpTakeProfit2Pips = 35;  //Take Profit 2  in Pips
input double InpTakeProfit3Pips = 50;  //Take Profit 3 in Pips
input bool InpBreakEven = false;       //Break Even After TP1 
input bool InpCloseEOD = true;    //Close All Trade EOD

// EA settings
input long InpMagic = 3253;                               //Magic Number
input string InpTradeComment = "TIME RANGE BREAKOUT";     //Trade Comment
input double InpRisk = 0.01;                               //Risk
input ENUM_RISK_TYPE InpRiskType = RISK_TYPE_FIXED_LOTS;  //Risk Type

// Global Variables
double RangeGap = 0;
double StopLoss = 0;
double TakeProfit1 = 0;
double TakeProfit2 = 0;
double TakeProfit3 = 0;


datetime StartTime = 0;
datetime EndTime = 0;
bool InRange = false;

long Magic1 = 0;
long Magic2 = 0;


int PositionCount = 0;

double BuyEntryPrice = 0;
double SellEntryPrice = 0;


;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   
   if(InpRangeStartHour < 0 || InpRangeStartHour > 23)
      {
         Alert("Start hour must be from 0 - 23");
         return INIT_PARAMETERS_INCORRECT;
      }
   if(InpRangeStartMinute < 0 || InpRangeStartMinute > 59)
      {
         Alert("Start Minute must be from 0 - 59");
         return INIT_PARAMETERS_INCORRECT;
      }
      
   if(InpRangeEndHour < 0 || InpRangeEndHour > 23)
      {
         Alert("End hour must be from 0 - 23");
         return INIT_PARAMETERS_INCORRECT;
      }
   if(InpRangeEndminute < 0 || InpRangeEndminute > 59)
      {
         Alert("End Minute must be from 0 - 59");
         return INIT_PARAMETERS_INCORRECT;
      }
      
   
   
   RangeGap = PipsToDouble(InpRangeGapPips);
   StopLoss = PipsToDouble(InpStopLossPips);
   TakeProfit1 = PipsToDouble(InpTakeProfit1Pips);
   TakeProfit2 = PipsToDouble(InpTakeProfit2Pips);
   TakeProfit3 = PipsToDouble(InpTakeProfit3Pips);
   
   BuyEntryPrice = 0;
   SellEntryPrice = 0;
   
   //Trade.SetExpertMagicNumber(InpMagic);
   
   
   datetime now = TimeCurrent();
   
   if (IsTradingDay(now)) 
    {
        
        EndTime = SetNextTime(now + 60, InpRangeEndHour, InpRangeEndminute);
        StartTime = SetPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
    } 
    else 
    {
        Alert("Market is currently closed. Setting times to the next market open.");
    }
   
   InRange = (StartTime <= now && EndTime > now);
   
   
   Magic1 = InpMagic;
   Magic2 = Magic1 + 1;
   
   PositionCount = 0;
   UpdateBreakEven();
   

   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

}

void OnTick()
{
   if (PositionCount != PositionsTotal()){
      UpdateBreakEven();
   }
   
   datetime now = TimeCurrent();
   bool currentlyInRange = ( StartTime <= now && now<EndTime);
   
   if(InRange && !currentlyInRange)
     {
     SetTradeEntries();
  
     }
     
   if(now >= EndTime){
      EndTime = SetNextTime(EndTime+60, InpRangeEndHour, InpRangeEndminute);
      StartTime = SetPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
     }  
     
   InRange = currentlyInRange;
   
   double currentprice = 0;
   if(BuyEntryPrice > 0)
     {
      currentprice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      if(currentprice >= BuyEntryPrice)
        {
         OpenTrade(ORDER_TYPE_BUY, currentprice);
         BuyEntryPrice = 0;
         SellEntryPrice = 0;
        }
     }
   if(SellEntryPrice > 0)
     {
      currentprice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      if(currentprice <= SellEntryPrice)
        {
         OpenTrade(ORDER_TYPE_SELL, currentprice);
         BuyEntryPrice = 0;
         SellEntryPrice = 0;
        }
     }
     
   updateCloseEOD(Magic1, Magic2);
   





 Comment("Risk = " + string(InpRisk) + "\n"
            + "In Range = " + string(currentlyInRange) + "\n"
            + "Start Time = " + TimeToString(StartTime, TIME_DATE | TIME_MINUTES) + "\n"
            + "End Time = " + TimeToString(EndTime, TIME_DATE | TIME_MINUTES) + "\n"
            
            
            );
}

datetime SetNextTime(datetime now, int hour, int minute) 
{
    MqlDateTime nowStruct;
    TimeToStruct(now, nowStruct);

    nowStruct.sec = 0;
    datetime nowTime = StructToTime(nowStruct);

    nowStruct.hour = hour;
    nowStruct.min = minute;
    datetime nextTime = StructToTime(nowStruct);

    int maxIterations = 30;  // Prevent infinite loops
    int iterations = 0;

    while ((nextTime < nowTime || !IsTradingDay(nextTime)) && iterations < maxIterations)
    {
        nextTime += 86400;
        iterations++;
    }

    if (iterations >= maxIterations)
    {
        Alert("SetNextTime reached max iterations without finding a valid time.");
        return -1;
    }

    return nextTime;
}

datetime SetPrevTime(datetime now, int hour, int minute) 
{
    MqlDateTime nowStruct;
    TimeToStruct(now, nowStruct);

    nowStruct.sec = 0;
    datetime nowTime = StructToTime(nowStruct);

    nowStruct.hour = hour;
    nowStruct.min = minute;
    datetime prevTime = StructToTime(nowStruct);

    int maxIterations = 30;  // Prevent infinite loops
    int iterations = 0;

    while ((prevTime > nowTime || !IsTradingDay(prevTime)) && iterations < maxIterations)
    {
        prevTime -= 86400;
        iterations++;
    }

    if (iterations >= maxIterations)
    {
        Alert("SetPrevTime reached max iterations without finding a valid time.");
        return -1;
    }

    return prevTime;
}


bool IsTradingDay(datetime time){

   MqlDateTime timeStruct;
   TimeToStruct(time, timeStruct);
   datetime fromTime;
   datetime toTime;
   return SymbolInfoSessionTrade(Symbol(), (ENUM_DAY_OF_WEEK)timeStruct.day_of_week, 0, fromTime, toTime);
   
}

double PipsToDouble(double pips){
   return PipsToDouble(Symbol(), pips);
}

double PipsToDouble(string symbol, double pips){

   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3|| digits == 5){
      pips = pips * 10;
      
   }
   double value = pips * SymbolInfoDouble(symbol, SYMBOL_POINT);
   return value;
   

}

void SetTradeEntries(){

   int startBar = iBarShift(Symbol(), PERIOD_M1, StartTime, false);
   int endBar = iBarShift(Symbol(), PERIOD_M1, EndTime, false)+ 1;
   
   double high = iHigh(Symbol(), PERIOD_M1, iHighest(Symbol(), PERIOD_M1, MODE_HIGH, startBar - endBar +1, endBar));
   double low = iLow(Symbol(), PERIOD_M1, iLowest(Symbol(), PERIOD_M1, MODE_LOW, startBar - endBar +1, endBar));
   
   BuyEntryPrice = high + RangeGap;
   SellEntryPrice = low - RangeGap;
}

void OpenTrade(ENUM_ORDER_TYPE type, double price){

   double sl = 0;
   
   if (type == ORDER_TYPE_BUY){
      sl = price - StopLoss;
   
   }else
      {
       sl = price + StopLoss;
      }
      
  if (!OpenTrade(type, price, sl, TakeProfit1, Magic1)) return;
  if (!OpenTrade(type, price, sl, TakeProfit2, Magic2)) return;
  if (!OpenTrade(type, price, sl, TakeProfit3, Magic2)) return;
}

bool OpenTrade(ENUM_ORDER_TYPE type, double price, double sl, double takeProfit, long magic){
   
   if (takeProfit ==0) return true;
   
   double tp = 0;
   
   if (type == ORDER_TYPE_BUY){
      tp = price + takeProfit;
   }else{
      tp = price - takeProfit;
   }
   
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   price = NormalizeDouble(price, digits);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);
   
   double Volume = 0;
   if (InpRiskType == RISK_TYPE_EQUITY_PERCENT){
      Volume = GetRiskVolume(InpRisk/100, MathAbs(price -sl));
   }else{
      Volume = InpRisk;
   }
   Trade.SetExpertMagicNumber(magic);
   if (!Trade.PositionOpen(Symbol(), type, Volume, price, sl, tp, InpTradeComment)){
      PrintFormat("Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f",
                  EnumToString(type), Volume, price, sl ,tp);
      
      return false;
   }
   return true;
   
   
}
double GetRiskVolume(double risk, double loss){

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskAmount = risk * equity;
   
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double lossTicks = loss / tickSize;
   
   double volume = riskAmount /(lossTicks * tickValue);
   volume = NormaliseVolume(volume);
   
   return volume;
   


}

double NormaliseVolume(double volume){
   if(volume == 0) return 0;
     
   double max = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double min = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   
   double result = MathRound(volume/step) * step;
   if (result > max ) result = max;
   if (result < min ) result = min;
   
   return result;
     
}

void UpdateBreakEven(){
   if (!InpBreakEven) return;
   
   for (int i = PositionsTotal() -1; i>= 0; i--){
      if(!PositionSelectByIndex(i, Magic2)) continue;
      if(PositionStopLoss() == PositionPriceOpen()) continue; // already set be
      
      datetime timeopen = PositionTimeOpen();
      
      
      long ticket = PositionTicket();
      double priceOpen = PositionPriceOpen();
      double takeProfit = PositionTakeProfit();
      
      if (!IsPrimaryOpen(timeopen)){
      
         SetBreakEven(ticket, priceOpen, takeProfit);
      
      }
   
   
   }
   
   PositionCount = PositionsTotal();

}




bool PositionSelectByIndex(int index, long magic, datetime groupTime){
   if (!PositionSelectByIndex(index, magic)) return false;
   if (MathAbs(PositionTimeOpen()-groupTime) > 300)return false;
   return true;


}

bool PositionSelectByIndex(int index, long magic){
   ulong ticket = PositionGetTicket(index);
   if (ticket <= 0) return false;
   if (PositionSymbol() != Symbol()) return false;
   if (PositionMagic()!= magic) return false;
   
   return true;

}

double PositionPriceOpen(){return PositionGetDouble(POSITION_PRICE_OPEN);}
double PositionTakeProfit(){return PositionGetDouble(POSITION_TP);}
double PositionStopLoss(){return PositionGetDouble(POSITION_SL);}
long PositionTicket(){return PositionGetInteger(POSITION_TICKET);}
datetime PositionTimeOpen(){return (datetime)PositionGetInteger(POSITION_TIME);}
long PositionMagic(){return PositionGetInteger(POSITION_MAGIC);}
int PositionType(){return (int)PositionGetInteger(POSITION_TYPE);}
string PositionSymbol(){return PositionGetString(POSITION_SYMBOL);}

void SetBreakEven (long ticket, double priceOpen, double takeProfit){
   Trade.PositionModify(ticket,priceOpen,takeProfit);

}

bool IsPrimaryOpen(datetime timeOpen){

   bool primaryOpen = false;
   for(int i = PositionsTotal()-1; i >=0; i--){
   
      if (PositionSelectByIndex(i, Magic1, timeOpen)) return true;
   }
   
   return false;

}

void updateCloseEOD(long magic1, long magic2)
{
   if(!InpCloseEOD) return;
   
   datetime now = TimeCurrent();
   datetime today = now - (now % 86400); // Get the start of the current day
   datetime closeTime = today + 23 * 3600 + 50 * 60; // 23:50:00
   
   if(now >= closeTime)
   {
      CloseAllTradesByMagic(magic1);
      CloseAllTradesByMagic(magic2);
   }
}

void CloseAllTradesByMagic(long magicNumber)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetInteger(POSITION_MAGIC) == magicNumber)
      {
         Trade.PositionClose(ticket);
      }
   }
}