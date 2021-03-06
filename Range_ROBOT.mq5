//+----------------------------------------------+
//| Trading algorithms                           |
//+----------------------------------------------+ 
#include <Trade/Trade.mqh> 
#include <Trade/SymbolInfo.mqh> 
//+----------------------------------------------+
//| Input parameters of the EA                   |
//+----------------------------------------------+
input string                        EAComment             = "Range ROBOT";// EA Comment
input int                           LotSize               = 1;            // Lot Size
input int                           TakeProfit            = 50;           // Take Profit (in points)
input int                           Magic                 = 1;            // Magic number
      int                           MaxOpenOrders         = 1;            // Max. Open Orders
input string                        Moving Average        = "====< MA >====";//___________Moving Average
input int                           Fast_MA               = 3;            // Period 
input int                           Shift_MA              = 3;            // Shift
input ENUM_MA_METHOD                MA_Method             = MODE_SMA;     // Method
input ENUM_APPLIED_PRICE            Price                 = PRICE_CLOSE;  // Apply to 
input string inicio="09:00"; //Horario de inicio(entradas);
input string termino="16:00"; //Horario de termino(entradas);
input string fechamento="16:10"; //Horario de fechamento(entradas);
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+----------------------------------------------+
//--- declaration of integer variables for the indicators handles
string   gvp;
double   priceb=0,pricec=0;
bool     Buy=0,Sell=0,Buy2=0,Sell2=0;
int      Pip=1,Slippage=1000,InpInd_MA; 
datetime ctmt[1],tbuy,tsell,ctmt2[1],otimeB,otimeS;

MqlDateTime horario_inicio,horario_termino,horario_fechamento,horario_atual;
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   TimeToStruct(StringToTime(inicio),horario_inicio);         //+-------------------------------------+
   TimeToStruct(StringToTime(termino),horario_termino);       //| Conversão das variaveis para mql    |
   TimeToStruct(StringToTime(fechamento),horario_fechamento); //+-------------------------------------+
   
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
      if(Buy && ClosedBar() && Positions(-1) < MaxOpenOrders && Orders(4) < MaxOpenOrders && HorarioEntrada())
        {    
         priceb = NormalizeDouble(iHigh(_Symbol,0,1),_Digits);     
         if(tbuy < ctmt[0] && priceb+1 > 0 && Ask < priceb)
           { 
            MarketOrder(_Symbol, POSITION_TYPE_BUY, LotSize, priceb+0.5, 0, TakeProfit, Magic, Slippage, EAComment); otimeB=iTime(NULL,0,0); tbuy=ctmt[0];
           }      
        }    
   //---- Getting sell signals
      if(Sell && ClosedBar() && Positions(-1) < MaxOpenOrders && Orders(5) < MaxOpenOrders && HorarioEntrada())
        {
         pricec = NormalizeDouble(iLow(_Symbol,0,1),_Digits);
         if(tsell < ctmt2[0] && pricec-1 > 0 && Bid > pricec)
           {
            MarketOrder(_Symbol, POSITION_TYPE_SELL, LotSize, pricec-0.5, 0, TakeProfit, Magic, Slippage, EAComment); otimeS=iTime(NULL,0,0); tsell=ctmt2[0];
           }
        }
        
        
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


void CancelOrders() {
  
  CTrade mytrade;
  int o_total = OrdersTotal();

  for(int j=o_total-1; j>=0; j--) {

    ulong o_ticket = OrderGetTicket(j);
    string sym     = OrderGetString(ORDER_SYMBOL);

    if( o_ticket!=0 && sym == _Symbol ) {   // delete the pending order

      mytrade.OrderDelete(o_ticket);

      Print(_Symbol," Pending order ",o_ticket," deleted sucessfully!");
    }
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
   int lot=LotSize; 
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
  
bool HorarioEntrada()
      {
       TimeToStruct(TimeCurrent(),horario_atual);

      if(horario_atual.hour >= horario_inicio.hour && horario_atual.hour <= horario_termino.hour)
   {
      // Hora atual igual a de início
      if(horario_atual.hour == horario_inicio.hour)
         // Se minuto atual maior ou igual ao de início => está no horário de entradas
         if(horario_atual.min >= horario_inicio.min)
            return true;
         // Do contrário não está no horário de entradas
         else
            return false;
      
      // Hora atual igual a de término
      if(horario_atual.hour == horario_termino.hour)
         // Se minuto atual menor ou igual ao de término => está no horário de entradas
         if(horario_atual.min <= horario_termino.min)
            return true;
         // Do contrário não está no horário de entradas
         else
            return false;
      
      // Hora atual maior que a de início e menor que a de término
      return true;
   }
   
   // Hora fora do horário de entradas
   return false;
}


bool HorarioFechamento()
     {
      TimeToStruct(TimeCurrent(),horario_atual);
      
     
     // Hora dentro do horário de fechamento
   if(horario_atual.hour >= horario_fechamento.hour)
   {
      // Hora atual igual a de fechamento
      if(horario_atual.hour == horario_fechamento.hour)
         // Se minuto atual maior ou igual ao de fechamento => está no horário de fechamento
         if(horario_atual.min >= horario_fechamento.min)
            return true;
         // Do contrário não está no horário de fechamento
         else
            return false;
      
      // Hora atual maior que a de fechamento
      return true;
   }
   
   // Hora fora do horário de fechamento
   return false;
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
//+------------------------------------------------------------------+
//| ВОЗВРАЩАЕТ ОПИСАНИЕ ОШИБКИ                                       |
//+------------------------------------------------------------------+
string ErrorDescription(int error_code)
  {
   string error_string="";
//---
   switch(error_code)
     {
      //--- Коды возврата торгового сервера

      case 10004: error_string="Реквота";                                                         break;
      case 10006: error_string="Запрос отвергнут";                                                break;
      case 10007: error_string="Запрос отменён трейдером";                                        break;
      case 10008: error_string="Ордер размещён";                                                  break;
      case 10009: error_string="Заявка выполнена";                                                break;
      case 10010: error_string="Заявка выполнена частично";                                       break;
      case 10011: error_string="Ошибка обработки запроса";                                        break;
      case 10012: error_string="Запрос отменён по истечению времени";                             break;
      case 10013: error_string="Неправильный запрос";                                             break;
      case 10014: error_string="Неправильный объём в запросе";                                    break;
      case 10015: error_string="Неправильная цена в запросе";                                     break;
      case 10016: error_string="Неправильные стопы в запросе";                                    break;
      case 10017: error_string="Торговля запрещена";                                              break;
      case 10018: error_string="Рынок закрыт";                                                    break;
      case 10019: error_string="Нет достаточных денежных средств";                                break;
      case 10020: error_string="Цены изменились";                                                 break;
      case 10021: error_string="Отсутствуют котировки для обработки запроса";                     break;
      case 10022: error_string="Неверная дата истечения ордера в запросе";                        break;
      case 10023: error_string="Состояние ордера изменилось";                                     break;
      case 10024: error_string="Слишком частые запросы";                                          break;
      case 10025: error_string="В запросе нет изменений";                                         break;
      case 10026: error_string="Автотрейдинг запрещён трейдером";                                 break;
      case 10027: error_string="Автотрейдинг запрещён клиентским терминалом";                     break;
      case 10028: error_string="Запрос заблокирован для обработки";                               break;
      case 10029: error_string="Ордер или позиция заморожены";                                    break;
      case 10030: error_string="Указан неподдерживаемый тип исполнения ордера по остатку";        break;
      case 10031: error_string="Нет соединения с торговым сервером";                              break;
      case 10032: error_string="Операция разрешена только для реальных счетов";                   break;
      case 10033: error_string="Достигнут лимит на количество отложенных ордеров";                break;
      case 10034: error_string="Достигнут лимит на объём ордеров и позиций для данного символа";  break;

      //--- Ошибки времени выполнения

      case 0:  // Операция выполнена успешно
      case 4001: error_string="Неожиданная внутренняя ошибка";                                                                                                   break;
      case 4002: error_string="Ошибочный параметр при внутреннем вызове функции клиентского терминала";                                                          break;
      case 4003: error_string="Ошибочный параметр при вызове системной функции";                                                                                 break;
      case 4004: error_string="Недостаточно памяти для выполнения системной функции";                                                                            break;
      case 4005: error_string="Структура содержит объекты строк и/или динамических массивов и/или структуры с такими объектами и/или классы";                    break;
      case 4006: error_string="Массив неподходящего типа, неподходящего размера или испорченный объект динамического массива";                                   break;
      case 4007: error_string="Недостаточно памяти для перераспределения массива либо попытка изменения размера статического массива";                           break;
      case 4008: error_string="Недостаточно памяти для перераспределения строки";                                                                                break;
      case 4009: error_string="Неинициализированная строка";                                                                                                     break;
      case 4010: error_string="Неправильное значение даты и/или времени";                                                                                        break;
      case 4011: error_string="Запрашиваемый размер массива превышает 2 гигабайта";                                                                              break;
      case 4012: error_string="Ошибочный указатель";                                                                                                             break;
      case 4013: error_string="Ошибочный тип указателя";                                                                                                         break;
      case 4014: error_string="Системная функция не разрешена для вызова";                                                                                       break;
      //-- Графики
      case 4101: error_string="Ошибочный идентификатор графика";                                                                                                 break;
      case 4102: error_string="График не отвечает";                                                                                                              break;
      case 4103: error_string="График не найден";                                                                                                                break;
      case 4104: error_string="У графика нет эксперта, который мог бы обработать событие";                                                                       break;
      case 4105: error_string="Ошибка открытия графика";                                                                                                         break;
      case 4106: error_string="Ошибка при изменении для графика символа и периода";                                                                              break;
      case 4107: error_string="Ошибочный параметр для таймера";                                                                                                  break;
      case 4108: error_string="Ошибка при создании таймера";                                                                                                     break;
      case 4109: error_string="Ошибочный идентификатор свойства графика";                                                                                        break;
      case 4110: error_string="Ошибка при создании скриншота";                                                                                                   break;
      case 4111: error_string="Ошибка навигации по графику";                                                                                                     break;
      case 4112: error_string="Ошибка при применении шаблона";                                                                                                   break;
      case 4113: error_string="Подокно, содержащее указанный индикатор, не найдено";                                                                             break;
      case 4114: error_string="Ошибка при добавлении индикатора на график";                                                                                      break;
      case 4115: error_string="Ошибка при удалении индикатора с графика";                                                                                        break;
      case 4116: error_string="Индикатор не найден на указанном графике";                                                                                        break;
      //-- Графические объекты
      case 4201: error_string="Ошибка при работе с графическим объектом";                                                                                        break;
      case 4202: error_string="Графический объект не найден";                                                                                                    break;
      case 4203: error_string="Ошибочный идентификатор свойства графического объекта";                                                                           break;
      case 4204: error_string="Невозможно получить дату, соответствующую значению";                                                                              break;
      case 4205: error_string="Невозможно получить значение, соответствующее дате";                                                                              break;
      //-- MarketInfo
      case 4301: error_string="Неизвестный символ";                                                                                                              break;
      case 4302: error_string="Символ не выбран в MarketWatch";                                                                                                  break;
      case 4303: error_string="Ошибочный идентификатор свойства символа";                                                                                        break;
      case 4304: error_string="Время последнего тика неизвестно (тиков не было)";                                                                                break;
      //-- Доступ к истории
      case 4401: error_string="Запрашиваемая история не найдена!";                                                                                               break;
      case 4402: error_string="Ошибочный идентификатор свойства истории";                                                                                        break;
      //-- Global_Variables
      case 4501: error_string="Глобальная переменная клиентского терминала не найдена";                                                                          break;
      case 4502: error_string="Глобальная переменная клиентского терминала с таким именем уже существует";                                                       break;
      case 4510: error_string="Не удалось отправить письмо";                                                                                                     break;
      case 4511: error_string="Не удалось воспроизвести звук";                                                                                                   break;
      case 4512: error_string="Ошибочный идентификатор свойства программы";                                                                                      break;
      case 4513: error_string="Ошибочный идентификатор свойства терминала";                                                                                      break;
      case 4514: error_string="Не удалось отправить файл по ftp";                                                                                                break;
      //-- Буфера пользовательских индикаторов
      case 4601: error_string="Недостаточно памяти для распределения индикаторных буферов";                                                                      break;
      case 4602: error_string="Ошибочный индекс своего индикаторного буфера";                                                                                    break;
      //-- Свойства пользовательских индикаторов
      case 4603: error_string="Ошибочный идентификатор свойства пользовательского индикатора";                                                                   break;
      //-- Account
      case 4701: error_string="Ошибочный идентификатор свойства счета";                                                                                          break;
      case 4751: error_string="Ошибочный идентификатор свойства торговли";                                                                                       break;
      case 4752: error_string="Торговля для эксперта запрещена";                                                                                                 break;
      case 4753: error_string="Позиция не найдена";                                                                                                              break;
      case 4754: error_string="Ордер не найден";                                                                                                                 break;
      case 4755: error_string="Сделка не найдена";                                                                                                               break;
      case 4756: error_string="Не удалось отправить торговый запрос";                                                                                            break;
      //-- Индикаторы
      case 4801: error_string="Неизвестный символ";                                                                                                              break;
      case 4802: error_string="Индикатор не может быть создан";                                                                                                  break;
      case 4803: error_string="Недостаточно памяти для добавления индикатора";                                                                                   break;
      case 4804: error_string="Индикатор не может быть применен к другому индикатору";                                                                           break;
      case 4805: error_string="Ошибка при добавлении индикатора";                                                                                                break;
      case 4806: error_string="Запрошенные данные не найдены";                                                                                                   break;
      case 4807: error_string="Ошибочный хэндл индикатора";                                                                                                      break;
      case 4808: error_string="Неправильное количество параметров при создании индикатора";                                                                      break;
      case 4809: error_string="Отсутствуют параметры при создании индикатора";                                                                                   break;
      case 4810: error_string="Первым параметром в массиве должно быть имя пользовательского индикатора";                                                        break;
      case 4811: error_string="Неправильный тип параметра в массиве при создании индикатора";                                                                    break;
      case 4812: error_string="Ошибочный индекс запрашиваемого индикаторного буфера";                                                                            break;
      //-- Стакан цен
      case 4901: error_string="Стакан цен не может быть добавлен";                                                                                               break;
      case 4902: error_string="Стакан цен не может быть удален";                                                                                                 break;
      case 4903: error_string="Данные стакана цен не могут быть получены";                                                                                       break;
      case 4904: error_string="Ошибка при подписке на получение новых данных стакана цен";                                                                       break;
      //-- Файловые операции
      case 5001: error_string="Не может быть открыто одновременно более 64 файлов";                                                                              break;
      case 5002: error_string="Недопустимое имя файла";                                                                                                          break;
      case 5003: error_string="Слишком длинное имя файла";                                                                                                       break;
      case 5004: error_string="Ошибка открытия файла";                                                                                                           break;
      case 5005: error_string="Недостаточно памяти для кеша чтения";                                                                                             break;
      case 5006: error_string="Ошибка удаления файла";                                                                                                           break;
      case 5007: error_string="Файл с таким хэндлом уже был закрыт, либо не открывался вообще";                                                                  break;
      case 5008: error_string="Ошибочный хэндл файла";                                                                                                           break;
      case 5009: error_string="Файл должен быть открыт для записи";                                                                                              break;
      case 5010: error_string="Файл должен быть открыт для чтения";                                                                                              break;
      case 5011: error_string="Файл должен быть открыт как бинарный";                                                                                            break;
      case 5012: error_string="Файл должен быть открыт как текстовый";                                                                                           break;
      case 5013: error_string="Файл должен быть открыт как текстовый или CSV";                                                                                   break;
      case 5014: error_string="Файл должен быть открыт как CSV";                                                                                                 break;
      case 5015: error_string="Ошибка чтения файла";                                                                                                             break;
      case 5016: error_string="Должен быть указан размер строки, так как файл открыт как бинарный";                                                              break;
      case 5017: error_string="Для строковых массивов должен быть текстовый файл, для остальных – бинарный";                                                     break;
      case 5018: error_string="Это не файл, а директория";                                                                                                       break;
      case 5019: error_string="Файл не существует";                                                                                                              break;
      case 5020: error_string="Файл не может быть переписан";                                                                                                    break;
      case 5021: error_string="Ошибочное имя директории";                                                                                                        break;
      case 5022: error_string="Директория не существует";                                                                                                        break;
      case 5023: error_string="Это файл, а не директория";                                                                                                       break;
      case 5024: error_string="Директория не может быть удалена";                                                                                                break;
      case 5025: error_string="Не удалось очистить директорию (возможно, один или несколько файлов заблокированы и операция удаления не удалась)";               break;
      //-- Преобразование строк
      case 5030: error_string="В строке нет даты";                                                                                                               break;
      case 5031: error_string="В строке ошибочная дата";                                                                                                         break;
      case 5032: error_string="В строке ошибочное время";                                                                                                        break;
      case 5033: error_string="Ошибка преобразования строки в дату";                                                                                             break;
      case 5034: error_string="Недостаточно памяти для строки";                                                                                                  break;
      case 5035: error_string="Длина строки меньше, чем ожидалось";                                                                                              break;
      case 5036: error_string="Слишком большое число, больше, чем ULONG_MAX";                                                                                    break;
      case 5037: error_string="Ошибочная форматная строка";                                                                                                      break;
      case 5038: error_string="Форматных спецификаторов больше, чем параметров";                                                                                 break;
      case 5039: error_string="Параметров больше, чем форматных спецификаторов";                                                                                 break;
      case 5040: error_string="Испорченный параметр типа string";                                                                                                break;
      case 5041: error_string="Позиция за пределами строки";                                                                                                     break;
      case 5042: error_string="К концу строки добавлен 0, бесполезная операция";                                                                                 break;
      case 5043: error_string="Неизвестный тип данных при конвертации в строку";                                                                                 break;
      case 5044: error_string="Испорченный объект строки";                                                                                                       break;
      //-- Работа с массивами
      case 5050: error_string="Копирование несовместимых массивов. Строковый массив может быть скопирован только в строковый, а числовой массив – в числовой";   break;
      case 5051: error_string="Приемный массив объявлен как AS_SERIES, и он недостаточного размера";                                                             break;
      case 5052: error_string="Слишком маленький массив, стартовая позиция за пределами массива";                                                                break;
      case 5053: error_string="Массив нулевой длины";                                                                                                            break;
      case 5054: error_string="Должен быть числовой массив";                                                                                                     break;
      case 5055: error_string="Должен быть одномерный массив";                                                                                                   break;
      case 5056: error_string="Таймсерия не может быть использована";                                                                                            break;
      case 5057: error_string="Должен быть массив типа double";                                                                                                  break;
      case 5058: error_string="Должен быть массив типа float";                                                                                                   break;
      case 5059: error_string="Должен быть массив типа long";                                                                                                    break;
      case 5060: error_string="Должен быть массив типа int";                                                                                                     break;
      case 5061: error_string="Должен быть массив типа short";                                                                                                   break;
      case 5062: error_string="Должен быть массив типа char";                                                                                                    break;
      //-- Пользовательские ошибки

      default: error_string="Ошибка не определена";
     }
//---
   return(error_string);
  }
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
