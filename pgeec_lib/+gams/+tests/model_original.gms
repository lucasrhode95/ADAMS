$Title Modelo de otimizacao de day-ahead de MR inteligente (MICROGRID, SEQ=1)

*PARAMETROS DO MODELO DO GERADOR DIESEL (consumo)
  Scalar a parametro para modelagem do consumo /0.004446/;
  Scalar b parametro para modelagem do consumo /0.121035/;
  Scalar c parametro para modelagem do consumo /1.653882/;
  Scalar custo_startup custo de acionamento do gerador /6.8/;
  Scalar custo_comb custo de combustivel (R$ por litro) /2.9/;
  Scalar Pi_nominal potencia nominal do gerador /0.000/;

  Sets tdia / semana, fimsemana/
       thora / ponta, foraponta/
;

*PARAMETROS DE COMPRA/VENDA DA MACRORREDE
  Table precos_cr_venda(tdia, thora) precos de compra por kWh da macrorrede
                 ponta   foraponta
  semana         0.20000   0.20000
  fimsemana      0.20000   0.20000
;
  Table precos_cr_compra(tdia, thora) precos de venda por kWh para a macrorrede
                 ponta   foraponta
  semana         0.47987  0.29908
  fimsemana      0.29908  0.29908
;
  Parameter demandas_contratadas(thora) demanda contratada em kW /
  ponta          20.00000
  foraponta      24.75770
/;
  Table tarifas_demandas(tdia, thora) multa por kW excedente
                 ponta              foraponta
  semana         28.85000             8.82000
  fimsemana      8.82000             8.82000
;

*DISCRETIZACAO EM 3 NIVEIS: na primeira meia hora otimiza de 5 em 5 min (dt=.083
*                           horas), na segunda meia hora discretiza em .5 horas,
*                           e no restante das 23 horas do dia, discretiza de
*                           hora em hora (dt = 1 hora).
  Scalar dt1 duracao de intervalos na primeira meia hora em horas /.083333/;
  Scalar dt2 duracao de intervalos na segunda meia hora em horas /.5/;
  Scalar dt3 duracao de intervalos nas 23 horas restantes em horas /1/;

  set t enumeracao com os periodos de tempo dt /
    1*30
  /;

  Parameter dt(t) /
        1*6    .083333
    7      .5
    8*30   1

/;

  Set map_th(t, thora) /

1*24.foraponta
25*27.ponta
28*30.foraponta
/;

  Set tp_dia(tdia) / semana /;

*PARAMETROS PARA MODELAMENTO DA BATERIA
  Scalar batSize tamanho da bateria em kWh /2.4/;
  Scalar nf taxa de manutencao de carga da bateria a cada hora  /.998/;

  Parameter nft(t) taxa de manutencao de carga para cada periodo t;
  nft(t) = nf ** dt(t);

*LIMITES
  Scalar psmax /20.600/;
  Scalar psmin /-19.000/;
  Scalar soc_max /.8/;
  Scalar soc_min /.42/;
  Scalar nMaxCiclos numero maximo de ciclos da bateria /4/;
  Scalar Nbat /12/;

*CONDICOES INICIAIS
  Parameter IniGer(t) Gerador ja estava ligado? /1 0/ ;
  Parameter IniBat(t) Estado de carga inicial da bateria (0-1) /1 0.8/ ;

  Parameter DL(t) demanda liquida (carga - ger. solar) por periodo /
*    (kW)
1  6.56
2  6.56
3  6.27
4  6.27
5  6.44
6  6.44
7  6.57
8  6.31
9  9.81
10  15.24
11  19.94
12  20.94
13  21.60
14  23.74
15  26.08
16  25.68
17  26.16
18  28.70
19  28.13
20  28.73
21  19.83
22  19.77
23  19.97
24  17.17
25  17.44
26  24.17
27  22.92
28  21.24
29  12.42
30  8.66

  /;

  set i /1*6/ ;

  Parameter pival(i) usado na linearização da curva de consumo do gerador /
* i        pi(kW)
  1        0.0
  2        4.0
  3        7.0
  4        11.5
  5        15.0
  6        20.0
  /;

  Parameter consumoger(i) /1 0. /;
  consumoger(i)$(ord(i) > 1) = (a * pival(i) * pival(i) + b * pival(i) + c);

  variables lam(t, i);
  sos2 variables lam(t, i);

*VARIAVEIS INDEPENDENTES
  Positive Variables
    prv(t, tp_dia, thora) pot. de venda a macrorrede por kWh
    prc(t, tp_dia, thora) pot. de compra da macrorrede por kWh
    prcd(t, tp_dia, thora) pot. comprada alem da demanda contratada
    pi(t)  potencia gerada pelo gerador diesel
    soc(t) estado de carga do final do periodo
    psc(t) potencia de carga(-) ou descarga(+) do banco de baterias
    psd(t) potencia de carga(-) ou descarga(+) do banco de baterias
    rvr(t, tp_dia, thora) receita de vendas de energia para a macrorrede
    comb(t) consumo de diesel
    ci(t) custo da geracao de energia pelo gerador a diesel
    cb(t) custo de penalizacao por uso da bateria
;

  Binary variables
*   bVG(t, tp_dia, thora) 1 indica q MR esta vendendo energia para a macrorrede
    bCG(t, tp_dia, thora) 1 indica q MR esta comprando energia da macrorrede
    bGL(t)  1 indica que o gerador diesel esta ligado
    bGerLigou(t)  1 indica que o gerador ligou no periodo t
    bGerDesligou(t) 1 indica que o gerador desligou no periodo t
    bDescIni(t)  1 indica que novo ciclo de descarga foi iniciado em t
    bDescFim(t) 1 indica que um ciclo de descarga foi terminado em t
    bDesc(t)  1 indica que o banco de baterias esta descarregando em t
;

  Variables
    z custo total - resultado da funcao objetivo
    cr(t, tp_dia, thora) custo de compras de energia da macrorrede
;

  Integer Variable nCiclos(t);

*BOUNDARIES
  soc.lo(t) = soc_min;
  soc.up(t) = soc_max;
  soc.fx(t)$(ord(t) = card(t)) = soc_max;
  nCiclos.up(t) = nMaxCiclos;

  Equations
    obj       a funcao objetivo

    eqCr(t, tp_dia, thora) calculo do custo de compras da macrorrede
    eqRvr(t, tp_dia, thora) calculo da receita de vendas para a macrorrede
    eqCi(t)   calculo do custo do gerador diesel
    eqCBat(t) calculo da penalizacao por uso da bateria

    A_1(t, tp_dia, thora) limite superior de prc de acordo com valor de bCG
    A_2(t, tp_dia, thora) limite superior de prv de acordo com valor de bVG

    B_1(t)    calculo do consumo de diesel por kWh
    B_2(t)    logica liga-desliga do gerador
    B_3(t)    funcao de normalizacao para linearizacao do consumo
    B_4(t)    equacao de pi com base no consumo
    B_5(t)    limite inferior de pi
    B_6(t)    limite superior de pi
    B_7(t)

    C_1(t)    calculo do soc com base no soc anterior e ps atual
    C_2(t)    calculo de binarios indicando inicio ou fim de descarga
    C_3(t)    calculo do numero de ciclos de carga-descarga
    C_4(t)    limite superior de ps
    C_5(t)    limite inferior de ps
    C_6(t)    nao permite situacao absurda de inicio e fim de descarga

    D_1(t, tp_dia, thora)  balanco de potencias
;

  obj.. z =e= sum((t, tp_dia, thora)$map_th(t, thora), cr(t, tp_dia, thora) + ci(t) - rvr(t, tp_dia, thora));
  eqCr(t, tp_dia, thora)$map_th(t, thora).. cr(t, tp_dia, thora) =e= (prc(t, tp_dia, thora) + prcd(t, tp_dia, thora)) * dt(t) * precos_cr_compra(tp_dia, thora) + prcd(t, tp_dia, thora) * tarifas_demandas(tp_dia, thora) * 2 + cb(t);
  eqRvr(t, tp_dia, thora)$map_th(t, thora).. rvr(t, tp_dia, thora) =e= precos_cr_venda(tp_dia, thora) * prv(t, tp_dia, thora) * dt(t);
  eqCi(t).. ci(t) =e= comb(t) * custo_comb + bGerLigou(t) * custo_startup;
  eqCBat(t).. cb(t) =e= (psc(t) + psd(t)) * .01 * dt(t);

  A_1(t, tp_dia, thora)$map_th(t, thora).. prc(t, tp_dia, thora) =l= bCG(t, tp_dia, thora) * demandas_contratadas(thora);
  A_2(t, tp_dia, thora)$map_th(t, thora).. prv(t, tp_dia, thora) =l= (1-bCG(t, tp_dia, thora)) * demandas_contratadas(thora);

  B_1(t)..  comb(t) =e= sum(i,lam(t, i) * consumoger(i)) ;
  B_2(t)..  bGerLigou(t) - bGerDesligou(t) =e= bGL(t) - bGL(t - 1) - IniGer(t);
  B_3(t)..  sum(i,lam(t, i)) =l= 1 ;
  B_4(t)..  pi(t) =e= sum(i,lam(t, i)*pival(i)) ;
  B_5(t)..  pi(t) =g= bGL(t) * (.2  * Pi_nominal);
  B_6(t)..  pi(t) =l= bGL(t) * Pi_nominal;
  B_7(t)..  bGerLigou(t) + bGerDesligou(t) =l= 1;

  C_1(t)..  soc(t) =e= nft(t) * soc(t - 1) - psd(t) * dt(t) / (Nbat * batSize) + psc(t) * dt(t) / (Nbat * batSize) + IniBat(t);
  C_2(t)..  bDescIni(t) - bDescFim(t) =e= bDesc(t) - bDesc(t - 1);
  C_3(t)..  nCiclos(t) =e= nCiclos(t - 1) + bDescIni(t)+bDescFim(t);
  C_4(t)..  psd(t) =l= bDesc(t) * psmax;
  C_5(t)..  psc(t) =l= -(1 - bDesc(t)) * psmin;
  C_6(t)..  bDescIni(t) + bDescFim(t) =l= 1;

  D_1(t, tp_dia, thora)$map_th(t, thora)..  prc(t, tp_dia, thora) + prcd(t, tp_dia, thora) - prv(t, tp_dia, thora) + pi(t) + psd(t) - psc(t) =e= DL(t);

  Model MR /all/;

*MR.optfile = 1;
MR.optcr   = 0;

option limrow=50, mip=cplex;

Solve MR using mip minimizing z;

display z.l;
