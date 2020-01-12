classdef DieselGeneratorQuadratic < microgrid_model.DieselGenerator
	% Class that represents a diesel generator modeled with quadratic fuel consumption aP² + bP + c.
	%
	% This diesel gen model includes a startup cost, parameters for max and
	% minimal power output and also a flag indicating whether or not it is
	% on at the beginning of the simulation.
	%
	% The fuel consumption quadratic equation is linearized by
	% interpolating between 6 points by default, but the number of points
	% can be changed using the <a href="matlab:doc('microgrid_model.DieselGeneratorQuadratic/linearizationPoints')">linearizationPoints</a> property.
	%
	% --
	%
	% This model presents default values for all its parameters, so that you
	% only need to worry about what you really want to change (if anything).
	%
	% In each property description the engineering unit (and the valid range
	% in some cases) is displayed inside square brackets [] and the default
	% value is found between parenthesis ().
	%
	% See also: microgrid_model
	
	% simulation properties
	properties(Access = public)
		
		% Fuel consumption modeling parameter [c = a×Pi² + b×Pi + c]
		a {util.TypesUtil.mustBeScalar(a)} = 0.004446;
		
		% Fuel consumption modeling parameter [c = a×Pi² + b×Pi + c]
		b {util.TypesUtil.mustBeScalar(b)} = 0.121035;
		
		% Fuel consumption modeling parameter [c = a×Pi² + b×Pi + c]
		c {util.TypesUtil.mustBeScalar(c)} = 1.653882;
		
		% Amount of points used to linearize the fuel consumption model
		linearizationPoints {mustBePositive(linearizationPoints), mustBeInteger(linearizationPoints)} = 6;
		
	end
	
	properties(Constant, Access = protected)
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.PARAMETERS_FILE')">MGElement.PARAMETERS_FILE</a>
		PARAMETERS_FILE = 'dieselgen_quadratic_parameters.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		EQUATIONS_FILE  = 'dieselgen_quadratic_equations.gms';
	end

	methods(Access = protected)
		
		function flushVariables(this)
			import microgrid_model.CentralController
			% superclass method
			this.flushVariables@microgrid_model.DieselGenerator();
			
			% creates the set i, used as index of the linearization points
			setI = 1:this.linearizationPoints;
			
			% initializes the power data array, used as sort of a 'lookup'
			% table on the linearization model
			powerData = linspace(0, this.maxPower*this.quantity, this.linearizationPoints);
			
			% flushes everything related to the quadratic model
			this.addScalar('a', this.a/this.quantity);
			this.addScalar('b', this.b);
			this.addScalar('c', this.c*this.quantity);
			
			this.addSet('i', setI);
			this.addParameter('pival', powerData, ['i', this.ID_PLACEHOLDER]);
		end
	end
end

