*----------------VV Parameters of MGElement #_#_ (Battery) VV---------------------
PARAMETERS
* SIZING
	batSize_#_  capacity [kWh],
	batPrice_#_ battery total cost (installation-maintenance-etc),

* LIMITS
	soc_max_#_  maximum state of charge [0 1],
	soc_min_#_  minimum state of charge [0 1],
	soc_ini_#_  initial state of charge [0 1],
	socFinLo_#_ minimum state of charge at the end of the simulation [0 1],
	socFinUp_#_ maximum state of charge at the end of the simulation [0 1],

        psmax_#_    maximum rate of discharge [kW],
	psmin_#_    maximum rate of charge [kW],

* EFFICIENCY
	nf_#_       rate of self discharge [% (0-1) per hour],
	disEffic_#_ discharge efficiency (ACpower÷BATpower),
	chaEffic_#_ charge efficiency (BATpower÷ACpower)
;
*----------------^^ Parameters of MGElement #_#_ (Battery) ^^---------------------
