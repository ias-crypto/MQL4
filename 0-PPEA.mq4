//+------------------------------------------------------------------+
//|                                                       0-PPEA.mq4 |
//|                                                   Copyright 2018 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <stdlib.mqh>


string EAName="zhang";
extern int Magic=1314;
extern double Lots=0.01;
extern bool SetLotFactor=false;
extern double LotFactor=2.3;
extern bool AutoLotSize=false;
extern double Risk=2;
extern double MaxDN=38;
//extern bool AutoSL=true;
extern double SingleOrderTP=0;
extern double SingleOrderSL=0;
extern double MoneyToClose=63;
extern double OffPrice=16;
int day=0;
double R3Val,R2Val,R1Val,PPVal,S1Val,S2Val,S3Val;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   getPPVal(R3Val,R2Val,R1Val,PPVal,S1Val,S2Val,S3Val);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(Day()!=day)
     {
      getPPVal(R3Val,R2Val,R1Val,PPVal,S1Val,S2Val,S3Val);
      day=Day();
     }
     
   MMProtect();
   CheckMarket();
  }
//+------------------------------------------------------------------+

string cusInd="PivotPointsDaily";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getPPVal(double &r3Val,double &r2Val,double &r1Val,double &ppVal,double &s1Val,double &s2Val,double &s3Val)
  {
   r3Val = iCustom(Symbol(),0,cusInd,0,0,0);
   r2Val = iCustom(Symbol(),0,cusInd,0,1,0);
   r1Val = iCustom(Symbol(),0,cusInd,0,2,0);
   ppVal = iCustom(Symbol(),0,cusInd,0,3,0);
   s1Val = iCustom(Symbol(),0,cusInd,0,4,0);
   s2Val = iCustom(Symbol(),0,cusInd,0,5,0);
   s3Val = iCustom(Symbol(),0,cusInd,0,6,0);
   //Comment("\nr1: ",DoubleToStr(r1Val,Digits),"\nr2: ",DoubleToStr(r2Val,Digits),"\npp: ",DoubleToStr(ppVal,Digits),"\ns1: ",DoubleToStr(s1Val,Digits));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckMarket()
  {
   double vlot=LotsSize(Symbol());
   double lot=0.01;
   int mode=-1;
// sell
// 1、s1<p<PP 0.01, r1<p<r2 0.01, r2<p<r3 0.02, r3<p 0.03
   if((S1Val<Bid && Bid<PPVal) || Bid>R1Val)
     {
      //if(/*diaoDingXian(1)=="上吊线" ||*/ wuYunGaiDing(1)=="乌云盖顶" || wuYunGaiDing(1)=="看跌吞没")
      if((Close[1]<Open[1] && Close[2]>Open[2] && Close[1]<Open[2] && MathAbs(Close[2]-Open[2])>20*Point)  //看跌吞没
         || (Close[1]<Open[1] && Close[2]>Open[2] && Close[1]>Open[2] && Close[1]<(Close[2]+Open[2])*0.5)  //乌云盖顶
        )  
        {
         if(Bid>R3Val) lot = vlot*5;
         if(Bid>R2Val) lot = vlot*3;
         if(Bid>R1Val) lot = vlot*2;
         if(Bid<PPVal) lot = vlot*1; 
         if((GetLastOpenPrice(OP_SELL) != 0 && MathAbs(GetLastOpenPrice(OP_BUY)-Bid)>=OffPrice*10*Point) || (OrderCounts(OP_SELL)==0))
            MarketOrder(OP_SELL,NormalizeDouble(lot,2));
        }
     }
// buy
// 1、PP<p<r1 0.01, s2<p<s1 0.01, s3<p<s2 0.02, p<s3 0.03
   if((PPVal<Ask && Ask<R1Val) || Ask<S1Val)
     {
      //if(/*diaoDingXian(1)=="锤子线" || */wuYunGaiDing(1)=="刺透" || wuYunGaiDing(1)=="看涨吞没")
      if((Close[1]>Open[1] && Close[2]<Open[2] && Close[1]>Open[2] && MathAbs(Close[2]-Open[2])>20*Point)
          || (Close[1]>Open[1] && Close[2]<Open[2] && Close[1]<Open[2] && Close[1]>(Close[2]+Open[2])*0.5)
        )
        {
         if(Ask>PPVal) lot = vlot*1;
         if(Ask<S1Val) lot = vlot*2;
         if(Ask<S2Val) lot = vlot*3;
         if(Ask<S3Val) lot = vlot*5;
         
         if((GetLastOpenPrice(OP_BUY) != 0 && MathAbs(GetLastOpenPrice(OP_BUY)-Ask)>=OffPrice*10*Point) || (OrderCounts(OP_BUY)==0))
            MarketOrder(OP_BUY,NormalizeDouble(lot,2));
        }
     }
  }

double shangYingXian(int n) { return(MathMin((High[n]-Open[n]),(High[n]-Close[n]))); }
double xiaYingXian(int n) { return(MathMin((Open[n]-Low[n]),(Close[n]-Low[n]))); }
double shiTi(int n) { return(MathAbs(Open[n]-Close[n]));}
double shiTiHalfVal(int n) {return(NormalizeDouble((Open[n]+Close[n])/2.0,Digits));}
//+------------------------------------------------------------------+

string diaoDingXian(int n)
  {
   string res="";
   if(xiaYingXian(n)>=2*shiTi(n) && shangYingXian(n)<shiTi(n) && shiTi(n)>3*Point)
     {
      if(Close[n+1]>Open[n+1] && MathMax(Open[n],Close[n])>=Close[n+1] && Low[n+1]<=Low[n])
        {
         res="上吊线";
         // DrawTradPoint(OP_SELL,n,"上吊线");
        }
      if((Close[n+1]<Open[n+1] || shangYingXian(n+1)>2*shiTi(n+1)) && MathMin(Open[n],Close[n])<=Close[n+1] && High[n+1]>=High[n])
        {
         res="锤子线";
         //DrawTradPoint(OP_BUY,n,"锤子线");
        }
     }
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string  wuYunGaiDing(int n)
  {
   string res="";
   if(Close[n+1]>Open[n+1] && shiTi(n+1)>30*Point && (MathAbs(Open[n]-Close[n+1])<=3*Point) && Close[n]<Open[n] && High[n+1]<=High[n] && shangYingXian(n)<shiTi(n))
     {
      if(Close[n]<shiTiHalfVal(n+1) && xiaYingXian(n)<shiTi(n))
        {
         res="乌云盖顶";
         // DrawTradPoint(OP_SELL,n,"乌云盖顶");
        }
      if(Close[n]<=Open[n+1] && xiaYingXian(n+1)<shiTi(n))
        {
         res="看跌吞没";
         //DrawTradPoint(OP_SELL,n,"看跌吞没");
        }
     }
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ciTou(int n)
  {
   string res="";
   if(Close[n+1]<Open[n+1] && shiTi(n+1)>30*Point && /*(MathAbs(Open[n]-Close[n+1])<=3*Point) &&*/ Close[n]>Open[n] && Low[n+1]>=Low[n] && shangYingXian(n)<shiTi(n))
     {
      if(Close[n]>shiTiHalfVal(n+1) && shangYingXian(n)<shiTi(n))
        {
         res="刺透";
         //DrawTradPoint(OP_BUY,n,"刺透");
        }

      if(Close[n]>=Open[n+1] && shangYingXian(n+1)<shiTi(n+1))
        {
         res="看涨吞没";
         //DrawTradPoint(OP_BUY,n,"看涨吞没");
        }
     }
   return res;
  }
//+------------------------------------------------------------------+
double Slippage=3;
double PipValue=1;
int ticket;
int OrderTime;
bool OrderOpen=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MarketOrder(int Mode,double MarketLot)
  {
   double price=0;
   color ColorSet=White;
   double SL=0;
   double TP=0;
   double NDigits=Digits; ///
                          //double MarketLot=NormalizeDouble((LotsSize(Symbol())/2),2);
   int SlippageOrder=3;//Slippage*PipValue;

   if(Mode==1)
     {
      price=NormalizeDouble(Bid,NDigits);
      SL = price + SingleOrderSL*PipValue*Point;
      TP = price - SingleOrderTP*PipValue*Point;
      ColorSet=Red;
     }
   if(Mode==0)
     {
      price=NormalizeDouble(Ask,NDigits);
      SL = price - SingleOrderSL*PipValue*Point;
      TP = price + SingleOrderTP*PipValue*Point;
      ColorSet=Blue;
     }
   if(SingleOrderSL == 0) {SL = 0;}
   if(SingleOrderTP == 0) {TP = 0; }
   while(!IsTradeAllowed()) Sleep(100);
   if(Time[0]!=OrderTime && Time[1]!=OrderTime) OrderOpen=false; 
   if(OrderOpen==false)
      ticket=OrderSend(Symbol(),Mode,MarketLot,price,SlippageOrder,SL,TP,EAName,Magic,0,ColorSet);
   if(ticket>0)
     {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         OrderOpen=true;
         OrderTime=Time[0];
        }
      else
        {
         Print("OrderSend() error - ",ErrorDescription(GetLastError()));
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotsSize(string symbol)
  {
   double lot=Lots;
   if(SetLotFactor) lot = Lots * LotFactor;
   if(!AutoLotSize) return(lot);
   lot=AccountFreeMargin()/100000*AccountLeverage()*Risk/1000.0/2.0;
   if(lot>MarketInfo(symbol,MODE_MAXLOT))
      lot=MarketInfo(symbol,MODE_MAXLOT);
   return(NormalizeDouble(lot,2));
  }
//+------------------------------------------------------------------+
void MMProtect()
  {
   double totalProfits=0;
   double drawdown=0;
   double MoneyThold = 0;
   
   if(SetLotFactor) MoneyThold = MoneyToClose * LotFactor * 0.5;
   else MoneyThold = MoneyToClose;
   
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
      Comment("\ndn:  "+DoubleToStr(-drawdown,2));
      if(drawdown>MaxDN)
        {
         for(int j=0;j<2;j++)
           {
            CloseAllOrders();
           }
        }
     }
   if(totalProfits>=MoneyThold)
     {
         for(int k=0;k<5;k++)
           {
            CloseAllOrders();
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
      if(OrderType()<2 && OrderMagicNumber()==Magic && OrderComment()== EAName && Magic!=0)
         res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),5,clrNONE);
      if(OrderType()<2 && Magic==0 && OrderComment()== EAName )
         res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),5,clrNONE);
      if(OrderType()>=2)
         res=OrderDelete(OrderTicket());
     }
  }
//+------------------------------------------------------------------+ 
int OrderCounts(int type)
{
   int buyOrder=0;
   int sellOrder=0;
   
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==Magic && OrderSymbol()==Symbol())
         {
            if(OrderType()==OP_BUY)  buyOrder++;
            if(OrderType()==OP_SELL) sellOrder++;
         }
        }
      }    
   switch(type)
     {
      case OP_BUY: return (buyOrder);
      break;
      case OP_SELL: return (sellOrder);
      break;
     }
   return(0);
}

double GetLastOpenPrice(int type)
{
   datetime lastOpenTime=0;
   double lastOpenPrice=0;
   
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==Magic && OrderSymbol()==Symbol() && OrderType()==type)
           {
            if(OrderOpenTime() > lastOpenTime)
              {
               lastOpenTime = OrderOpenTime();
               lastOpenPrice = OrderOpenPrice();
              }
           }
        }
     }
   return(lastOpenPrice);
}

