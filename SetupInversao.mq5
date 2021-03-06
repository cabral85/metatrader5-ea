//+------------------------------------------------------------------+
//|                                                    Setup9EMA.mq5 |
//|                                               Denis Cabral Lopes |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Denis Cabral Lopes"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

input int                     ma_periodo_longo = 21;//Período da Média
input ENUM_MA_METHOD          ma_metodo_longo = MODE_SMA;//Método Média Móvel

input int                     ma_periodo_curto = 9;//Período da Média
input ENUM_MA_METHOD          ma_metodo_curto = MODE_SMA;//Método Média Móvel

input ulong                         magicNum = 1;//Magic Number
ENUM_ORDER_TYPE_FILLING preenchimento = ORDER_FILLING_RETURN;//Preenchimento da Ordem

input ulong                   offset = 5;//Desvio em Pontos
input double                  lote = 1.0;//Volume
input string comment1 = "--Horario Funcionamento"; //--------Horário de Funcionamento----------
input string inicio="09:00"; //Horario de inicio(entradas);
input string termino="16:00"; //Horario de termino(entradas);
input string fechamento="16:10"; //Horario de fechamento(entradas);
input double                  percentualMinimoAceito = 0.02; //Movimento minimo esperado no dia
input double max_take=300; // Take profit ajustado


double                        emaLongaArray[];
int                           emaLongaHandle;

double                        emaCurtaArray[];
int                           emaCurtaHandle;

double percentualMovimento;
double   priceb=0,pricec=0;

double                        STL;//StopLoss normalizado
double                        TKP;//TakeProfit normalizado
bool                          diaComOperacao = false;


bool                          posAberta;
bool                          ordPendente;
bool                          beAtivo;
bool                          buySignal = false;
bool                          sellSignal = false;


MqlTick                       ultimoTick;
MqlRates                      rates[];
MqlDateTime horario_inicio,horario_termino,horario_fechamento,horario_atual;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   TimeToStruct(StringToTime(inicio),horario_inicio);
   TimeToStruct(StringToTime(termino),horario_termino);
   TimeToStruct(StringToTime(fechamento),horario_fechamento);
   emaLongaHandle = iMA(_Symbol, _Period, ma_periodo_longo, 0, ma_metodo_longo, PRICE_CLOSE);
   emaCurtaHandle = iMA(_Symbol, _Period, ma_periodo_curto, 0, ma_metodo_curto, PRICE_CLOSE);

   if(emaLongaHandle==INVALID_HANDLE || emaCurtaHandle==INVALID_HANDLE)
     {
      Print("Erro ao criar média móvel - erro", GetLastError());
      return(INIT_FAILED);
     }

   ArraySetAsSeries(emaLongaArray, true);
   ArraySetAsSeries(emaCurtaArray, true);
   ArraySetAsSeries(rates, true);

   trade.SetTypeFilling(preenchimento);
   trade.SetDeviationInPoints(offset);
   trade.SetExpertMagicNumber(magicNum);

   return(INIT_SUCCEEDED);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   copyBar();
   double Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   if(!ordPendente && !posAberta && HorarioEntrada() && !diaComOperacao)
     {
      percentualMovimento = ((emaLongaArray[1] * 100) / emaCurtaArray[1]) - 100;
      buySignal = rates[1].open < emaCurtaArray[1] && rates[1].open < emaLongaArray[1] && rates[1].close > emaCurtaArray[1] && rates[1].close > emaLongaArray[1];
      sellSignal = rates[1].open > emaCurtaArray[1] && rates[1].open > emaLongaArray[1] && rates[1].close < emaCurtaArray[1] && rates[1].close < emaLongaArray[1];

      if(buySignal)
        {
         priceb = NormalizeDouble(iHigh(_Symbol,0,1),_Digits);
         STL = NormalizeDouble(rates[1].low, _Digits);
         TKP = NormalizeDouble(priceb + max_take, _Digits);
         if(Ask >= priceb-1)
           {
            if(trade.Buy(lote, _Symbol, priceb, STL, TKP))
              {
               diaComOperacao = true;
               Print("Ordem de Compra - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Ordem de Compra - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
              }
           }
        }
      if(sellSignal)
        {
         pricec = NormalizeDouble(iLow(_Symbol,0,1),_Digits);
         STL = NormalizeDouble(rates[1].high, _Digits);
         TKP = NormalizeDouble(pricec - max_take, _Digits);
         if(Bid <= pricec-1)
           {
            if(trade.Sell(lote, _Symbol, pricec, STL, TKP))
              {
               diaComOperacao = true;
               Print("Ordem de Venda - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Ordem de Venda - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
              }
           }
        }
     }
   else
     {
      TrailingStop();
     }

   if(HorarioFechamento())
     {
      diaComOperacao = false;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void copyBar()
  {
   if(!SymbolInfoTick(Symbol(),ultimoTick))
     {
      Alert("Erro ao obter informações de Preços: ", GetLastError());
      return;
     }

   if(CopyRates(_Symbol, _Period, 0, 3, rates)<0)
     {
      Alert("Erro ao obter as informações de MqlRates: ", GetLastError());
      return;
     }

   if(CopyBuffer(emaLongaHandle, 0, 0, 3, emaLongaArray)<0)
     {
      Alert("Erro ao copiar dados da média móvel: ", GetLastError());
      return;
     }

   if(CopyBuffer(emaCurtaHandle, 0, 0, 3, emaCurtaArray)<0)
     {
      Alert("Erro ao copiar dados da média móvel: ", GetLastError());
      return;
     }


   posAberta = false;
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(symbol == _Symbol && magic == magicNum)
        {
         posAberta = true;
         break;
        }
     }

   ordPendente = false;
   for(int i = OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      string symbol = OrderGetString(ORDER_SYMBOL);
      ulong magic = OrderGetInteger(ORDER_MAGIC);
      if(symbol == _Symbol && magic == magicNum)
        {
         ordPendente = true;
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClosedBar()
  {
   datetime ctm[1], time=0;
   bool yes = 1;

   if(CopyTime(_Symbol,0,0,1,ctm)<0)
      return(false);

   HistorySelect(0,TimeCurrent());

   for(int x = HistoryDealsTotal()-1; x>=0; x--)
     {
      ulong ticket = HistoryDealGetTicket(x);
      ulong type = HistoryDealGetInteger(ticket,DEAL_TYPE);
      ulong magic = HistoryDealGetInteger(ticket,DEAL_MAGIC);
      if(HistoryDealGetString(ticket,DEAL_SYMBOL)==_Symbol)

         if(HistoryDealGetInteger(ticket,DEAL_ENTRY) == DEAL_ENTRY_IN)
            if(magic == magicNum && (type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL))
               time = (datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
      if(ctm[0] <= time)
         yes = 0;
     }
   return(yes);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HorarioEntrada()
  {
   TimeToStruct(TimeCurrent(),horario_atual);

   if(horario_atual.hour >= horario_inicio.hour && horario_atual.hour <= horario_termino.hour)
     {
      if(horario_atual.hour == horario_inicio.hour)
         if(horario_atual.min >= horario_inicio.min)
            return true;
         else
            return false;
      if(horario_atual.hour == horario_termino.hour)
         if(horario_atual.min <= horario_termino.min)
            return true;
         else
            return false;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HorarioFechamento()
  {
   TimeToStruct(TimeCurrent(),horario_atual);
   if(horario_atual.hour >= horario_fechamento.hour)
     {
      if(horario_atual.hour == horario_fechamento.hour)
         if(horario_atual.min >= horario_fechamento.min)
            return true;
         else
            return false;
      return true;
     }
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStop()
  {
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(symbol == _Symbol && magic==magicNum)
        {
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double StopLossCorrente = PositionGetDouble(POSITION_SL);
         double TakeProfitCorrente = PositionGetDouble(POSITION_TP);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            if(rates[1].close < emaCurtaArray[1])
              {
               double novoSL = NormalizeDouble(iLow(_Symbol,0,1),_Digits);
               if(trade.PositionModify(PositionTicket, novoSL, TakeProfitCorrente))
                 {
                  Print("TrailingStop - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                 }
               else
                 {
                  Print("TrailingStop - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                 }
              }
           }
         else
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               if(rates[1].close > emaCurtaArray[1])
                 {
                  double novoSL = NormalizeDouble(iHigh(_Symbol,0,1),_Digits);
                  if(trade.PositionModify(PositionTicket, novoSL, TakeProfitCorrente))
                    {
                     Print("TrailingStop - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                    }
                  else
                    {
                     Print("TrailingStop - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                    }
                 }
              }
        }
     }

  }
//+------------------------------------------------------------------+
