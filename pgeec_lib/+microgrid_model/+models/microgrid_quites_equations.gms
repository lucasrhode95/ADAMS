*----------------VV Equations of MGElement #_#_ (Microgrid) VV--------------------

FREE VARIABLES
	Cz(t) total operational cost at each interval
	z     MG total operational cost over the entire period
;

*VARIAVEIS INDEPENDENTES
POSITIVE VARIABLES
	prv(t, tp_dia, thora)  rate at which energy (power) is being sold to the macrogrid
	prc(t, tp_dia, thora)  rate at which energy (power) is purchased from the macrogrid
	prcd(t, tp_dia, thora) energy purchased beyond contract demand
	rvr(t, tp_dia, thora)  revenue of energy sale to the macrogrid
	cr(t, tp_dia, thora)   cost of energy purchases from macrogrid
;

BINARY VARIABLES
	bCG(t, tp_dia, thora)  1 indicates that the MG is buying power from the macrogrid
;

EQUATIONS
	defCz(t)                cost at each interval
	obj                     the objective function

	eqCr(t, tp_dia, thora)  calculation of the purchase cost from the macro network
	eqRvr(t, tp_dia, thora) calculation of the sales revenue to the macro network

	A_1(t, tp_dia, thora)   upper limit of prc according to bCG value
	A_2(t, tp_dia, thora)   upper limit of prv according to bVG value

	I_1(t, tp_dia, thora)   island mode restrictions: selling
	I_2(t, tp_dia, thora)   island mode restrictions: purchasing
	I_3(t, tp_dia, thora)   island mode restrictions: purchasing above contract

	D_1(t, tp_dia, thora)   power balance
;

* arbitrarily large value used for power import limit
I_1(t, tp_dia, thora) .. prv(t, tp_dia, thora)  =l= (1-isIsland)*1000000;
I_2(t, tp_dia, thora) .. prc(t, tp_dia, thora)  =l= (1-isIsland)*1000000;
I_3(t, tp_dia, thora) .. prcd(t, tp_dia, thora) =l= (1-isIsland)*1000000;

eqCr(t, tp_dia, thora)$map_th(t, thora)  .. cr(t, tp_dia, thora) =e= (prc(t, tp_dia, thora) + prcd(t, tp_dia, thora)) * dt(t) * precos_cr_compra(tp_dia, thora) + prcd(t, tp_dia, thora) * exceededDemandPenalty(tp_dia, thora);
eqRvr(t, tp_dia, thora)$map_th(t, thora) .. rvr(t, tp_dia, thora) =e= precos_cr_venda(tp_dia, thora) * prv(t, tp_dia, thora) * dt(t);

A_1(t, tp_dia, thora)$map_th(t, thora) .. prc(t, tp_dia, thora) =l= bCG(t, tp_dia, thora) * demandas_contratadas(thora);
A_2(t, tp_dia, thora)$map_th(t, thora) .. prv(t, tp_dia, thora) =l= (1-bCG(t, tp_dia, thora)) * demandas_contratadas(thora);

*POWER VARIABLES = prc(t, tp_dia, thora) + prcd(t, tp_dia, thora) - prv(t, tp_dia, thora) + pi(t) + psd1(t) - psc1(t) - net_load(t)
D_1(t, tp_dia, thora)$map_th(t, thora) .. #POWER_VARIABLES# =e= 0;

*COST_VARIABLES = cr(t, tp_dia, thora) - rvr(t, tp_dia, thora) + ci(t) + cb1(t)
defCz(t) .. Cz(t) =e= SUM((tp_dia, thora)$map_th(t, thora), #COST_VARIABLES#);
obj      .. z =e= SUM(t, Cz(t));

*----------------^^ Equations of MGElement #_#_ (Microgrid) ^^--------------------
