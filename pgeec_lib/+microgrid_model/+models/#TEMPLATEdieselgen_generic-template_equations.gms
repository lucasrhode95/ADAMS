*-------------VV Equations of MGElement #_#_ (DieselGenerator) VV-----------------

POSITIVE VARIABLES
	comb_#_(t) diesel consumption - should be implement by children classes,
	ci_#_(t)   power generation cost - should be implemented by children classes,
	pi_#_(t)   power output
;

BINARY VARIABLES
	bGL_#_(t)          1 indicates that the diesel gen is on,
	bGerLigou_#_(t)    1 indicates that the diesel gen turned on in the period t,
	bGerDesligou_#_(t) 1 indicates that the diesel gen turned off in the period t
;

EQUATIONS
	B_2_#_(t) on-off logic of the generator,
	B_5_#_(t) min power output,
	B_6_#_(t) max power output,
	B_7_#_(t) doesn't allow the generator to start and stop in the same interval
;

B_2_#_(t) .. bGerLigou_#_(t) - bGerDesligou_#_(t) =e= bGL_#_(t) - bGL_#_(t - 1) - iniGer_#_(t);
B_5_#_(t) .. pi_#_(t) =g= bGL_#_(t)*(minLoad_#_*Pi_nominal_#_);
B_6_#_(t) .. pi_#_(t) =l= bGL_#_(t)*Pi_nominal_#_;
B_7_#_(t) .. bGerLigou_#_(t) + bGerDesligou_#_(t) =l= 1;

*-------------^^ Equations of MGElement #_#_ (DieselGenerator) ^^-----------------
