//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

input string comment0 = "--Parâmetros de entrada"; //--------Média----------
input int                     ma_periodo = 20;//Período da Média
input int                     ma_desloc = 0;//Deslocamento da Média
input ENUM_MA_METHOD          ma_metodo = MODE_SMA;//Método Média Móvel
input ENUM_APPLIED_PRICE      ma_preco = PRICE_CLOSE;//Preço para Média
input ulong                   magicNum = 123456;//Magic Number
input ulong                   desvPts = 50;//Desvio em Pontos
input ENUM_ORDER_TYPE_FILLING preenchimento = ORDER_FILLING_RETURN;//Preenchimento da Ordem
input string comment3 = "--Lote e Ganho"; //--------Lote e Ganho----------
input double                  lote = 5.0;//Volume
input string comment1 = "--Gatilho TLStop"; //--------TP - Gatilhos----------
input bool                    useTraillingStop; //Usar Trailling Stop?
input double                  gatilhoBE = 2;//Gatilho BreakEven
input double                  gatilhoTS = 6;//Gatilho TrailingStop
input double                  stepTS = 2;//Step TrailingStop
input string comment2 = "--Horario Funcionamento"; //--------Horário de Funcionamento----------
input string inicio="09:00"; //Horario de inicio(entradas);
input string termino="16:00"; //Horario de termino(entradas);
input string fechamento="16:10"; //Horario de fechamento(entradas);

double                        PRC;//Preço normalizado
double                        STL;//StopLoss normalizado
double                        TKP;//TakeProfit normalizado

double                        smaArray[];
int                           smaHandle;

bool                          posAberta;
bool                          ordPendente;
bool                          beAtivo;

MqlTick                       ultimoTick;
MqlRates                      rates[];
MqlDateTime horario_inicio,horario_termino,horario_fechamento,horario_atual;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   TimeToStruct(StringToTime(inicio),horario_inicio);         //+-------------------------------------+
   TimeToStruct(StringToTime(termino),horario_termino);       //| Conversão das variaveis para mql    |
   TimeToStruct(StringToTime(fechamento),horario_fechamento);
   smaHandle = iMA(_Symbol, _Period, ma_periodo, ma_desloc, ma_metodo, ma_preco);
   if(smaHandle==INVALID_HANDLE)
     {
      Print("Erro ao criar média móvel - erro", GetLastError());
      return(INIT_FAILED);
     }
   ArraySetAsSeries(smaArray, true);
   ArraySetAsSeries(rates, true);

   trade.SetTypeFilling(preenchimento);
   trade.SetDeviationInPoints(desvPts);
   trade.SetExpertMagicNumber(magicNum);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
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

   if(CopyBuffer(smaHandle, 0, 0, 3, smaArray)<0)
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

   if(HorarioFechamento())
     {
      //CancelOrders();
     }

   if(!posAberta)
     {
      beAtivo = false;
     }

   if(posAberta && !beAtivo && useTraillingStop)
     {
      BreakEven(ultimoTick.last);
     }

   if(posAberta && beAtivo && useTraillingStop)
     {
      TrailingStop(ultimoTick.last);
     }
   double Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double takeProfit;
   double qttPips;
   double minOrMaxDoDia;
   if(rates[1].open < smaArray[1] && rates[1].close > smaArray[1] && !posAberta && !ordPendente && ClosedBar() && HorarioEntrada())
     {
      minOrMaxDoDia = iLow(_Symbol,PERIOD_D1,0);
      qttPips = rates[1].close - minOrMaxDoDia;
      takeProfit = ((qttPips * 100) / 61.8) - qttPips;
      PRC = NormalizeDouble(iHigh(_Symbol,_Period,1),_Digits);
      STL = NormalizeDouble(rates[1].low-1, _Digits);
      TKP = NormalizeDouble(PRC + int(takeProfit) -2, _Digits);
      if(Ask >= PRC)
        {
         if(trade.Buy(lote, _Symbol, PRC, STL, TKP))
           {
            Print("Ordem de Compra - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
           }
         else
           {
            Print("Ordem de Compra - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
           }
        }
     }
   else
     {
      if(rates[1].open > smaArray[1] && rates[1].close < smaArray[1] && !posAberta && !ordPendente && ClosedBar() && HorarioEntrada())
        {
         minOrMaxDoDia = iHigh(_Symbol,PERIOD_D1,0);
         qttPips = minOrMaxDoDia - rates[1].close;
         takeProfit = ((qttPips * 100) / 61.8) - qttPips;
         PRC = NormalizeDouble(iLow(_Symbol,_Period,1),_Digits);
         STL = NormalizeDouble(rates[1].high+1, _Digits);
         TKP = NormalizeDouble(PRC - int(takeProfit)-2, _Digits);
         if(Bid <= PRC)
           {
            if(trade.Sell(lote, _Symbol, PRC, STL, TKP))
              {
               Print("Ordem de Venda - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Ordem de Venda - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelOrders()
  {
   int o_total = OrdersTotal();

   for(int j=o_total-1; j>=0; j--)
     {

      ulong o_ticket = OrderGetTicket(j);
      string sym     = OrderGetString(ORDER_SYMBOL);

      if(o_ticket!=0 && sym == _Symbol)       // delete the pending order
        {

         trade.OrderDelete(o_ticket);

         Print(_Symbol," Pending order ",o_ticket," deleted sucessfully!");
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
//---
//---
void TrailingStop(double preco)
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
            if(preco >= (StopLossCorrente + gatilhoTS))
              {
               double novoSL = NormalizeDouble(StopLossCorrente + stepTS, _Digits);
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
               if(preco <= (StopLossCorrente - gatilhoTS))
                 {
                  double novoSL = NormalizeDouble(StopLossCorrente - stepTS, _Digits);
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
//---
//---

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BreakEven(double preco)
  {
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(symbol == _Symbol && magic == magicNum)
        {
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double PrecoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
         double TakeProfitCorrente = PositionGetDouble(POSITION_TP);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            if(preco >= (PrecoEntrada + gatilhoBE))
              {
               if(trade.PositionModify(PositionTicket, PrecoEntrada, TakeProfitCorrente))
                 {
                  Print("BreakEven - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                  beAtivo = true;
                 }
               else
                 {
                  Print("BreakEven - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                 }
              }
           }
         else
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               if(preco <= (PrecoEntrada - gatilhoBE))
                 {
                  if(trade.PositionModify(PositionTicket, PrecoEntrada, TakeProfitCorrente))
                    {
                     Print("BreakEven - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                     beAtivo = true;
                    }
                  else
                    {
                     Print("BreakEven - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                    }
                 }
              }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
