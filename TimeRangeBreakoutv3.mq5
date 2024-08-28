
#property strict
#property version   "2.00"
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

// EA settings
input long InpMagic = 3253;                            //Magic Number
input string InpTradeComment = "TIME RANGE BREAKOUT";  //Trade Comment
input double InpRiskPercent = 1;                       // Risk Percent

// Global Variables
double RangeGap = 0;
double StopLoss = 0;
double TakeProfit1 = 0;
double TakeProfit2 = 0;
double TakeProfit3 = 0;
double Risk;

datetime StartTime = 0;
datetime EndTime = 0;
bool InRange = false;
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
      
   Risk = InpRiskPercent / 100;
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
   
   
  
   

   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

}

void OnTick()
{
 Comment("Risk Lot = " + string(Risk) + "\n"
            + "Risk Percent = " + string(InpRiskPercent) + "\n"
            + "In Range = " + string(InRange) + "\n"
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