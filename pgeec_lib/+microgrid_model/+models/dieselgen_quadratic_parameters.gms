*--------VV Parameters of MGElement #_#_ (DieselGeneratorQuadratic) VV------------

SET
	i_#_ samples indices for the linearization model
;

PARAMETERS
*CONSUMPTION MODEL
	a_#_ fuel consumption modeling parameter [c = a×Pi² + b×Pi + c],
	b_#_ fuel consumption modeling parameter [c = a×Pi² + b×Pi + c],
	c_#_ fuel consumption modeling parameter [c = a×Pi² + b×Pi + c],

*LINEARIZATION MODEL
	pival_#_(i_#_)      samples used in the linearization process,
	consumoger_#_(i_#_) values of the quadratic function at each "pival"
;

*--------^^ Parameters of MGElement #_#_ (DieselGeneratorQuadratic) ^^------------
