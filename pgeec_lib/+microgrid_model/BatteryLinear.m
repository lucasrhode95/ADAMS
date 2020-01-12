classdef BatteryLinear < microgrid_model.Battery
	% Class that represents a stationary battery with a linear wear cost model.
	%
	% This model is best suitable for simpler applications, where the
	% wear of the battery is secondary. Since it's a purely linear model,
	% it can be used to aliviate the simulation burden of using a more
	% complex model (e.g. <a href="matlab:doc('microgrid_model.BatteryHan')">BatteryHan</a>)
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
		
		% Unit energy cost attributed to the battery usage [$/kWh] (1.5157 [R$/kWh)
		unitCost {mustBeNonnegative(unitCost)} = 1.5157;
		
	end
	
	properties(Constant, Access = protected)
		% API developers' use only
		%
		% See <a href="matlab:doc('microgrid_model.MGElement.PARAMETERS_FILE')">MGElement.PARAMETERS_FILE</a>
		PARAMETERS_FILE = 'battery_linear_parameters.gms';
		
		% API developers' use only
		%
		% See <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		EQUATIONS_FILE  = 'battery_linear_equations.gms';
	end
	
	methods(Access = protected)
		
		function flushVariables(this)
		% API developers' use only
		%
		% Sends all the variables to GAMS
		%
		% See also:
		% <a href="matlab:doc('microgrid_model.Battery/flushVariables')">Battery.flushVariables()</a>,
		% <a href="matlab:doc('microgrid_model.MGElement/flushVariables')">MGElement.flushVariables()</a>
		
			% superclass method
			this.flushVariables@microgrid_model.Battery();
		
			this.addScalar('unitCost', this.unitCost);
		end
	end
	
end

