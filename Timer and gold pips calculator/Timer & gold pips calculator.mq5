//+------------------------------------------------------------------+
//|                                          CandleTimerWithPips.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Candle Timer with Pips"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Enums
enum ENUM_DISPLAY_POSITION
  {
   DISPLAY_TOP_RIGHT,      // Top Right Corner
   DISPLAY_BOTTOM_RIGHT,   // Bottom Right Corner
   DISPLAY_FOLLOW_PRICE    // Follow Price Line
  };

//--- Input parameters
input ENUM_DISPLAY_POSITION InpPosition   = DISPLAY_TOP_RIGHT; // Appearance Position
input color                 InpTextColor  = clrWhite;          // Text Color
input int                   InpTextSize   = 12;                // Text Size

//--- Global variables
string displayLabel = "CandleDisplay";
string followLabel  = "FollowDisplay";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetMillisecondTimer(100);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectDelete(0, displayLabel);
   ObjectDelete(0, followLabel);
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   UpdateDisplay();
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer()
  {
   UpdateDisplay();
  }

//+------------------------------------------------------------------+
//| Chart event function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      UpdateDisplay();
     }
  }

//+------------------------------------------------------------------+
//| Get countdown time string                                        |
//+------------------------------------------------------------------+
string GetCountdownString()
  {
   datetime candleTime    = iTime(_Symbol, _Period, 0);
   int      periodSeconds = PeriodSeconds(_Period);
   datetime candleEndTime = candleTime + periodSeconds;
   datetime currentTime   = TimeCurrent();
   int      remaining     = (int)(candleEndTime - currentTime);

   if(remaining < 0)
      remaining = 0;

   int days    = remaining / 86400;
   int hours   = (remaining % 86400) / 3600;
   int minutes = (remaining % 3600) / 60;
   int seconds = remaining % 60;

   string timeStr = "";

   if(days > 0)
      timeStr = StringFormat("%dd %02d:%02d:%02d", days, hours, minutes, seconds);
   else if(hours > 0)
      timeStr = StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
   else
      timeStr = StringFormat("%02d:%02d", minutes, seconds);

   return timeStr;
  }

//+------------------------------------------------------------------+
//| Calculate pips (Gold: after 1 decimal place, truncated to 1 dp)  |
//+------------------------------------------------------------------+
string GetPipsString()
  {
   double high = iHigh(_Symbol, _Period, 0);
   double low  = iLow(_Symbol, _Period, 0);
   double diff = high - low;

   // For Gold (XAUUSD): pips start after 1 decimal place
   // Pips = difference * 10, displayed with 1 decimal place, no rounding
   
   double pips = diff * 10.0;

   // Truncate to 1 decimal place without rounding
   double truncatedPips = MathFloor(pips * 10.0) / 10.0;

   string pipsStr = StringFormat("%.1f", truncatedPips);

   return pipsStr;
  }

//+------------------------------------------------------------------+
//| Get combined display string                                       |
//+------------------------------------------------------------------+
string GetDisplayString()
  {
   string pipsStr      = GetPipsString();
   string countdownStr = GetCountdownString();
   
   return pipsStr + " | " + countdownStr;
  }

//+------------------------------------------------------------------+
//| Update the display                                               |
//+------------------------------------------------------------------+
void UpdateDisplay()
  {
   string displayStr = GetDisplayString();

   // Clean up objects that don't belong to current mode
   CleanupObjects();

   if(InpPosition == DISPLAY_FOLLOW_PRICE)
     {
      DrawFollowPrice(displayStr);
     }
   else
     {
      DrawCorner(displayStr);
     }

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Cleanup objects not used by current mode                          |
//+------------------------------------------------------------------+
void CleanupObjects()
  {
   if(InpPosition == DISPLAY_FOLLOW_PRICE)
     {
      ObjectDelete(0, displayLabel);
     }
   else
     {
      ObjectDelete(0, followLabel);
     }
  }

//+------------------------------------------------------------------+
//| Draw in corner mode                                              |
//+------------------------------------------------------------------+
void DrawCorner(string displayStr)
  {
   ENUM_BASE_CORNER corner;
   ENUM_ANCHOR_POINT anchor;
   int xDist = 15;
   int yDist;

   if(InpPosition == DISPLAY_TOP_RIGHT)
     {
      corner = CORNER_RIGHT_UPPER;
      anchor = ANCHOR_RIGHT_UPPER;
      yDist  = 20;
     }
   else // DISPLAY_BOTTOM_RIGHT
     {
      corner = CORNER_RIGHT_LOWER;
      anchor = ANCHOR_RIGHT_LOWER;
      yDist  = 20;
     }

   // Create or update label
   if(ObjectFind(0, displayLabel) < 0)
     {
      ObjectCreate(0, displayLabel, OBJ_LABEL, 0, 0, 0);
     }

   ObjectSetInteger(0, displayLabel, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, displayLabel, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, displayLabel, OBJPROP_XDISTANCE, xDist);
   ObjectSetInteger(0, displayLabel, OBJPROP_YDISTANCE, yDist);
   ObjectSetString(0, displayLabel, OBJPROP_TEXT, displayStr);
   ObjectSetString(0, displayLabel, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, displayLabel, OBJPROP_FONTSIZE, InpTextSize);
   ObjectSetInteger(0, displayLabel, OBJPROP_COLOR, InpTextColor);
   ObjectSetInteger(0, displayLabel, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, displayLabel, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//| Draw following price line (slightly above price)                  |
//+------------------------------------------------------------------+
void DrawFollowPrice(string displayStr)
  {
   datetime time0  = iTime(_Symbol, _Period, 0);
   double   close0 = iClose(_Symbol, _Period, 0);

   // Calculate bar offset to the right
   int      shift     = 3;
   int      periodSec = PeriodSeconds(_Period);
   datetime timePos   = time0 + periodSec * shift;

   // Get visible chart price range for proper offset calculation
   double chartPriceMin = ChartGetDouble(0, CHART_PRICE_MIN);
   double chartPriceMax = ChartGetDouble(0, CHART_PRICE_MAX);
   double priceRange    = chartPriceMax - chartPriceMin;

   // Calculate offset as percentage of visible range (2% above price)
   double priceOffset = priceRange * 0.02;
   double pricePos    = close0 + priceOffset;

   // Create or update text object
   if(ObjectFind(0, followLabel) < 0)
     {
      ObjectCreate(0, followLabel, OBJ_TEXT, 0, timePos, pricePos);
     }

   ObjectSetString(0, followLabel, OBJPROP_TEXT, displayStr);
   ObjectSetString(0, followLabel, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, followLabel, OBJPROP_FONTSIZE, InpTextSize);
   ObjectSetInteger(0, followLabel, OBJPROP_COLOR, InpTextColor);
   ObjectSetInteger(0, followLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
   ObjectSetInteger(0, followLabel, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, followLabel, OBJPROP_HIDDEN, true);
   ObjectSetDouble(0, followLabel, OBJPROP_PRICE, pricePos);
   ObjectSetInteger(0, followLabel, OBJPROP_TIME, timePos);
  }
//+------------------------------------------------------------------+
