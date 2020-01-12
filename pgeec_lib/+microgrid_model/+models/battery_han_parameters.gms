*---------------VV Parameters of MGElement #_#_ (BatteryHan) VV-------------------

*--------- WEAR MODEL PARAMETERS ----
PARAMETERS
	a0_#_       curve fit coefficient [ACC(dod) = a0*dod^-a1],
	a1_#_       curve fit coefficient [ACC(dod) = a0*dod^-a1]
;

*The goal of this section is to define the relationships used on the 2D linea-
*rization of the battery wear cost-function.
*This section should be independent of the rest of the file.
SETS
*SETS
        k_#_ indices of the SOC values (X axis),
*used uppercase L to diferentiate from the number 1
        L_#_ indices of the DOD values (Y axis),
        m_#_ indices of the grid diagonals
;

*NOTE ABOUT THE DISCRETIZATION PARAMETERS:
*1) It's better if you have a DOD=0 discretization point. That is advisable
*   for intervals where the EMS doesn't want to (dis)charge the battery (DOD=0)
*2) Remember that DOD can be either positive or negative
*3) Remember that SOC can only be positive
*4) Remember to check if the discretization points contain SOC_max|min
PARAMETERS
        socData_#_(k_#_) discretization points of SOC (X array),
        dodData_#_(L_#_) discretization points of DOD (Y array)
;
*--------- WEAR MODEL PARAMETERS ----

*---------------^^ Parameters of MGElement #_#_ (BatteryHan) ^^-------------------
