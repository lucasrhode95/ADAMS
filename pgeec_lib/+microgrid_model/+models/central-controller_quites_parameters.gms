$Title DAY-AHEAD MICROGRID OPTIMIZATION MODEL (MICROGRID, SEQ=1)

*-------------------VV Global parameters of the simulation VV-------------------
SETS
	t enumeration with the time-discretization periods,
	tdia list of week day labels (100% chance of being variations of 'weekday' and 'weekend'),
	tp_dia(tdia) set with only one value to tell which day is that we're simulating (weekday or weekend),
	thora period labels of the hours of the day 'off-peak' - 'intermediate' or 'peak',
	map_th(t, thora) variable that maps every indice of t to a value of thora
;

PARAMETERS
	dt(t) duration of each discretization period in hours (e.g. 30min: dt=0.5),
	demandas_contratadas(thora) hired demands for each energy tariff times [any $ unit per kWh],

*PARAMETERS FOR PURCHASE/SALE OF ENERGY TO THE MACROGRID
	precos_cr_venda(tdia, thora) price of buying power from the macrogrid [any $ per kWh],
	precos_cr_compra(tdia, thora) revenue for selling power to the macrogrid [any $ unit per kWh],
	exceededDemandPenalty(tdia, thora) fine for power exceeding demand [any $ unit per kWh over the hired demand]
;
*-------------------^^ Global parameters of the simulation ^^-------------------
