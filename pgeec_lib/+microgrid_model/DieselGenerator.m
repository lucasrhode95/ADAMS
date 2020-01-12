classdef (Abstract) DieselGenerator < microgrid_model.MGElement
	% Class that represents a generic diesel generator. Developers that mean to create new diesel generator models should extend this class.
	%
	% This diesel gen model includes a startup cost, parameters for max and
	% minimal power output and also a flag indicating whether or not it is
	% powered on at the beginning of the simulation.
	%
	% Extenders should write a cost-calculating equation relating the cost
	% variable ci(t) with the power output pi(t)
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
		% Diesel generator start up cost [any $ unit] (6.8 [R$])
		startupCost {mustBePositive(startupCost)} = 6.8;
		
		% Diesel cost [$ per litre] (2.9 R$/litre)
		fuelCost {mustBePositive(fuelCost)} = 2.9;
		
		% Nominal generator power [kW] (20 kW)
		maxPower {mustBePositive(maxPower)} = 20;
		
		% Minimal generator load [0 - 1] (0.2)
		minRelativePower {util.TypesUtil.mustBeBetween(minRelativePower, 0, 1)} = 0.2;
		
		% Whether or not the generator is initially on (false)
		initiallyOn {util.TypesUtil.mustBeLogical(initiallyOn)} = false;
	end
	
	properties(Constant, Access = protected)
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.PARAMETERS_FILE')">MGElement.PARAMETERS_FILE</a>
		SUPER_PARAMETERS_FILE = '#TEMPLATEdieselgen_generic-template_parameters.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		SUPER_EQUATIONS_FILE  = '#TEMPLATEdieselgen_generic-template_equations.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.COST_VARIABLE')">MGElement.COST_VARIABLE</a>
		COST_VARIABLE   = ['+ci', microgrid_model.MGElement.ID_PLACEHOLDER, '(t)'];
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.POWER_VARIABLE')">MGElement.POWER_VARIABLE</a>
		POWER_VARIABLE  = ['+pi', microgrid_model.MGElement.ID_PLACEHOLDER, '(t)'];
	end
	
	methods(Access = public)
		
		function operationalCost = getOperationalCost(this)
		% Returns an array containing the operational (fuel) cost of this
		% diesel generator at each discretization period
		% Always positive
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			operationalCost = this.timeRead('ci');
		end
		
		function netPowerOutput = getPowerOutput(this)
		% Returns an array containing the net power flow of this diesel
		% generator at each discretization period
		% Always positive
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			netPowerOutput = this.timeRead('pi');
		end
		
		function genStates = getStates(this)
		% Returns the state of the generator (On or Off) at each interval
			genStates = this.timeRead('bGL');
		end
		
		function consumptionModelX = getConsumptionModelX(this)
			consumptionModelX = this.read('pival', ['i', this.ID_PLACEHOLDER]);
		end
		
		function consumptionCurve = getConsumptionModelY(this)
		% Returns the data points used by GAMS to linearized the quadratic function.
			consumptionCurve = this.read('consumoger', ['i', this.ID_PLACEHOLDER]);
		end
	end

	methods(Access = protected)
		function updateTimeInfo(this, timeArray)
		% API developers' use only
		% See also: <a href="matlab:doc('microgrid_model.MGElement/updateTimeInfo')">MGElement.updateTimeInfo()</a>
			this.setTimeArray(timeArray);
		end
		
		function flushVariables(this)
			import microgrid_model.CentralController
			
			% initializes the set that says if the generator is on in a
			% given period, here we used to define the initial state of it.
			iniGer = zeros(size(this.getTimeArray()));
			iniGer(1) = this.initiallyOn;
			
			this.addScalar('DG_startup_cost', this.startupCost*this.quantity);
			this.addScalar('diesel_cost', this.fuelCost);
			this.addScalar('Pi_nominal', this.maxPower*this.quantity);
			this.addScalar('minLoad', this.minRelativePower);
			
			this.addParameter('iniGer', iniGer, CentralController.TIME_VARIABLE);
		end
		
		function checkIsReadyForExecution(~)
		% Checks if the model is ready for execution, throws error if not.
		end
	end
end

