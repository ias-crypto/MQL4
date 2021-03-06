//+------------------------------------------------------------------+
//|                                                     0-AddCur.mq4 |
//|                                                                  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//---------------------------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Aqua
#property indicator_color2 Yellow
#property indicator_color3 Aqua
#property indicator_color4 Yellow
extern string 添加商品="EURUSD";
extern int 对准均线=5;
double MyBuffer1[];
double MyBuffer2[];
double MyBuffer3[];
double MyBuffer4[];
double multp;
string my_symbol;

int init()  {
   SetIndexBuffer(0, MyBuffer1);
   SetIndexBuffer(1, MyBuffer2);
   SetIndexBuffer(2, MyBuffer3);
   SetIndexBuffer(3, MyBuffer4);
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,3);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,0);
   SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,0);
   my_symbol=添加商品;
   int kk=PERIOD_D1/Period();
   if(kk<1) kk=1;
   multp=iMA(NULL,0,对准均线*kk,0,MODE_SMA,PRICE_CLOSE,0)/iMA(my_symbol,0,对准均线*kk,0,MODE_SMA,PRICE_CLOSE,0);
   return(0);
}

int start()  {
   int limit;
   int counted_bars=IndicatorCounted();
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
   for(int t=0; t<limit; t++)
   {
      MyBuffer1[t]=iOpen(my_symbol,0,t)*multp;
      MyBuffer2[t]=iClose(my_symbol,0,t)*multp;
      if (iOpen(my_symbol,0,t)==iClose(my_symbol,0,t))
         MyBuffer2[t]=iClose(my_symbol,0,t)*multp-0.1*Point;
      if (iOpen(my_symbol,0,t)>=iClose(my_symbol,0,t))  
      {
         MyBuffer3[t]=iHigh(my_symbol,0,t)*multp;
         MyBuffer4[t]=iLow(my_symbol,0,t)*multp;
      }
      else  if(iOpen(my_symbol,0,t)<iClose(my_symbol,0,t))
      {
         MyBuffer3[t]=iLow(my_symbol,0,t)*multp;
         MyBuffer4[t]=iHigh(my_symbol,0,t)*multp;
      }
   }
   //Comment("\nAdd cur Price: ",DoubleToStr(MyBuffer2[0],Digits));
   return(0);
}
//-----------------------------------------------------------------------------------------------------