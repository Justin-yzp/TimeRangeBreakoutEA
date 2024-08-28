
#property strict
#property version   "2.00"
//+------------------------------------------------------------------+
//| Inputs                                                           
//+------------------------------------------------------------------+
// Time Range
input int InpRangeStartHour = 1;    //Range Start Hour
input int InpRangeStartMinute = 0;  //Range Start Minute
input int InpRangeEndHour = 1;      //Range End Hour
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
double Risk;

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
   
  
   Comment("Risk Lot = "+ string(Risk)+"\n" +
    "Risk Percent = " + string(InpRiskPercent)+ "\n");
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

}

void OnTick()
{
 
}

