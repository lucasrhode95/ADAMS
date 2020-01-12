*--------------------VV Global settings of the simulation VV--------------------
MODEL MR / ALL /;

$onecho > cplex.opt
workmem 4096
$offecho
MR.OptFile = 1;

OPTIONS
	MIP = cplex,
	threads = 0,
	limrow = 100,
	iterLim = 2100000000,
	optCA = 0,
	optCR = #RELATIVE_ERROR#,
	resLim = 1000000
;

*MR.OptCA = 0;
*MR.OptCr = #RELATIVE_ERROR#

SOLVE MR using MIP minimizing z;
*--------------------^^ Global settings of the simulation ^^--------------------
