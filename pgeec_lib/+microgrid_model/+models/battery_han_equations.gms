*---------------VV Equations of MGElement #_#_ (BatteryHan) VV--------------------

*The goal of this section is to define the relationships used on the 2D linea-
*rization of the battery wear cost-function.
*This section should be independent of the rest of the file.
PARAMETERS
	cbData_#_(k_#_, L_#_) discretization points of the cost function (Z array)
;

SETS
	map2D_#_(k_#_, L_#_, m_#_) choice of the diagonal points
;

ABORT$(CARD(m_#_) <> CARD(k_#_) + CARD(L_#_) - 1) "###### SET m_#_ HAS WRONG SIZE ######";
map2D_#_(k_#_, L_#_, m_#_) $ (ORD(L_#_) = ORD(k_#_) + ORD(m_#_) - CARD(k_#_)) = YES;

*with all the parameters defined, we can now evaluate the cost function at each feasible point, populating the Z array
*LOOP((k_#_, L_#_) $ ( (soc_min_#_ <= socData_#_(k_#_)+1e-6) AND (soc_max_#_ >= socData_#_(k_#_)-1e-6) AND (soc_min_#_ - 1e-6 <= socData_#_(k_#_)-dodData_#_(L_#_)) AND (soc_max_#_ + 1e-6 >= socData_#_(k_#_)-dodData_#_(L_#_)) AND (1-socData_#_(k_#_)+dodData_#_(L_#_) >= 0) ),
*	cbData_#_(k_#_, L_#_) = batPrice_#_/(2*a0_#_)*abs( ((1-socData_#_(k_#_)+dodData_#_(L_#_))**a1_#_ - (1-socData_#_(k_#_))**a1_#_) )
*);

* very high cost for invalid values
* this actually may be troublesome for values near SOCs of 100% and 0% and should be fixed in the future.
* Altough, if the user uses SOCmax and SOCmin as, say, 10 and 90% it wouldn't be a problem.
cbData_#_(k_#_, L_#_) = 10000;

* calculates the cost matrix at all valid points. Here we sum a residual 1e-7 to avoid unexpected floating point errors
LOOP((k_#_, L_#_)
	$ (
		(socData_#_(k_#_)-dodData_#_(L_#_) <= 1) AND
		(socData_#_(k_#_)-dodData_#_(L_#_) >= 0)
        ),
	cbData_#_(k_#_, L_#_) = batPrice_#_/(2*a0_#_)*abs( ((1-socData_#_(k_#_)+dodData_#_(L_#_) + 1e-7)**a1_#_ - (1-socData_#_(k_#_))**a1_#_) )
);
cbData_#_(k_#_, L_#_) = round(cbData_#_(k_#_, L_#_), 7);

POSITIVE VARIABLES
	lambda_#_(t, k_#_, L_#_) weights of the convex approximation
;

SOS2 VARIABLES
	delta_#_(t, k_#_) 2 points max per line,
	gamma_#_(t, L_#_) 2 points max per row,
	beta_#_(t, m_#_)  3 points max in total
;

EQUATIONS
	defSoc2D_#_(t)     defines the approximated SOC - given by the convex-weighted points,
	defDod2D_#_(t)     defines the approximated DOD - given by the convex-weighted points,
	defCb2D_#_(t)      defines the approximated wear cost - given by the convex-weighted points,
	convexity_#_(t)    makes the model convex,
	defDelta_#_(t, k_#_) defines delta so that only 2 point are active per grid-line,
	defGamma_#_(t, L_#_) defines gamma so that only 2 point are active per grid-row,
	defBeta_#_(t, m_#_)  defines beta so that only 3 points are active on the entire grid
;

defSoc2D_#_(t)  .. soc_#_(t-1)+IniBat_#_(t) =e= SUM((k_#_, L_#_), lambda_#_(t, k_#_, L_#_)*socData_#_(k_#_));
defDod2D_#_(t)  .. dod_#_(t) =e= SUM((k_#_, L_#_), lambda_#_(t, k_#_, L_#_)*dodData_#_(L_#_));
defCb2D_#_(t)   .. Cb_#_(t)  =e= SUM((k_#_, L_#_), lambda_#_(t, k_#_, L_#_)*cbData_#_(k_#_, L_#_));
convexity_#_(t) .. 1         =e= SUM((k_#_, L_#_), lambda_#_(t, k_#_, L_#_));

defDelta_#_(t, k_#_) .. delta_#_(t, k_#_) =e= SUM(L_#_, lambda_#_(t, k_#_, L_#_));
defGamma_#_(t, L_#_) .. gamma_#_(t, L_#_) =e= SUM(k_#_, lambda_#_(t, k_#_, L_#_));
 defBeta_#_(t, m_#_) ..  beta_#_(t, m_#_) =e= SUM(map2D_#_(k_#_, L_#_, m_#_), lambda_#_(t, k_#_, L_#_));
*---------------^^ Equations of MGElement #_#_ (BatteryHan) ^^--------------------
