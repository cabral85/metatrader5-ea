//+----------------------------------------------+
//| Trading algorithms                           |
//+----------------------------------------------+ 
#include <Trade/Trade.mqh> 
#include <Trade/SymbolInfo.mqh> 
//+----------------------------------------------+
//| Input parameters of the EA                   |
//+----------------------------------------------+
input string EAComment             = "Range ROBOT";// EA Comment
input double LotSize               = 0.1;          // Lot Size
input double TakeProfit            = 100;          // Take Profit (in points)
input int    Magic                 = 1;            // Magic number
      int    MaxOpenOrders         = 1;            // Max. Open Orders
input string Moving Average        = "====< MA >====";//___________Moving Average
input int    Fast_MA               = 3;            // Period 
input int    Shift_MA              = 3;            // Shift
input ENUM_MA_METHOD MA_Method     = MODE_EMA;     // Method
input ENUM_APPLIED_PRICE Price     = PRICE_CLOSE;  // Apply to 
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+----------------------------------------------+
//--- declaration of integer variables for the indicators handles
string   gvp;
double   priceb=0,pricec=0;
bool     Buy=0,Sell=0,Buy2=0,Sell2=0;
int      Pip=1,Slippage=1000,InpInd_MA; 
datetime ctmt[1],tbuy,tsell,ctmt2[1],otimeB,otimeS;
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- getting the handle of the iMA indicator
   InpInd_MA=iMA(_Symbol,0,Fast_MA,Shift_MA,MA_Method,Price);
   if(InpInd_MA==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the iMA indicator");
      return(INIT_FAILED);
     }
//---     
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   int digits=(int) SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   if(digits==4 || (bid<1000 && digits==2)){ Pip=1;} else Pip=10; 
//---        
   int total=(int)ChartGetInteger(1,CHART_WINDOWS_TOTAL);
   ChartIndicatorAdd(0,total,InpInd_MA);
//---      
   gvp=_Symbol+"_"+IntegerToString(Magic)+"_"+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO)gvp=gvp+"_d";
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL)gvp=gvp+"_r";
   if(MQL5InfoInteger(MQL5_TESTING))gvp=gvp+"_t"; 
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(reason==REASON_REMOVE) DeleteGV();
} 
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{	  
   double Signal[3];	
   double Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   if(CopyTime(_Symbol,0,0,1,ctmt)<0) return;
   if(CopyTime(_Symbol,0,0,1,ctmt2)<0) return;
   CopyBuffer(InpInd_MA,0,0,3,Signal);

   Buy  = (Signal[1] < iClose(NULL,0,1) && Signal[1] > iOpen(NULL,0,1));
   Sell = (Signal[1] > iClose(NULL,0,1) && Signal[1] < iOpen(NULL,0,1));
                                
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    
//---- getting buy signals
   if(Buy && ClosedBar() && Positions(-1) < MaxOpenOrders && Orders(4) < MaxOpenOrders)
     {    
      priceb = NormalizeDouble(iHigh(_Symbol,0,1),_Digits);     
      if(tbuy < ctmt[0] && priceb > 0 && Ask < priceb)
        { 
         MarketOrder(_Symbol, POSITION_TYPE_BUY, LotSize, priceb, 0, TakeProfit, Magic, Slippage, EAComment); otimeB=iTime(NULL,0,0); tbuy=ctmt[0];
        }      
     }    
//---- Getting sell signals
   if(Sell && ClosedBar() && Positions(-1) < MaxOpenOrders && Orders(5) < MaxOpenOrders)
     {
      pricec = NormalizeDouble(iLow(_Symbol,0,1),_Digits);
      if(tsell < ctmt2[0] && pricec > 0 && Bid > pricec)
        {
         MarketOrder(_Symbol, POSITION_TYPE_SELL, LotSize, pricec, 0, TakeProfit, Magic, Slippage, EAComment); otimeS=iTime(NULL,0,0); tsell=ctmt2[0];
        }
     }       //Comment(iBarShift(NULL,0,OrderGetInteger(ORDER_TIME_SETUP),1));    
//---
      if(OrderGetInteger(ORDER_TYPE)==4 && iBarShift(NULL,0,OrderGetInteger(ORDER_TIME_SETUP),1) > 1)
        { 
         Delete(Symbol(),4); 
        }
      if(OrderGetInteger(ORDER_TYPE)==5 && iBarShift(NULL,0,OrderGetInteger(ORDER_TIME_SETUP),1) > 1)
        { 
         Delete(Symbol(),5);
        }
      if(iBarShift(NULL,0,OrderGetInteger(ORDER_TIME_SETUP),1) == 1 && iClose(NULL,0,0) < iLow(NULL,0,1))
        { 
         Delete(Symbol(),4);
        } 
      if(iBarShift(NULL,0,OrderGetInteger(ORDER_TIME_SETUP),1) == 1 && iClose(NULL,0,0) > iHigh(NULL,0,1))
        { 
         Delete(Symbol(),5);
        } 
}   
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double Lots()
{
   double price=0.0;
   double margin=0.0;
   double lot=LotSize; 
//--- select lot size
   if(!SymbolInfoDouble(_Symbol,SYMBOL_ASK,price))
      return(0.0);
   if(!OrderCalcMargin(ORDER_TYPE_BUY,_Symbol,1.0,price,margin))
      return(0.0);
   if(margin<=0.0)
      return(0.0);
//--- calculate number of losses orders without a break
   double stepvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   lot=stepvol*NormalizeDouble(lot/stepvol,0);

   double minvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(lot<minvol)
      lot=minvol;

   double maxvol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  } 
//+------------------------------------------------------------------+
double RoundLot(const string sSymbol, const double fLot)
{
	double fMinLot  = SymbolInfoDouble(sSymbol, SYMBOL_VOLUME_MIN);
	double fMaxLot  = SymbolInfoDouble(sSymbol, SYMBOL_VOLUME_MAX);
	double fLotStep = SymbolInfoDouble(sSymbol, SYMBOL_VOLUME_STEP);
	
	int nLotDigits = (int) StringToInteger(DoubleToString(MathAbs(MathLog(fLotStep)/MathLog(10)), 0));
	
	double fRoundedLot = MathFloor(fLot/fLotStep + 0.5) * fLotStep;
	
	fRoundedLot = NormalizeDouble(fRoundedLot, nLotDigits);
	
	if(fRoundedLot < fMinLot)
		fRoundedLot = fMinLot;
		
	if(fRoundedLot > fMaxLot)
		fRoundedLot = fMaxLot;
	
	return(fRoundedLot);
}  
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//+------------------------------------------------------------------+
//| Check Symbol Points                                              |
//+------------------------------------------------------------------+     
double point(string symbol=NULL)  
{  
   string sym=symbol;if(symbol==NULL) sym=_Symbol;
   double bid=SymbolInfoDouble(sym,SYMBOL_BID);
   long digits=SymbolInfoInteger(sym,SYMBOL_DIGITS);
   
   if(digits<=2) return(1); //CFD & Indexes  
   if(digits==3 && SymbolInfoInteger(sym,SYMBOL_TRADE_CALC_MODE)!=SYMBOL_CALC_MODE_FOREX) return(1); 
   if(digits==3 && SymbolInfoInteger(sym,SYMBOL_TRADE_CALC_MODE)==SYMBOL_CALC_MODE_FOREX) return(0.01); 
   if(digits==4 || digits==5) return(0.0001);
   if(StringFind(sym,"XAU")>-1 || StringFind(sym,"xau")>-1 || StringFind(sym,"GOLD")>-1) return(0.1);//Gold  
   
   return(0);
} 
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+------------------------------------------------------------------+
//| Send trade request to delete                             	      |  
//+------------------------------------------------------------------+ 
void Delete(const string sSymbol, int ty=-1)
{
	  int ot = OrdersTotal();
	  MqlTradeRequest oRequest = {0};
	  MqlTradeResult	oResult = {0};	 
   
      for(int i=0; i < ot; i++)
         { 
          ulong   Order_ticket=OrderGetTicket(i); 
          string  Order_symbol=OrderGetString(ORDER_SYMBOL);  
          ulong   magic=OrderGetInteger(ORDER_MAGIC);    
          ENUM_ORDER_TYPE eOrderType=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE); 
 
   		 if(Order_symbol == sSymbol && magic == Magic && (eOrderType == ty || ty < 0))
   	  	   {
             oRequest.action    = TRADE_ACTION_REMOVE;
             oRequest.magic     = Magic;
             oRequest.order     = Order_ticket;
             //--- action and return the result
             bool os = OrderSend(oRequest,oResult);
   			      Print("in function DeletePending Executed");
   		   } 
         }
}
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+------------------------------------------------------------------+
//| Get amount of Pending Orders                                     |
//+------------------------------------------------------------------+
int Orders(int type=-1)
{
	int result = 0;

	//First deal with the Orders
	int ot = OrdersTotal();
	for(int i = 0; i < ot; i++)
	   {
		  bool os = OrderSelect(OrderGetTicket(i));
		  string sym = OrderGetString(ORDER_SYMBOL);
		  ulong om = OrderGetInteger(ORDER_MAGIC);
		  ENUM_ORDER_TYPE Type = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
        string comm = OrderGetString(ORDER_COMMENT);    
		  
		  if(sym ==_Symbol && om == Magic)
		    { 
		     if(type==-1) result++;
		     if(Type == ORDER_TYPE_BUY_LIMIT && type==2) result++;
		     if(Type == ORDER_TYPE_SELL_LIMIT && type==3) result++;
		     if(Type == ORDER_TYPE_BUY_STOP && type==4) result++;	
		     if(Type == ORDER_TYPE_SELL_STOP && type==5) result++;
		    } 		
	   }
	return(result); // 0 means there are no orders/positions
} 
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
//+------------------------------------------------------------------+
//| Check for open positions                                         |
//+------------------------------------------------------------------+
int Positions(int ty=-1)
{
	 int result = 0, total=PositionsTotal(); // number of open positions   
//--- iterate over all open positions
   for(int i=0; i<total; i++)
      {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);// ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol  
      ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position 
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position 
       
      if(magic==Magic && position_symbol==_Symbol)
        {  
			   if(type == ty || ty == -1) result++;	
        }	
     }   
	 return(result); // 0 means there are no orders/positions
}  
//+------------------------------------------------------------------+
//| Disable trade in current bar(if one is already opened and closed)|
//+------------------------------------------------------------------+
bool ClosedBar()
{
   datetime ctm[1], time=0;bool yes = 1;
   
   if(CopyTime(_Symbol,0,0,1,ctm)<0) return(false); 
    
   HistorySelect(0,TimeCurrent()); 
   
   for(int x = HistoryDealsTotal()-1; x>=0; x--) 
      {
       ulong ticket = HistoryDealGetTicket(x);
       ulong type = HistoryDealGetInteger(ticket,DEAL_TYPE);
       ulong magic = HistoryDealGetInteger(ticket,DEAL_MAGIC); 
       if(HistoryDealGetString(ticket,DEAL_SYMBOL)==_Symbol)

       if(HistoryDealGetInteger(ticket,DEAL_ENTRY) == DEAL_ENTRY_IN) 
       if(magic == Magic && (type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL)) 
       time = (datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
       if(ctm[0] <= time) yes = 0; 
	    }  
  return(yes);
}
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
bool MarketOrder(const string sSymbol, const ENUM_POSITION_TYPE eType, const double fLot, const double prices, const double nSL = 0, const double nTP = 0, const ulong nMagic = 0, const uint nSlippage = 1000, const string nComment = "")
{
	bool bRetVal = false;
	
	MqlTradeRequest oRequest = {0};
	MqlTradeResult	 oResult = {0};
	
	double fPoint = SymbolInfoDouble(sSymbol, SYMBOL_POINT);
	int nDigits	= (int) SymbolInfoInteger(sSymbol, SYMBOL_DIGITS);
   if(prices == 0){
	oRequest.action		 = TRADE_ACTION_DEAL;}
   if(prices > 0){
	oRequest.action		 = TRADE_ACTION_PENDING;}	
	oRequest.symbol		 = sSymbol;
	oRequest.volume		 = fLot;
	oRequest.stoplimit	 = 0;
	oRequest.deviation	 = nSlippage; 
	oRequest.type_filling = ORDER_FILLING_RETURN;
	oRequest.type_time    = ORDER_TIME_DAY;
	
	if(eType == POSITION_TYPE_BUY && prices == 0)
	{
		oRequest.type		= ORDER_TYPE_BUY;
		oRequest.price		= NormalizeDouble(SymbolInfoDouble(sSymbol, SYMBOL_ASK), nDigits);
		oRequest.sl			= NormalizeDouble(oRequest.price - nSL * fPoint, nDigits) * (nSL > 0);
		oRequest.tp			= NormalizeDouble(oRequest.price + nTP * fPoint, nDigits) * (nTP > 0);
	}
	
	if(eType == POSITION_TYPE_SELL && prices == 0)
	{
		oRequest.type		= ORDER_TYPE_SELL;
		oRequest.price		= NormalizeDouble(SymbolInfoDouble(sSymbol, SYMBOL_BID), nDigits);
		oRequest.sl			= NormalizeDouble(oRequest.price + nSL * fPoint, nDigits) * (nSL > 0);
		oRequest.tp			= NormalizeDouble(oRequest.price - nTP * fPoint, nDigits) * (nTP > 0);
	}
	if(eType == POSITION_TYPE_BUY && prices > 0)
	{
		oRequest.type		= ORDER_TYPE_BUY_STOP;            
		oRequest.price		= NormalizeDouble(prices, nDigits);
		oRequest.sl			= NormalizeDouble(iLow(sSymbol,0,1), nDigits);
		oRequest.tp			= NormalizeDouble(oRequest.price + nTP * fPoint,nDigits) * (nTP > 0);
	}
	
	if(eType == POSITION_TYPE_SELL && prices > 0)
	{
		oRequest.type		= ORDER_TYPE_SELL_STOP;
		oRequest.price		= NormalizeDouble(prices, nDigits);
		oRequest.sl			= NormalizeDouble(iHigh(sSymbol,0,1), nDigits);
		oRequest.tp			= NormalizeDouble(oRequest.price - nTP * fPoint,nDigits) * (nTP > 0);  
	}	
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_FOK)
	{
		oRequest.type_filling = ORDER_FILLING_FOK;}
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_IOC)
	{		
		oRequest.type_filling = ORDER_FILLING_IOC;}
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==0)
	{	
		oRequest.type_filling = ORDER_FILLING_RETURN;
	}
   	//--- check filling
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)>2)
	{   	
   if(!FillingCheck(sSymbol))
      return(false);}
	oRequest.magic = nMagic;
	
	MqlTradeCheckResult oCheckResult= {0};
	
	bool bCheck = OrderCheck(oRequest, oCheckResult);

	Print("Order Check MarketOrder:",
			" OrderCheck = ",		bCheck,
			", retcode = ",		oCheckResult.retcode, 
			", balance = ",		NormalizeDouble(oCheckResult.balance, 2),
			", equity = ",			NormalizeDouble(oCheckResult.equity, 2),
			", margin = ",			NormalizeDouble(oCheckResult.margin, 2),
			", margin_free = ",	NormalizeDouble(oCheckResult.margin_free, 2),
			", margin_level = ",	NormalizeDouble(oCheckResult.margin_level, 2),
			", comment = ",		oCheckResult.comment);
	
	if(bCheck == true && oCheckResult.retcode == 0)
	{
		bool bResult = false;
		
		for(int k = 0; k < 5; k++)
		{
			bResult = OrderSend(oRequest, oResult);
			
			if(bResult == true && (oResult.retcode == TRADE_RETCODE_PLACED || oResult.retcode == TRADE_RETCODE_DONE))
				break;
			
			if(k == 4)
				break;
				
			Sleep(100);
		}
	
		Print("Order Send MarketOrder:",
				" OrderSend = ",	bResult,
				", retcode = ",	oResult.retcode, 
				", deal = ",		oResult.deal,
				", order = ",		oResult.order,
				", volume = ",		NormalizeDouble(oResult.volume, 2),
				", price = ",		NormalizeDouble(oResult.price, _Digits),
				", bid = ",			NormalizeDouble(oResult.bid, _Digits),
				", ask = ",			NormalizeDouble(oResult.ask, _Digits),
				", comment = ",	oResult.comment,
				", request_id = ",oResult.request_id);	
				
		if(oResult.retcode == TRADE_RETCODE_DONE)
			bRetVal = true;
	}
	else if(oResult.retcode == TRADE_RETCODE_NO_MONEY)
	{
		Print("Недостаточно денег для открытия позиции. Работа эксперта прекращена.");
		ExpertRemove();
	}
	
	return(bRetVal);
}
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
//| Checks and corrects type of filling policy                       |
//+------------------------------------------------------------------+
bool FillingCheck(const string symbol)
  {
   MqlTradeRequest   m_request={0};         // request data
   MqlTradeResult    m_result={0};          // result data

   ENUM_ORDER_TYPE_FILLING m_type_filling=0;
//--- get execution mode of orders by symbol
   ENUM_SYMBOL_TRADE_EXECUTION exec=(ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE);
//--- check execution mode
   if(exec==SYMBOL_TRADE_EXECUTION_REQUEST || exec==SYMBOL_TRADE_EXECUTION_INSTANT)
     {
      //--- neccessary filling type will be placed automatically
      return(true);
     }
//--- get possible filling policy types by symbol
   uint filling=(uint)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
//--- check execution mode again
   if(exec==SYMBOL_TRADE_EXECUTION_MARKET)
     {
      //--- for the MARKET execution mode
      //--- analyze order
      if(m_request.action!=TRADE_ACTION_PENDING)
        {
         //--- in case of instant execution order
         //--- if the required filling policy is supported, add it to the request
         if(m_type_filling==ORDER_FILLING_FOK && (filling & SYMBOL_FILLING_FOK)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         if(m_type_filling==ORDER_FILLING_IOC && (filling & SYMBOL_FILLING_IOC)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         //--- wrong filling policy, set error code
         m_result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
        }
      return(true);
     }
//--- EXCHANGE execution mode
   switch(m_type_filling)
     {
      case ORDER_FILLING_FOK:
         //--- analyze order
         if(m_request.action==TRADE_ACTION_PENDING)
           {
            //--- in case of pending order
            //--- add the expiration mode to the request
            if(!ExpirationCheck(symbol))
               m_request.type_time=ORDER_TIME_DAY;
            //--- stop order?
            if(m_request.type==ORDER_TYPE_BUY_STOP || m_request.type==ORDER_TYPE_SELL_STOP)
              {
               //--- in case of stop order
               //--- add the corresponding filling policy to the request
               m_request.type_filling=ORDER_FILLING_RETURN;
               return(true);
              }
            }
         //--- in case of limit order or instant execution order
         //--- if the required filling policy is supported, add it to the request
         if((filling & SYMBOL_FILLING_FOK)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         //--- wrong filling policy, set error code
         m_result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
      case ORDER_FILLING_IOC:
         //--- analyze order
         if(m_request.action==TRADE_ACTION_PENDING)
           {
            //--- in case of pending order
            //--- add the expiration mode to the request
            if(!ExpirationCheck(symbol))
               m_request.type_time=ORDER_TIME_DAY;
            //--- stop order?
            if(m_request.type==ORDER_TYPE_BUY_STOP || m_request.type==ORDER_TYPE_SELL_STOP)
              {
               //--- in case of stop order
               //--- add the corresponding filling policy to the request
               m_request.type_filling=ORDER_FILLING_RETURN;
               return(true);
              }
           }
         //--- in case of limit order or instant execution order
         //--- if the required filling policy is supported, add it to the request
         if((filling & SYMBOL_FILLING_IOC)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         //--- wrong filling policy, set error code
         m_result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
      case ORDER_FILLING_RETURN:
         //--- add filling policy to the request
         m_request.type_filling=m_type_filling;
         return(true);
     }
//--- unknown execution mode, set error code
   m_result.retcode=TRADE_RETCODE_ERROR;
   return(false);
  }
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+------------------------------------------------------------------+
//| Check expiration type of pending order                           |
//+------------------------------------------------------------------+
bool ExpirationCheck(const string symbol)
{
   CSymbolInfo sym;
   MqlTradeRequest   m_request={0};         // request data
   MqlTradeResult    m_result={0};          // result data

//--- check symbol
   if(!sym.Name((symbol==NULL)?Symbol():symbol))
      return(false);
//--- get flags
   int flags=sym.TradeTimeFlags();
//--- check type
   switch(m_request.type_time)
     {
      case ORDER_TIME_GTC:
         if((flags&SYMBOL_EXPIRATION_GTC)!=0)
            return(true);
         break;
      case ORDER_TIME_DAY:
         if((flags&SYMBOL_EXPIRATION_DAY)!=0)
            return(true);
         break;
      case ORDER_TIME_SPECIFIED:
         if((flags&SYMBOL_EXPIRATION_SPECIFIED)!=0)
            return(true);
         break;
      case ORDER_TIME_SPECIFIED_DAY:
         if((flags&SYMBOL_EXPIRATION_SPECIFIED_DAY)!=0)
            return(true);
         break;
      default:
         Print(__FUNCTION__+": Unknown expiration type");
         break;
     }
//--- failed
   return(false);
}
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
//|   Delete GlobalVariabeles with perfix gvp                        | 
//+------------------------------------------------------------------+
void DeleteGV()
{ 
   for(int i=GlobalVariablesTotal()-1;i>=0;i--)
      {
       if(StringFind(GlobalVariableName(i),gvp,0)==0)
      
       GlobalVariableDel(GlobalVariableName(i));
      } 
}   
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
//|  Global Variable Set                                             |
//+------------------------------------------------------------------+  
datetime GVSet(string name,double value)
{
   return(GlobalVariableSet(gvp+name,value));
}
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
//|  Global Variable Get                                             |
//+------------------------------------------------------------------+
double GVGet(string name)
{
   return(GlobalVariableGet(gvp+name));
}  