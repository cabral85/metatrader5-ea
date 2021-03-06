//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//|                                                   TabajaraEA.mq5 |
//|                                               Denis Cabral Lopes |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Denis Cabral Lopes"
#property link      "https://www.mql5.com"
#property version   "1.00"

input int                     ma_periodo = 21;//Período da Média
input int                     ma_desloc = 0;//Deslocamento da Média
input ENUM_MA_METHOD          ma_metodo = MODE_SMA;//Método Média Móvel
input ENUM_APPLIED_PRICE      ma_preco = PRICE_CLOSE;//Preço para Média
input ulong                   offset = 5;//Desvio em Pontos
input string comment3 = "--Lote e Ganho"; //--------Lote e Ganho----------
input double                  lote = 1.0;//Volume
input string comment2 = "--Horario Funcionamento"; //--------Horário de Funcionamento----------
input string inicio="09:00"; //Horario de inicio(entradas);
input string termino="16:00"; //Horario de termino(entradas);
input string fechamento="16:10"; //Horario de fechamento(entradas);


ulong                         magicNum = 1;//Magic Number
ENUM_ORDER_TYPE_FILLING preenchimento = ORDER_FILLING_RETURN;//Preenchimento da Ordem

double                        PRC;//Preço normalizado
double                        STL;//StopLoss normalizado
double                        TKP;//TakeProfit normalizado
input double                  percentualMinimoAceito = 0.4; //Movimento minimo esperado no dia

double                        smaArray[];
int                           smaHandle;

bool                          posAberta;
bool                          ordPendente;
bool                          beAtivo;
bool                          operacoesNoDia = false;
double ZigZagBuffer[];
int    ZigZagHandle;

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
   smaHandle = iMA(_Symbol, _Period, ma_periodo, ma_desloc, ma_metodo, ma_preco);
   ZigZagHandle = iCustom(_Symbol, 0, "Examples\\ZigZag", 12, 5, 3);
   if(ZigZagHandle == INVALID_HANDLE) return(INIT_FAILED);

   if(smaHandle==INVALID_HANDLE)
     {
      Print("Erro ao criar média móvel - erro", GetLastError());
      return(INIT_FAILED);
     }

   ArraySetAsSeries(smaArray, true);
   ArraySetAsSeries(rates, true);

   trade.SetTypeFilling(preenchimento);
   trade.SetDeviationInPoints(offset);
   trade.SetExpertMagicNumber(magicNum);

   return(INIT_SUCCEEDED);
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   copyBar();
   double minDoDia = iLow(_Symbol,PERIOD_D1,0);
   double maxDoDia = iHigh(_Symbol,PERIOD_D1,0);
   double aberturaDoDia = iOpen(_Symbol, PERIOD_D1,0);
   double fechamentoDoDia = iClose(_Symbol, PERIOD_D1, 0);
   double percentualMovimento;
   double takeProfit;
   double qttPips;
   double high[];
   double lastHigh;
   double low[];
   double lastLow;
   
   CopyHigh(_Symbol, _Period, 0, 30, high);
   lastHigh = ArrayMaximum(high, 0, 10);
   
   
   CopyLow(_Symbol, _Period, 0, 30, low);
   lastLow = ArrayMaximum(low, 0, 10);

   if(!posAberta && !ordPendente && ClosedBar() && HorarioEntrada() && !operacoesNoDia)
     {
      if(aberturaDoDia < fechamentoDoDia)
        {
         if(rates[1].close > rates[2].close && rates[1].close > smaArray[1] && smaArray[1] > smaArray[2])
           {
            percentualMovimento = ((rates[1].close * 100) / minDoDia) - 100;
            if(percentualMovimento > percentualMinimoAceito)
              {
              Print(ZigZagBuffer[1]);
               qttPips = rates[1].high - minDoDia;
               takeProfit = ((qttPips * 100) / 61.8) - qttPips;
               PRC = rates[1].high;
               STL = NormalizeDouble(rates[2].low, _Digits);
               TKP = NormalizeDouble(PRC + int(takeProfit)-2, _Digits);
               if(trade.BuyLimit(lote,PRC,_Symbol,STL,TKP,ORDER_TIME_DAY))
                 {
                  operacoesNoDia = true;
                  Print("Ordem de Compra - sem falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                 }
               else
                 {
                  Print("Ordem de Compra - com falha. ResultRetcode: ", trade.ResultRetcode(), ", RetcodeDescription: ", trade.ResultRetcodeDescription());
                 }
              }
           }
        }

      if(aberturaDoDia > fechamentoDoDia)
        {
         if(rates[1].close < rates[2].close && rates[1].close < smaArray[1] && smaArray[1] < smaArray[2])
           {
            percentualMovimento = (((rates[1].close * 100) / maxDoDia)-100) * -1;
            if(percentualMovimento > percentualMinimoAceito)
              {
              Print(ZigZagBuffer[1]);
               qttPips = maxDoDia - rates[1].low;
               takeProfit = ((qttPips * 100) / 61.8) - qttPips;
               PRC = rates[1].low;
               STL = NormalizeDouble(rates[2].high, _Digits);
               TKP = NormalizeDouble(PRC - int(takeProfit)-2, _Digits);
               if(trade.SellLimit(lote,PRC,_Symbol,STL,TKP,ORDER_TIME_DAY))
                 {
                  operacoesNoDia = true;
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

   if(HorarioFechamento())
     {
      ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
      trade.PositionClose(PositionTicket);
     }
   if(HorarioFechamento())
     {
      operacoesNoDia = false;
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

   if(CopyBuffer(smaHandle, 0, 0, 3, smaArray)<0)
     {
      Alert("Erro ao copiar dados da média móvel: ", GetLastError());
      return;
     }  
     
   if(CopyBuffer(ZigZagHandle, 0, 0, 3, ZigZagBuffer) == 0) return;

   posAberta = false;
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(symbol == _Symbol)
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
      if(symbol == _Symbol)
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
