*-------------VV Equations of MGElement #_#_ (BatteryLinear) VV-------------------
EQUATIONS
	defCb_#_(t) wear cost from using the battery's energy
;

defCb_#_(t) .. Cb_#_(t) =e= unitCost_#_*(1/disEffic_#_*psd_#_(t) + chaEffic_#_*psc_#_(t))*dt(t);
*-------------^^ Equations of MGElement #_#_ (BatteryLinear) ^^-------------------
