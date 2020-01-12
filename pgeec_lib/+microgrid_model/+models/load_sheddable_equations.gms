*--------------VV Equations of MGElement #_#_ (LoadSheddable) VV------------------

POSITIVE VARIABLES
	netPower_#_(t)     the power input required to supply this load [kW],
	sheddingCost_#_(t) the shedding cost of this load. If the load is being fully supplied this should be zero
;

BINARY VARIABLES
	status_#_(t) status of the load: 1 = being fully supplied | 0 = turned off
;

EQUATIONS
	defNetPower_#_(t)     forces the power consumption of the load to zero when status = 0
	defSheddingCost_#_(t) adds a shedding cost when status = 0
;

defSheddingCost_#_(t) .. sheddingCost_#_(t) =e= (1-status_#_(t)) * (sheddingTariff_#_ * baseDemand_#_(t) + sheddingOpportunity_#_) * dt(t);
defNetPower_#_(t)     .. netPower_#_(t) =e= status_#_(t)*baseDemand_#_(t);

*--------------^^ Equations of MGElement #_#_ (LoadSheddable) ^^------------------
