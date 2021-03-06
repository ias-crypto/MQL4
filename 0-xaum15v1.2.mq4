//+------------------------------------------------------------------+
//|                                                 0-xaum15v1.2.mq4 |
//|                                                   Copyright 2018 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "xau_m15"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <stdlib.mqh>

extern int Magic=142308;
extern double Lots=0.1;
extern bool AutoLots=true;
extern double Risk=2;
double TakePorfit=60;
double StopLoss=40;
extern int Start_Hour=15;
extern int End_Hour=23;
extern double Alpha=1.6;

double tp,sl;
double hhv,llv;
datetime dt1,dt2;
bool time_ok;
bool Daydn=false,Dayup=false;
bool PendingDaydn=false,PendingDayup=false;
int day=-1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(StringSubstr(Symbol(),0,6)!="XAUUSD") {Alert("Only for XAUUSD M15 !"); return(-1);}
   if(Start_Hour<13) Start_Hour=14;
   hhv = 99999;
   llv = -99999;
   Daydn=false;
   Dayup=false;
   PendingDaydn=false;
   PendingDayup=false;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   del_obj();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void del_obj()
  {
   int k=0;
   while(k<ObjectsTotal())
     {
      string objname=ObjectName(k);
      if(StringSubstr(objname,0,1)=="a")
         ObjectDelete(objname);
      else
         k++;
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   string sym=Symbol();

   if(Day()!=day)
     {
      Daydn=false;
      Dayup=false;
      PendingDaydn=false;
      PendingDayup=false;
      day=Day();
     }
   CheckOrders();
   americaBoxs(sym,hhv,llv);
   americaBreakOutTrade();
   TrailOrderStop(sym);

   dt2=dt1+12*3600;
   DrawTrendLines("hi",dt1,hhv,dt2,hhv);
   DrawTrendLines("lo",dt1,llv,dt2,llv);

   Comment("\nDHV@ ",hhv,"\nDLV@ ",llv,"\nLots@ ",DoubleToString(LotSize(),2));
  }
//+------------------------------------------------------------------+

void CheckOrders()
  {
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==Magic && OrderSymbol()==Symbol())
           {
            if(Hour()==23 && Minute()>=40) //  订单不过夜
              {
               OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),7);
              }
           }
        }
     }
   if(OrderCounts(OP_BUY)>0 && !IfOrderDoesNotExist33(OP_SELLSTOP) && PendingDaydn==false) PendingOrder(OP_SELLSTOP);
   if(OrderCounts(OP_BUY)==0 ) DeletePendingOrder(OP_SELLSTOP);
   if(OrderCounts(OP_SELL)>0 && !IfOrderDoesNotExist33(OP_BUYSTOP)  && PendingDayup==false) PendingOrder(OP_BUYSTOP);
   if(OrderCounts(OP_SELL)==0) DeletePendingOrder(OP_BUYSTOP);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void americaBreakOutTrade()
  {
   if(Hour()<Start_Hour || Hour()>End_Hour) return;

   if(Ask>hhv) // buy
     {
      if((!IfOrderDoesNotExist(OP_BUY)) && Dayup==false) //加上后面的判断，则每天下下各最多一单
        {
         Dayup=true;
         MarketOrder(OP_BUY);
        }
     }
   if(Bid<llv) // sell
     {
      if((!IfOrderDoesNotExist(OP_SELL)) && Daydn==false)
        {
         Daydn=true;
         MarketOrder(OP_SELL);
        }
     }
  }
//+------------------------------------------------------------------+
string EAName="xau";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MarketOrder(int Mode)
  {
   double price=0;
   color ColorSet=White;
   double SL=0;
   double TP=0;
   double MarketLot=LotSize();

   if(Mode==1) // sell
     {
      price=NormalizeDouble(Bid,Digits);
      SL=hhv+130*Point;
      if(SL-Bid<500*Point) SL=Bid+500*Point;
      TP=price -(hhv-llv)*2.24;
      ColorSet=Red;
      if(OrderCounts(0)>0) MarketLot=MarketLot*1.6;
     }
   if(Mode==0) // buy
     {
      price=NormalizeDouble(Ask,Digits);
      SL=llv-130*Point;
      if(Ask-SL<500*Point) SL=Ask-500*Point;
      TP=price+(hhv-llv)*2.24;
      ColorSet=Blue;
      if(OrderCounts(1)>0) MarketLot=MarketLot*1.6;
     }
   if(StopLoss == 0) {SL = 0; }
   if(StopLoss == 0) {TP = 0; }
   while(!IsTradeAllowed()) Sleep(100);

   int ticket=OrderSend(Symbol(),Mode,NormalizeDouble(MarketLot,2),price,3,NormalizeDouble(SL,Digits),NormalizeDouble(TP,Digits),EAName,Magic,0,ColorSet);

   if(ticket==-1)
     {
      Print("OrderSend() error - ",ErrorDescription(GetLastError()));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IfOrderDoesNotExist(int Type)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderType()==Type && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) //&& OrderComment()==EAName)
           {
            return(1);
           }
        }
      else
        {
         Print("OrderSelect() error - ",ErrorDescription(GetLastError()));
        }
     }
   return(0);
  }
//+------------------------------------------------------------------+
bool IfOrderDoesNotExist33(int Type)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderType()==Type && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic+1) //&& OrderComment()==EAName)
           {
            return(1);
           }
        }
      else
        {
         Print("OrderSelect() error - ",ErrorDescription(GetLastError()));
        }
     }
   return(0);
  }  
//*******************************************************************************************************
void PendingOrder(int Mode)
  {
   double price=0;
   color ColorSet=White;
   double SL=0;
   double TP=0;   
   double PendingLot=0;
   
   PendingLot = GetLastOrderLots(5-Mode)*Alpha;

   if(Mode==5) // sellstop
     {
      PendingDaydn=true;
      price=NormalizeDouble(llv,Digits);
      ColorSet=Red;
     }
   if(Mode==4) // buystop
     {
      PendingDayup=true;
      price=NormalizeDouble(hhv,Digits);
      ColorSet=Blue;
     }
   //if(StopLoss == 0) {SL = 0; }
   //if(StopLoss == 0) {TP = 0; }
   while(!IsTradeAllowed()) Sleep(100);

   int ticket=OrderSend(Symbol(),Mode,NormalizeDouble(PendingLot,2),price,3,NormalizeDouble(SL,Digits),NormalizeDouble(TP,Digits),EAName,Magic+1,0,ColorSet);
   
   if(ticket==-1)
     {
      Print("OrderSend() error - ",ErrorDescription(GetLastError()));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeletePendingOrder(int Mode)
  {
   while(!IsTradeAllowed()) Sleep(100);
   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderType()==Mode && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic+1)
           {
            bool ret=OrderDelete(OrderTicket(),CLR_NONE);
            if(ret==false)
              {
               Print("OrderDelete() error - ",ErrorDescription(GetLastError()));
              }
           }
        }
  }
//+------------------------------------------------------------------+
double NewOrderCounts(int type)
  {
   double BuyOrders=0;
   double SellOrders=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber() == Magic+1 && OrderSymbol() == Symbol() ) BuyOrders++;
      if(OrderMagicNumber() == Magic+1 && OrderSymbol() == Symbol() ) SellOrders++;
     }
   switch(type)
     {
      case OP_BUY: return (BuyOrders);
      break;
      case OP_SELL: return (SellOrders);
      break;
     }
   return(0);
  }
//+------------------------------------------------------------------+  

double GetLastOrderLots(int Mode)
  {
   double lastLots=0;
   while(!IsTradeAllowed()) Sleep(100);
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderType()==Mode && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
           {
            lastLots=OrderLots();
           }
        }
     }
   return(lastLots);  
  }
//+------------------------------------------------------------------+
void americaBoxs(string symbol,double &hv,double &lv)
  {
   int ihour=TimeHour(TimeCurrent())-Start_Hour;
   if(ihour<0)
     {
      hv=99999;
      lv=-99999;
     }
   else if(Hour()==Start_Hour && Minute()<=1)
     {
      hv = High[iHighest(symbol,PERIOD_M15,MODE_HIGH,10,0)];
      lv = Low[iLowest(symbol,PERIOD_M15,MODE_LOW,10,0)];
      dt1=Time[ihour+3*PERIOD_H1/Period()];
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawTrendLines(string name,datetime t1,double price1,datetime t2,double price2,string pre="a")
  {
   string  objname=pre+name+"-"+t1;
   ObjectCreate(objname,OBJ_TREND,0,t1,price1,t2,price2);
   ObjectSet(objname,OBJPROP_RAY,0);
   ObjectSet(objname,OBJPROP_COLOR,Green);
   ObjectSet(objname,OBJPROP_WIDTH,2);
   ObjectSet(objname,OBJPROP_STYLE,STYLE_SOLID);
//ObjectSet(objname,OBJPROP_TIMEFRAMES,vis);
  }
//+------------------------------------------------------------------+
// -------------------------------------------------
// TrailOrderStop() start
// -------------------------------------------------
extern int TrailingStop=10;
extern double Delta=3;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailOrderStop(string symbol)
  {
   if(TrailingStop==0) return;
   int direction;
   double trail_val,old_stopv,new_stopv,gap_price,gap_stops;
   int digits=MarketInfo(symbol,MODE_DIGITS);
   double point=MarketInfo(symbol,MODE_POINT);

   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==symbol && OrderMagicNumber()>=Magic && OrderMagicNumber()<=Magic+1)
           {
            direction=(1-2 *(OrderType()%2));

            trail_val = NormalizeDouble(TrailingStop * point * direction, digits);
            old_stopv = NormalizeDouble(iif(direction>0 || OrderStopLoss()!=0, OrderStopLoss(), 999999), digits);
            new_stopv = NormalizeDouble(PriceClose(direction,symbol) - trail_val, digits);
            gap_price = NormalizeDouble(new_stopv - OrderOpenPrice(), digits);
            gap_stops = NormalizeDouble(new_stopv - old_stopv, digits);

            //double new_takep = NormalizeDouble(OrderTakeProfit(), digits);
            //double gap_tp_sl = NormalizeDouble(new_takep - new_stopv, digits);

            if(gap_price*direction>Delta*10*point && gap_stops*direction>=point && (OrderProfit()+OrderCommission()+OrderSwap()>7*OrderLots()))
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),new_stopv,OrderTakeProfit(),0);
              }
           }
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceOpen(int direction,string symbol)
  {
   return(iif(direction > 0, MarketInfo(symbol,MODE_BID), MarketInfo(symbol,MODE_ASK)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceClose(int direction,string symbol)
  {
   return(iif(direction > 0, MarketInfo(symbol,MODE_ASK), MarketInfo(symbol,MODE_BID)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iif(bool condition,double ifTrue,double ifFalse)
  {
   if(condition) return(ifTrue);
   return(ifFalse);
  }
//// TrailOrderStop() end
// ---------------------------------------------------
//+------------------------------------------------------------------+
double OrderCounts(int type)
  {
   double BuyOrders=0;
   double SellOrders=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == OP_BUY  && OrderMagicNumber() == Magic && OrderSymbol() == Symbol() ) BuyOrders++;
      if(OrderType() == OP_SELL && OrderMagicNumber() == Magic && OrderSymbol() == Symbol() ) SellOrders++;
     }
   switch(type)
     {
      case OP_BUY: return (BuyOrders);
      break;
      case OP_SELL: return (SellOrders);
      break;
     }
   return(0);
  }
//+------------------------------------------------------------------+  
double LotSize()
  {
   double lot=Lots;
   if(AutoLots==false) return(Lots);

   lot=AccountLeverage()*AccountFreeMargin()/100000*Risk/100.0/2.0;
   if(lot<MarketInfo(Symbol(),MODE_MINLOT)) lot =MarketInfo(Symbol(),MODE_MINLOT);
   if(lot>MarketInfo(Symbol(),MODE_MAXLOT)) lot =MarketInfo(Symbol(),MODE_MAXLOT);

   return(NormalizeDouble(lot,2));
  }
//+------------------------------------------------------------------+  
