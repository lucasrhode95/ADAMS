*----------------VV Equations of MGElement #_#_ (Battery) VV----------------------
PARAMETERS
	iniBat_#_(t) array used in the equations to set the initial state of the battery,
	nft_#_(t)    how much of the charge at period t passes on to period t+ (numbers like 0.999 are usual)
;

iniBat_#_(t) = soc_ini_#_ $ (ORD(t) = 1);
nft_#_(t) = (1-nf_#_)** dt(t);

FREE VARIABLES
	Cb_#_(t)  wear cost - function of soc_#_(t) and dod_#_(t),
	dod_#_(t) Depth Of Discharge. + for discharge. - for charge [0-1]
;

POSITIVE VARIABLES
	soc_#_(t) State Of Charge [0-1] at the end of the period,
	psc_#_(t) charging rate [kW],
	psd_#_(t) discharging rate [kW]
;

BINARY VARIABLES
	bDescIni_#_(t) 1 indicates that a new discharge cycle was initiated in t,
	bDescFim_#_(t) 1 indicates that a new discharge cycle was finished in t,
	bDesc_#_(t)    1 indicates that the battery is discharging in t
;

EQUATIONS
	defSoc_#_(t)	defines that SOC(t) = SOC(t-1) - DOD(t),
	defDod_#_(t)	defines that DOD(t) = Power×dt÷Capacity,

	C_2_#_(t) binary calculation indicating start or end of discharge,
	C_4_#_(t) maximum discharge rate (Psd_max),
	C_5_#_(t) maximum charge rate (Psc_max),
	C_6_#_(t) doesn't allow battery to start and stop discharging on the same time interval
;

defSoc_#_(t) .. soc_#_(t) =e= nft_#_(t)*(soc_#_(t - 1)+iniBat_#_(t)) - dod_#_(t);
defDod_#_(t) .. dod_#_(t) =e= (1/disEffic_#_*psd_#_(t) - chaEffic_#_*psc_#_(t))*dt(t)/(batSize_#_);

soc_#_.lo(t) = soc_min_#_;
soc_#_.up(t) = soc_max_#_;

soc_#_.lo(t) $ (ORD(t) = CARD(t)) = socFinLo_#_;
soc_#_.up(t) $ (ORD(t) = CARD(t)) = socFinUp_#_;

C_2_#_(t) .. bDescIni_#_(t) - bDescFim_#_(t) =e= bDesc_#_(t) - bDesc_#_(t - 1);
C_4_#_(t) .. psd_#_(t) =l= bDesc_#_(t) * psmax_#_;
C_5_#_(t) .. psc_#_(t) =l= (1 - bDesc_#_(t)) * psmin_#_;
C_6_#_(t) .. bDescIni_#_(t) + bDescFim_#_(t) =l= 1;
*----------------^^ Equations of MGElement #_#_ (Battery) ^^----------------------
