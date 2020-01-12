classdef LoadConstant < microgrid_model.Load
	% Class that represents a constant load on a Microgrid, i.e. will follow the demand profile exactly.
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
	
	properties(Constant, Access = protected)
		
		% API developers' use only
		%
		% Set to empty because there are no equations besides the super
		% class' definition
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		EQUATIONS_FILE  = [];
		
		% API developers' use only
		%
		% Set to empty because there are no parameters besides the super
		% class' definition
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		PARAMETERS_FILE  = [];
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.COST_VARIABLE')">MGElement.COST_VARIABLE</a>
		COST_VARIABLE   = [];
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.POWER_VARIABLE')">MGElement.POWER_VARIABLE</a>
		POWER_VARIABLE  = ['-baseDemand', microgrid_model.MGElement.ID_PLACEHOLDER,'(t)'];
	end
	
	methods(Access = public)

		function opCost = getOperationalCost(~)
		% This is not implemented and should not be used.
		%
		% The reason it shouldn't be used is that the operational cost of a
		% load is hard to define. Usually what you define is the load shedding
		% cost, a very high synthetic price to force the optimizer to avoid
		% it fiercely, but then again, that has nothing to do with an actual
		% operational cost.
			return;
		end
		
		%@override
		function netPowerOutput = getPowerOutput(this)
		% Returns an array containing the demand of this load at each discretization period
		% Always negative.
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			netPowerOutput = -this.timeRead('baseDemand');
		end
	end
	
end

