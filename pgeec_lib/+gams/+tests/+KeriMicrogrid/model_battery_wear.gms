$Title Modelo de otimizacao de day-ahead de MR inteligente (MICROGRID, SEQ=1)

* See last line
*$set matout "'matsol.gdx', soc, Cb, z ";

*____________________________TIME DISCRETIZATION________________________________
SET
	t enumeration with the time-discretization periods
;

PARAMETERS
	dt(t) duration of each discretization period in hours (e.g. 30min: dt=0.5)
;
*____________________________TIME DISCRETIZATION________________________________

*__________________________BATTERY SETTINGS_____________________________________
PARAMETERS
	batCount battery quantity,
	batSize  capacity (per battery) [kWh],
	batPrice battery total cost (per battery),
	soc_max  maximum state of charge [0 1],
	soc_min  minimum state of charge [0 1],
	soc_ini  initial state of charge [0 1],
	soc_fin  ending  state of charge [0 1],
	psmax    maximum rate of discharge [kW],
	psmin    maximum rate of charge [kW],
	nf	 rate of self discharge [% per hour],
	a0	 curve fit coefficient [ACC(dod) = a0*dod^-a1],
	a1	 curve fit coefficient [ACC(dod) = a0*dod^-a1],
        disEffic discharge efficiency (ACpower÷BATpower),
        chaEffic charge efficiency (BATpower÷ACpower)
;

*__________________________BATTERY SETTINGS_____________________________________

*______________________BATTERY WEAR MODEL SETTINGS______________________________
*The goal of this section is to define the relationships used on the 2D linea-
*rization of the battery wear cost-function.
*This section should be independent of the rest of the file.
SETS
*SETS
        k            indices of the SOC values (X axis),
*used uppercase L to diferentiate from the number 1
        L            indices of the DOD values (Y axis),
        m            indices of the grid diagonals
;

*NOTE ABOUT THE DISCRETIZATION PARAMETERS:
*1) It's better if you have a DOD=0 discretization point. That is advisable
*   for intervals where the EMS doesn't want to (dis)charge the battery (DOD=0)
*2) Remember that DOD can be either positive or negative
*3) Remember that SOC can only be positive
*4) Remember to check if the discretization points contain SOC_max|min
PARAMETERS
        socData(k) discretization points of SOC (X array),
        dodData(L) discretization points of DOD (Y array)
;
*______________________BATTERY WEAR MODEL SETTINGS______________________________


*________________________DIESEL GENERATOR SETTINGS______________________________
PARAMETERS
	DG_startup_cost diesel generator startup cost,
	diesel_cost	diesel cost (R$ per litre),
	Pi_nominal	nominal generator power [kWh]
;
*________________________DIESEL GENERATOR SETTINGS______________________________

*_________________________DIESEL GENERATOR COST MODEL SETTINGS__________________
PARAMETERS
	a fuel consumption modeling parameter [c = a×Pi² + b×Pi + c],
	b fuel consumption modeling parameter [c = a×Pi² + b×Pi + c],
	c fuel consumption modeling parameter [c = a×Pi² + b×Pi + c]
;
*_________________________DIESEL GENERATOR COST MODEL SETTINGS__________________

*_____________________________MICROGRID NET LOAD________________________________
PARAMETERS
	net_load(t) net load (total load - solar generation)
*_____________________________MICROGRID NET LOAD________________________________

*___________________________TIME-DEPENDENT CONSTRAINTS__________________________
SETS
	tdia / semana, fimsemana /,
	thora / ponta, foraponta /,
	tp_dia(tdia) / semana /,
	map_th(t, thora)
;

PARAMETERS demandas_contratadas(thora) demanda contratada em kW para cada posto horário;
*___________________________TIME-DEPENDENT CONSTRAINTS__________________________

*____________________________LOAD MATLAB DATA___________________________________
$include loader.gms
*____________________________LOAD MATLAB DATA___________________________________

*__________________________BATTERY BEHAVIOR_____________________________________
PARAMETERS
        iniBat(t) array used in the equations,
        nft(t)    taxa de manutencao de carga para cada periodo t
;
iniBat(t) = soc_ini $ (ORD(t) = 1);
nft(t) = (1-nf)** dt(t);
*__________________________BATTERY BEHAVIOR_____________________________________


*_____________________BATTERY WEAR MODEL LINEARIZATION__________________________
*The goal of this section is to define the relationships used on the 2D linea-
*rization of the battery wear cost-function.
*This section should be independent of the rest of the file.
PARAMETERS
	cbData(k, L) discretization points of the cost function (Z array);

SETS
	map2D(k, L, m) choice of the diagonal points;

ABORT$(CARD(m) <> CARD(k) + CARD(L) - 1) "###### SET m HAS WRONG SIZE ######";
map2D(k, L, m) $ (ORD(L) = ORD(k) + ORD(m) - CARD(k)) = YES;

*for the infeasible points, set it to a very high value
cbData(k, L) = 1000;
*with all the parameters defined, we can now evaluate the cost function at each feasible point, populating the Z array
LOOP((k, L) $ ( (soc_min <= socData(k)) AND (soc_max >= socData(k)) AND (soc_min <= socData(k)-dodData(L)) AND (soc_max >= socData(k)-dodData(L)) AND (1-socData(k)+dodData(L) >= 0) ),
	cbData(k, L) = batCount*batPrice/(2*a0)*abs( ((1-socData(k)+dodData(L))**a1 - (1-socData(k))**a1) )
);

POSITIVE VARIABLES
	lambda(t, k, L) weights of the convex approximation,
	soc(t)          State Of Charge of the battery [0-1] at the end of the period
;

FREE VARIABLES
	dod(t) Depth Of Discharge. + for discharge. - for charge [0-1],
	Cb(t)  wear cost - function of SOC_0 and DOD
;

SOS2 VARIABLES
	delta(t, k) 2 points max per line,
	gamma(t, L) 2 points max per row,
	beta(t, m)  3 points max in total
;

EQUATIONS
	defSoc2D(t)      defines the approximated SOC - given by the convex-weighted points,
	defDod2D(t)      defines the approximated DOD - given by the convex-weighted points,
	defCb2D(t)       defines the approximated wear cost - given by the convex-weighted points,
	convexity(t)     makes the model convex,
	defDelta(t, k)   defines delta so that only 2 point are active per grid-line,
	defGamma(t, L)   defines gamma so that only 2 point are active per grid-row,
	defBeta(t, m)    defines beta so that only 3 points are active on the entire grid
;

defSoc2D(t)  .. soc(t-1)+IniBat(t) =e= SUM((k, L), lambda(t, k, L)*socData(k));
defDod2D(t)  .. dod(t) =e= SUM((k, L), lambda(t, k, L)*dodData(L));
defCb2D(t)   .. Cb(t)  =e= SUM((k, L), lambda(t, k, L)*cbData(k, L));
convexity(t) .. 1      =e= SUM((k, L), lambda(t, k, L));

defDelta(t, k) .. delta(t, k) =e= SUM(L, lambda(t, k, L));
defGamma(t, L) .. gamma(t, L) =e= SUM(k, lambda(t, k, L));
defBeta(t, m)  ..  beta(t, m) =e= SUM(map2D(k, L, m), lambda(t, k, L));
*_____________________BATTERY WEAR MODEL LINEARIZATION__________________________



*______________________BATTERY VARIABLES AND EQUATIONS__________________________
POSITIVE VARIABLES
    psc(t) charging rate [kW],
    psd(t) discharging rate [kW]
;

EQUATIONS
	defSoc(t)	defines that SOC(t) = SOC(t-1) - DOD(t),
	defDod(t)	defines that DOD(t) = Power×dt÷Capacity
	finalSoc(t)	sets the ending SOC value - had to use an equation because using .fx was yielding infeasible results
;

*OPT #1:
*defSoc(t) .. soc(t) =e= soc(t - 1)+iniBat(t) - dod(t);
*defDod(t) .. dod(t) =e= (1-nft(t))*soc(t-1) + (psd(t) - psc(t))*dt(t)/(batCount*batSize);

*OPT #2:
*defSoc(t) .. soc(t) =e= nft(t)*(soc(t - 1)+iniBat(t)) - dod(t);
*defDod(t) .. dod(t) =e= (psd(t) - psc(t))*dt(t)/(batCount*batSize);

*OPT #2: efficiency
defSoc(t) .. soc(t) =e= nft(t)*(soc(t - 1)+iniBat(t)) - dod(t);
defDod(t) .. dod(t) =e= (1/disEffic*psd(t) - chaEffic*psc(t))*dt(t)/(batCount*batSize);

finalSoc(t) .. soc(t) $ (ORD(t) = CARD(t)) =e= soc_fin $ (ORD(t) = CARD(t));
soc.lo(t) = soc_min;
soc.up(t) = soc_max;
*Battery depreciation cost is calculated automatically based on DOD and
* SOC (t) on the 2D linearization routine
*______________________BATTERY VARIABLES AND EQUATIONS__________________________


*___________________STUFF THAT I DIDN'T WRITE NOR CHANGE________________________
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

  Table tarifas_demandas(tdia, thora) multa por kW excedente
                 ponta              foraponta
  semana         28.85000             8.82000
  fimsemana      8.82000             8.82000
;

*CONDICOES INICIAIS
PARAMETER
	IniGer(t)   was the diesel generator initially on? /1 0/
;

SET i /1*6/ ;

parameter pival(i) usado na linearização da curva de consumo do gerador /
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
    rvr(t, tp_dia, thora) receita de vendas de energia para a macrorrede
    comb(t) consumo de diesel
    ci(t) custo da geracao de energia pelo gerador a diesel
*    cb(t) custo de penalizacao por uso da bateria - movido para modelagem 2D
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

  Equations
    obj       a funcao objetivo

    eqCr(t, tp_dia, thora) calculo do custo de compras da macrorrede
    eqRvr(t, tp_dia, thora) calculo da receita de vendas para a macrorrede
    eqCi(t)   calculo do custo do gerador diesel
*    eqCBat(t) calculo da penalizacao por uso da bateria

    A_1(t, tp_dia, thora) limite superior de prc de acordo com valor de bCG
    A_2(t, tp_dia, thora) limite superior de prv de acordo com valor de bVG

    B_1(t)    calculo do consumo de diesel por kWh
    B_2(t)    logica liga-desliga do gerador
    B_3(t)    funcao de normalizacao para linearizacao do consumo
    B_4(t)    equacao de pi com base no consumo
    B_5(t)    limite inferior de pi
    B_6(t)    limite superior de pi
    B_7(t)

    C_2(t)    calculo de binarios indicando inicio ou fim de descarga
    C_4(t)    limite superior de ps
    C_5(t)    limite inferior de ps
    C_6(t)    nao permite situacao absurda de inicio e fim de descarga

    D_1(t, tp_dia, thora)  balanco de potencias
;

obj .. z =e= SUM((t, tp_dia, thora)$map_th(t, thora), cr(t, tp_dia, thora) + ci(t) - rvr(t, tp_dia, thora));
eqCi(t) .. ci(t) =e= comb(t) * diesel_cost + bGerLigou(t) * DG_startup_cost;
eqCr(t, tp_dia, thora)$map_th(t, thora)  .. cr(t, tp_dia, thora) =e= (prc(t, tp_dia, thora) + prcd(t, tp_dia, thora)) * dt(t) * precos_cr_compra(tp_dia, thora) + prcd(t, tp_dia, thora) * tarifas_demandas(tp_dia, thora) * 2 + Cb(t);
eqRvr(t, tp_dia, thora)$map_th(t, thora) .. rvr(t, tp_dia, thora) =e= precos_cr_venda(tp_dia, thora) * prv(t, tp_dia, thora) * dt(t);

A_1(t, tp_dia, thora)$map_th(t, thora) .. prc(t, tp_dia, thora) =l= bCG(t, tp_dia, thora) * demandas_contratadas(thora);
A_2(t, tp_dia, thora)$map_th(t, thora) .. prv(t, tp_dia, thora) =l= (1-bCG(t, tp_dia, thora)) * demandas_contratadas(thora);

B_1(t) .. comb(t) =e= SUM(i,lam(t, i) * consumoger(i)) ;
B_2(t) .. bGerLigou(t) - bGerDesligou(t) =e= bGL(t) - bGL(t - 1) - IniGer(t);
B_3(t) .. SUM(i,lam(t, i)) =l= 1 ;
B_4(t) .. pi(t) =e= SUM(i,lam(t, i)*pival(i)) ;
B_5(t) .. pi(t) =g= bGL(t) * (.2  * Pi_nominal);
B_6(t) .. pi(t) =l= bGL(t) * Pi_nominal;
B_7(t) .. bGerLigou(t) + bGerDesligou(t) =l= 1;

C_2(t) .. bDescIni(t) - bDescFim(t) =e= bDesc(t) - bDesc(t - 1);
C_4(t) .. psd(t) =l= bDesc(t) * psmax;
C_5(t) .. psc(t) =l= (1 - bDesc(t)) * psmin;
C_6(t) .. bDescIni(t) + bDescFim(t) =l= 1;

D_1(t, tp_dia, thora)$map_th(t, thora) .. prc(t, tp_dia, thora) + prcd(t, tp_dia, thora) - prv(t, tp_dia, thora) + pi(t) + psd(t) - psc(t) =e= net_load(t);
*___________________STUFF THAT I DIDN'T WRITE NOR CHANGE________________________


*_______________________SOLVER AND MODEL CONFIGURATION__________________________
MODEL MR / ALL /;

*MR.OptFile = 1;
MR.OptCA   = 0;
*MR.OptCR   = 0;
OPTION MIP=cplex;
*OPTION limrow=50, MINLP = BONMIN;

SOLVE MR using MIP minimizing z;
*_______________________SOLVER AND MODEL CONFIGURATION__________________________

* DISPLAY map_th;

*    Export data do MATLAB - doing this directly on MATLAB via command-line call
* because it's easier to export the entire GAMS workspace at once.
*    Using the following command you would need to manually define ALL the
* variables that you want to export on the first third of the document

*EXECUTE_UNLOAD %matout%;
