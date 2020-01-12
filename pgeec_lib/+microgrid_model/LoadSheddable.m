classdef LoadSheddable < microgrid_model.Load
	% Class that represents a sheddable load on a Microgrid, i.e. can be turned off if there is not enough generation available
	%
	% This model can be seen as an abstraction of the <a href="matlab:doc('microgrid_model.LoadConstant')">microgrid_model.LoadConstant</a>
	% class. They will behave identically provided there's enough power
	% available.
	% If the microgrid fails to keep the generation/load balance, this load
	% can be turned off (shedded) to minimize losses.
	%
	% The total shedding cost is given by
	% s = (<a href="matlab:doc('microgrid_model.LoadSheddable.sheddingTariff')">sheddingTariff</a>*baseDemand(t) + <a href="matlab:doc('microgrid_model.LoadSheddable.sheddingOpportunity')">sheddingOpportunity</a>)*deltaT
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
	
	properties(Access = public)
		% Cost of shedding this load, used to attribute a cost that varies with load size [$/kWh] (50 [R$/kWh])
		%
		% The shedding cost is calculated by the following expression:
		% s = (sheddingTariff*baseDemand(t) + sheddingOpportunity)*deltaT
		%
		% A load can be prioritized by setting higher values to this
		% parameter
		sheddingTariff {util.TypesUtil.mustBeScalar(sheddingTariff)} = 50;
		
		% Opportunity cost of shedding this load, used to attribute a cost that is independent of load size [$/hour] (50 [R$/hour])
		%
		% The shedding cost is calculated by the following expression:
		% s = (sheddingTariff*baseDemand(t) + sheddingOpportunity)*deltaT
		%
		% A load can be prioritized by setting higher values to this
		% parameter
		sheddingOpportunity {util.TypesUtil.mustBeScalar(sheddingOpportunity)} = 50;
	end
	
	properties(Constant, Access = protected)
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		EQUATIONS_FILE  = 'load_sheddable_equations.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		PARAMETERS_FILE  = 'load_sheddable_parameters.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.COST_VARIABLE')">MGElement.COST_VARIABLE</a>
		COST_VARIABLE   = ['+sheddingCost', microgrid_model.MGElement.ID_PLACEHOLDER, '(t)'];
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.POWER_VARIABLE')">MGElement.POWER_VARIABLE</a>
		POWER_VARIABLE  = ['-netPower', microgrid_model.MGElement.ID_PLACEHOLDER,'(t)'];
	end
	
	methods(Access = public)

		function opCost = getOperationalCost(this)
		% Returns the shedding cost at each discretization period
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			opCost = this.timeRead('sheddingCost');
		end
		
		%@override
		function netPowerOutput = getPowerOutput(this)
		% Returns an array containing the power output of this load at each discretization period
		% Always negative.
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			netPowerOutput = -this.timeRead('netPower');
		end
		
		%@override
		function realizedProfile = getRealizedProfile(this)
		% Returns an array containing the demand of this load at each discretization period
		% Always positive.
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			realizedProfile = this.timeRead('netPower');
		end
	end

	methods(Access = protected)
		
		% @override
		function flushVariables(this)
		% API developers' use only
		% 
		% See also: <a href="matlab:doc('microgrid_model.MGElement/flushVariables')">MGElement.flushVariables()</a>
			this.flushVariables@microgrid_model.Load(); % superclass method
			
			this.addScalar('sheddingTariff', this.sheddingTariff);
			this.addScalar('sheddingOpportunity', this.sheddingOpportunity);
		end
	end
	
end

