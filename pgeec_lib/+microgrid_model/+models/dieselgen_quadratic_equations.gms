*-----------VV Equations of MGElement #_#_ (DieselGenQuadratic) VV----------------

* evaluates the quadratic function at each point.
consumoger_#_(i_#_)$(ORD(i_#_) > 1) = (a_#_*pival_#_(i_#_)**2 + b_#_*pival_#_(i_#_) + c_#_);

SOS2 VARIABLES
	lam_#_(t, i_#_)
;

EQUATIONS
	eqCi_#_(t) calculo do custo do gerador diesel,

	B_1_#_(t) equacao de pi com base no consumo,
	B_3_#_(t) calculo do consumo de diesel por kWh,
	B_4_#_(t) funcao de normalizacao para linearizacao do consumo
;

eqCi_#_(t) .. ci_#_(t) =e= comb_#_(t)*diesel_cost_#_ + bGerLigou_#_(t)*DG_startup_cost_#_;

B_1_#_(t) ..   pi_#_(t) =e= SUM(i_#_, lam_#_(t, i_#_)*pival_#_(i_#_)) ;
B_3_#_(t) .. comb_#_(t) =e= SUM(i_#_, lam_#_(t, i_#_)*consumoger_#_(i_#_));
B_4_#_(t) .. SUM(i_#_, lam_#_(t, i_#_)) =e= 1;

*-----------^^ Equations of MGElement #_#_ (DieselGenQuadratic) ^^----------------
