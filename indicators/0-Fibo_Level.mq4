//------------------------------------------------------------------------------------
//                                                                 DiNapoli Levels.mq5
//                                                   The modified indicator FastZZ.mq5
//                                       Added DiNapoli Target Levels and tmpTime Targets
//                                                         victorg, www.mql5.com, 2013
//------------------------------------------------------------------------------------
#property copyright   "Copyright 2012, Yurich"
#property link        "https://login.mql5.com/en/users/Yurich"
#property version     "3.00"
#property description "FastZZ plus DiNapoli Target Levels."
#property description "The modified indicator 'FastZZ.mq5'."
#property description "victorg, www.mql5.com, 2013."
//------------
#property indicator_chart_window // Display the indicator in the chart window
#property indicator_buffers 3 // The number of buffers to calculate the indicator
#property indicator_plots 1 // Number of indicator windows
#property indicator_label1 "DiNapoli Levels" // Set the label for the graphics series displayed in the DataWindow window
#property indicator_type1 DRAW_ZIGZAG // Drawing style of the indicator. N - number of the graphic series
#property indicator_color1 clrTeal, clrOlive // The color for the N line output, where N is the number of the graphics series
#property indicator_style1 STYLE_SOLID // Line Style in the Graphics Series
#property indicator_width1 1 // Line thickness in the graphics series
//------------
input int iDepth = 400; // Minimum of points in the ray
input bool VLine = true; // Show Vertical Lines
input int iNumBars = 5000; // Number of bars in history
input bool Sound = true; // Enable sound notifications
input string SoundFile = "email.wav"; // Audio file
input color cStar = clrBlue; // Color of the start line
input color cStop = clrRed; // Stop line color
input color cTar1 = clrGreen; // The color of the goal line №1
input color cTar2 = clrDarkOrange; // Color of the goal line # 2
input color cTar3 = clrDarkOrchid; // Color of the goal line # 3
input color cTar4 = clrDarkSlateBlue; // Color of the goal line №4
input color cTarT1 = clrDarkSlateGray; // The color of the timeline # 1
input color cTarT2 = clrDarkSlateGray; // The color of the time line # 2
input color cTarT3 = clrSaddleBrown; // Color of the time line №3
input color cTarT4 = clrDarkSlateGray; // Color of the time line №4
input color cTarT5 = clrDarkSlateGray; // The color of the time line №5

// Main variables
double   DiNapoliH[],DiNapoliL[],ColorBuffer[],Depth,A,B,C,Price[6];
int      Last,Direction,Refresh,NumBars;
datetime AT,BT,CT,tmpTime[5];
color    Color[11];
string   Name[11]={"Start Line","Stop Line","Target1 Line","Target2 Line",
                   "Target3 Line","Target4 Line","tmpTime Target1","tmpTime Target2",
                   "tmpTime Target3","tmpTime Target4","tmpTime Target5"};
//------------------------------------------------------------------------------------

// Begin the initialization of the indicator
void OnInit()
  {
  int i;
  string sn,sn2;
  
// Set the conditions for the points in the ray
  if(iDepth<=0)Depth=500; 
  else Depth=iDepth;   
  
// Set the conditions for bars in history   
  if(iNumBars<10)NumBars=10;
  else NumBars=iNumBars;
  
// Set up displaying indicator buffers 
  SetIndexBuffer(0,DiNapoliH,INDICATOR_DATA); 
  SetIndexBuffer(1,DiNapoliL,INDICATOR_DATA);
  SetIndexBuffer(2,ColorBuffer,INDICATOR_COLOR_INDEX);
  
// Set the accuracy of displaying the indicator values
  IndicatorSetInteger(INDICATOR_DIGITS,Digits); 
  
// Set up the drawing of lines
  PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0); 
  PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0); 
  
// Set up a short name for the indicator  
  sn="DiNapoli"; sn2=""; 
  for(i=1;i<100;i++)
    {
// Set up a chart search  
    if(ChartWindowFind(0,sn)<0){break;}
    sn2="_"+(string)i; sn+=sn2;
    }
    
// Set the symbol display   
  IndicatorSetString(INDICATOR_SHORTNAME,sn);
  for(i=0;i<11;i++) Name[i]+=sn2;
  
// Initialize the buffers with empty values 
  ArrayInitialize(DiNapoliH,0); ArrayInitialize(DiNapoliL,0);
  
// Adjust the color lines of the indicator
  Color[0]=cStar; Color[1]=cStop; Color[2]=cTar1; Color[3]=cTar2;
  Color[4]=cTar3; Color[5]=cTar4; Color[6]=cTarT1; Color[7]=cTarT2;
  Color[8]=cTarT3; Color[9]=cTarT4; Color[10]=cTarT5;
  Depth=Depth*Point;
  Direction=1; Last=0; Refresh=1;
  for(i=0;i<6;i++)
    {
    if(ObjectFind(0,sn)!=0)
      {
      
// Set up horizontal and vertical lines    
      ObjectCreate(0,Name[i],OBJ_HLINE,0,0,0);
      ObjectSetInteger(0,Name[i],OBJPROP_COLOR,Color[i]);
      ObjectSetInteger(0,Name[i],OBJPROP_WIDTH,1);
      ObjectSetInteger(0,Name[i],OBJPROP_STYLE,STYLE_DOT);
//    ObjectSetString(0,Name[i],OBJPROP_TEXT,Name[i]);// Object description
      }
    }
  if(VLine==true)
    {
    for(i=6;i<11;i++)
      {
      if(ObjectFind(0,sn)!=0)
        {
        ObjectCreate(0,Name[i],OBJ_VLINE,0,0,0);
        ObjectSetInteger(0,Name[i],OBJPROP_COLOR,Color[i]);
        ObjectSetInteger(0,Name[i],OBJPROP_WIDTH,1);
        ObjectSetInteger(0,Name[i],OBJPROP_STYLE,STYLE_DOT);
//      ObjectSetString(0,Name[i],OBJPROP_TEXT,Name[i]);// Object description
        }
      }
    }
  }
  
// Add function when the indicator is removed from the graph, graphic objects are deleted from the indicator
void OnDeinit(const int reason)
  {
  int i;
   
  for(i=0;i<11;i++) ObjectDelete(0,Name[i]);
  ChartRedraw();
  return;
  }


// Function of iteration of the indicator
int OnCalculate (const int total, // Size of the input timeseries
                 const int calculated, // Processed bars call
                 const datetime & time [], // Array with time values
                 const double & open [], // Array with opening prices
                 const double & high [], // Array for copying the maximum prices
                 const double & low [], // Array of minimum prices
                 const double & close [], // The closing price array
                 const long & tick [], // Parameter containing the history of the tick volume
                 const long & real [], // Real volume
                 const int & spread []) // An array containing the spreads history           

  {
  int i,start;
  bool set;
  double a;

// Set the bar check
  if(calculated<=0)
    {
    start=total-NumBars; if(start<0)start=0;
    
// Initialize the buffers with empty values 
    Last=start; ArrayInitialize(ColorBuffer,0);
    ArrayInitialize(DiNapoliH,0); ArrayInitialize(DiNapoliL,0);
    }
    
// Calculation of a new bar  
  else start=calculated-1;
  for(i=start;i<total-1;i++)
    {
    set=false; DiNapoliL[i]=0; DiNapoliH[i]=0;
    if(Direction>0)
      {
      if(high[i]>DiNapoliH[Last])
        {
        DiNapoliH[Last]=0; DiNapoliH[i]=high[i];
        if(low[i]<high[Last]-Depth)
          {
          if(open[i]<close[i])
            {
            DiNapoliH[Last]=high[Last];
            A=C; B=high[Last]; C=low[i];
            AT=CT; BT=time[Last]; CT=time[i];
            Refresh=1;
            }
          else
            {
            Direction=-1;
            A=B; B=C; C=high[i];
            AT=BT; BT=CT; CT=time[i];
            Refresh=1;
            }
          DiNapoliL[i]=low[i];
          }
          
// Set the line colors    
        ColorBuffer[Last]=0; Last=i; ColorBuffer[Last]=1;
        set=true;
        }
      if(low[i]<DiNapoliH[Last]-Depth&&(!set||open[i]>close[i]))
        {
        DiNapoliL[i]=low[i];
        if(high[i]>DiNapoliL[i]+Depth&&open[i]<close[i])
          {
          DiNapoliH[i]=high[i];
          A=C; B=high[Last]; C=low[i];
          AT=CT; BT=time[Last]; CT=time[i];
          Refresh=1;
          }
        else
          {
          if(Direction>0)
            {
            A=B; B=C; C=high[Last];
            AT=BT; BT=CT; CT=time[Last];
            Refresh=1;
            }
          Direction=-1;
          }
          
// Set the line colors           
        ColorBuffer[Last]=0; Last=i; ColorBuffer[Last]=1;
        }
      }
    else
      {
      if(low[i]<DiNapoliL[Last])
        {
        DiNapoliL[Last]=0; DiNapoliL[i]=low[i];
        if(high[i]>low[Last]+Depth)
          {
          if(open[i]>close[i])
            {
            DiNapoliL[Last]=low[Last];
            A=C; B=low[Last]; C=high[i];
            AT=CT; BT=time[Last]; CT=time[i];
            Refresh=1;
            }
          else
            {
            Direction=1;
            A=B; B=C; C=low[i];
            AT=BT; BT=CT; CT=time[i];
            Refresh=1;
            }
          DiNapoliH[i]=high[i];
          }
          
// Set the line colors         
        ColorBuffer[Last]=0; Last=i; ColorBuffer[Last]=1;
        set=true;
        }
      if(high[i]>DiNapoliL[Last]+Depth&&(!set||open[i]<close[i]))
        {
        DiNapoliH[i]=high[i];
        if(low[i]<DiNapoliH[i]-Depth&&open[i]>close[i])
          {
          DiNapoliL[i]=low[i];
          A=C; B=low[Last]; C=high[i];
          AT=CT; BT=time[Last]; CT=time[i];
          Refresh=1;
          }
        else
          {
          if(Direction<0)
            {
            A=B; B=C; C=low[Last];
            AT=BT; BT=CT; CT=time[Last];
            Refresh=1;
            }
          Direction=1;
          }
// Set the line colors           
        ColorBuffer[Last]=0; Last=i; ColorBuffer[Last]=1;
        }
      }
    DiNapoliH[total-1]=0; DiNapoliL[total-1]=0;
    }
//------------
  if(Refresh==1)
    {
    
// The final cycle of calculating the indicator    

// Check the number of bars for sufficiency for calculation
    Refresh=0; a=B-A;
    Price[0]=NormalizeDouble(a*0.318+C,Digits);           // Start;
    Price[1]=C;                                            // Stop;
    Price[2]=NormalizeDouble(a*0.618+C,Digits);           // Target№1
    Price[3]=a+C;                                          // Target№2;
    Price[4]=NormalizeDouble(a*1.618+C,Digits);           // Target№3;
    Price[5]=NormalizeDouble(a*2.618+C,Digits);           // Target№4;
    for(i=0;i<6;i++) ObjectMove(0,Name[i],0,time[total-1],Price[i]);
    if(VLine==true)
      {
 
// Return the value rounded to the nearest integer of the specified value     
      a=(double)(BT-AT);
      tmpTime[0]=(datetime)MathRound(a*0.318)+CT;             // Temporary goal number №1
      tmpTime[1]=(datetime)MathRound(a*0.618)+CT;             // Temporary goal number №2
      tmpTime[2]=(datetime)MathRound(a)+CT;                   // Temporary goal number №3
      tmpTime[3]=(datetime)MathRound(a*1.618)+CT;             // Temporary goal number №4
      tmpTime[4]=(datetime)MathRound(a*2.618)+CT;             // Temporary goal number №5
      for(i=6;i<11;i++) ObjectMove(0,Name[i],0,tmpTime[i-6],open[total-1]);
      }
    ChartRedraw();
    
// If the direction is changed then turn on the audio playback
    if(Sound==true&&calculated>0)PlaySound(SoundFile);
    }
  return(total);
  }
//------------------------------------------------------------------------------------

