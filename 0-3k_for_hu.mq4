//+------------------------------------------------------------------+
//|                                                  0-3k_for_hu.mq4 |
//|                                                   Copyright 2018 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "适合震荡行情，大单边行情将不断亏损。请谨慎使用，后果自负。"

#property version   "1.00"
#property strict

#include <stdlib.mqh>

string EAName="hu";
extern int Magic=1314;
extern double Lots=0.1;
extern bool AutoLotSize=true;
extern double Risk=2;
extern double LotFactor=2.3;
extern double MaxDN=38;
extern bool AutoSL=true;
extern double SingleOrderTP=530;
extern double SingleOrderSL=230;
extern double StartTrailStop=38;
extern double TrailingStop=10;  // 0-关闭移动止损
extern bool ZhengDang=true;

double Slippage=3;
double PipValue=1;
double ReverseOrderLotDiv=2;
double natr=2*800;
datetime otime,ctime,dtime;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(LotFactor>=2.5) {LotFactor=2.3;Alert("High Risk !!! Please set 'LotFactor' less than 2.3 !");}
//---
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
   if(!IfOrderDoesNotExist(0))DeletePendingOrder(5);
   if(!IfOrderDoesNotExist(1))DeletePendingOrder(4);
   
   MMProtect();
   Processing();
   TrailOrderStop(Symbol());
  }
//+------------------------------------------------------------------+
void Processing()
  {
   if(Close[3]<Open[3] && Close[2]>Open[2] && Close[2]<Open[3] && Close[1]>Open[1] && Close[1]>Open[3])
     {
      SendOrder(OP_BUY);
     }
   if(Close[3]>Open[3] && Close[2]<Open[2] && Close[2]>Open[3] && Close[1]<Open[1] && Close[1]<Open[3])
     {
      SendOrder(OP_SELL);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendOrder(int type)
  {
   if(!IfOrderDoesNotExist(type))
     {
      DeletePendingOrder(5-type);MarketOrder(type);
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
         if(OrderType()==Type && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
           {
            return(true);
           }
        }
      else
        {
         Print("OrderSelect() error - ",ErrorDescription(GetLastError()));
        }
     }
   return(false);
  }
//*******************************************************************************************************
void MarketOrder(int Mode)
  {
   double price=0;
   color ColorSet=White;
   double SL=0;
   double TP=0;
   double NDigits=Digits; ///
   double MarketLot=NormalizeDouble((LotsSize(Symbol())/ReverseOrderLotDiv),2);
   int SlippageOrder=Slippage*PipValue;
   double hv=High[iHighest(Symbol(),0,MODE_HIGH,3,1)];
   double lv=Low[iLowest(Symbol(),0,MODE_LOW,3,1)];
   int pMode=-1;
   double pprice=0;
   double pSL=0,pTP=0;

   if(Mode==1)
     {
      price=NormalizeDouble(Bid,NDigits);
      SL = price + SingleOrderSL*PipValue*Point;
      TP = price - SingleOrderTP*PipValue*Point;
      pMode=4;
      pprice=hv;
      //pSL= pprice - natr*Point;
      pSL= hv - SingleOrderSL*PipValue*Point;
      pTP= hv + MathAbs(pprice-price);
      if(AutoSL)
        {
         SL=hv;
        }
      ColorSet=Red;
     }
   if(Mode==0)
     {
      price=NormalizeDouble(Ask,NDigits);
      SL = price - SingleOrderSL*PipValue*Point;
      TP = price + SingleOrderTP*PipValue*Point;
      pMode=5;
      pprice=lv;
      //pSL= pprice + natr*Point;
      pSL= lv + SingleOrderSL*PipValue*Point;
      pTP= lv - MathAbs(price-pprice);
      if(AutoSL)
        {
         SL=lv;
        }
      ColorSet=Blue;
     }
   if(SingleOrderSL == 0) {SL = 0; pSL=0;}
   if(SingleOrderTP == 0) {TP = 0; }
   while(!IsTradeAllowed()) Sleep(100);
   int ticket=OrderSend(Symbol(),Mode,MarketLot,price,SlippageOrder,SL,TP,EAName,Magic,0,ColorSet);

   if(ZhengDang)
      int ticket2=OrderSend(Symbol(),pMode,MarketLot*LotFactor,pprice,SlippageOrder,pSL,pTP,EAName,Magic,0,ColorSet);
//Print("MarketLot: "+DoubleToStr(MarketLot,2));
   if(ticket==-1)
     {
      Print("OrderSend() error - ",ErrorDescription(GetLastError()));
     }
  }
//*******************************************************************************************************
// -------------------------------------------------
// TrailOrderStop()
// -------------------------------------------------
void TrailOrderStop(string symbol)
  {
   if(TrailingStop==0) return;
   int direction;
   double trail_val,old_stopv,new_stopv,gap_price,gap_stops;
   double digits= MarketInfo(symbol,MODE_DIGITS);
   double point = MarketInfo(symbol,MODE_POINT);

   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==symbol && OrderMagicNumber()==Magic)
           {
            direction=(1-2 *(OrderType()%2));

            trail_val = NormalizeDouble(TrailingStop * point * direction, digits);
            old_stopv = NormalizeDouble(iif(direction>0 || OrderStopLoss()!=0, OrderStopLoss(), 999999), digits);
            new_stopv = NormalizeDouble(PriceClose(direction,symbol) - trail_val, digits);
            gap_price = NormalizeDouble(new_stopv - OrderOpenPrice(), digits);
            gap_stops = NormalizeDouble(new_stopv - old_stopv, digits);

            //double new_takep = NormalizeDouble(OrderTakeProfit(), Digits);
            //double gap_tp_sl = NormalizeDouble(new_takep - new_stopv, Digits);

            if(gap_price*direction>StartTrailStop*point && gap_stops*direction>=point && (OrderProfit()+OrderCommission()+OrderSwap()>1))
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),new_stopv,OrderTakeProfit(),0);
              }
           }
        }
  }
//+------------------------------------------------------------------+

double LotsSize(string symbol)
  {
   double lot=Lots;
   if(!AutoLotSize) return(lot);
   lot=AccountFreeMargin()/100000*AccountLeverage()*Risk/100.0;
   if(lot>MarketInfo(symbol,MODE_MAXLOT))
      lot=MarketInfo(symbol,MODE_MAXLOT);
   return(NormalizeDouble(lot,2));
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
//+------------------------------------------------------------------+

void DeletePendingOrder(int Mode)
  {
   while(!IsTradeAllowed()) Sleep(100);
   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderType()==Mode && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
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
//|                                                                  |
//+------------------------------------------------------------------+
void MMProtect()
  {
   double totalProfits=0;
   double drawdown=0;
   for(int i=0;i<OrdersTotal();i++)
     {
     OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()==Magic && OrderComment()==EAName && OrderSymbol()==Symbol())
        {
         totalProfits+=OrderProfit()+OrderCommission()+OrderSwap();
        }
     }
   if(totalProfits<0)
     {
      drawdown=-totalProfits/AccountBalance()*100.0;
      Comment("\ndn:  "+DoubleToStr(drawdown,2));
      if(drawdown>MaxDN)
        {
         for(int j=0;j<2;j++)
           {
            CloseAllOrders();
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders()
  {
   bool res;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<2 && OrderMagicNumber()==Magic && Magic!=0)
         res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),5,clrNONE);
      if(OrderType()<2 && Magic==0)
         res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),5,clrNONE);
      if(OrderType()>=2)
         res=OrderDelete(OrderTicket());
     }
  }
//+------------------------------------------------------------------+
