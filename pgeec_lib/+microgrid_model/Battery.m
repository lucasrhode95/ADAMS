classdef (Abstract) Battery < microgrid_model.MGElement
	% Class that represents a generic battery. Developers that mean to create new battery models should extend this class.
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
		
		% Storage capacity [kWh]. See also: <a href="matlab:doc('microgrid_model.Battery/setCapacityInAh')">setCapacityInAh(capacityAh, voltage)</a> for Ah input (16)
		capacity {mustBePositive(capacity)} = 16;
		
		% Total battery cost: price+installation+maintenance [any $ unit] (33660 [R$])
		totalPrice {mustBePositive(totalPrice)} = 33660; 
		
		% Maximum State of Charge allowed [0-1] (0.80)
		socMax {validateattributes(socMax, {'numeric'}, {'scalar', '>=', 0, '<=', 1})} = 0.80;
		
		% Minimum State of Charge allowed [0-1] (0.42)
		socMin {validateattributes(socMin, {'numeric'}, {'scalar', '>=', 0, '<=', 1})} = 0.42;
		
		% State of Charge at the beginning of the simulation [0-1] (0.80)
		socIni {validateattributes(socIni, {'numeric'}, {'scalar', '>=', 0, '<=', 1})} = 0.80;
		
		% Minimum State of Charge at the end of the simulation [0-1] (0.80)
		socFinLo {validateattributes(socFinLo, {'numeric'}, {'scalar', '>=', 0, '<=', 1})} = 0.42;
		
		% Maximum State of Charge at the end of the simulation [0-1] (0.80)
		socFinUp {validateattributes(socFinUp, {'numeric'}, {'scalar', '>=', 0, '<=', 1})} = 0.80;
		
		% Maximum discharge rate [kW] (20.6)
		maxDischRate {mustBePositive(maxDischRate)} = 20.6;
		
		% Maximum recharge rate [kW] (19.0)
		maxChargRate {mustBePositive(maxChargRate)} = 19.0;
		
		% Rate of self discharge [0-1, percentage per hour] (0.002)
		%
		% soc(t) = soc(t-1)×(1-selfDisch^dt) - dod(t)
		%
		% Where
		% soc: State of charge
		% dt: size of the interval, in hours
		% dod: depth of discharge a.k.a. intentional discharge
		selfDisch {validateattributes(selfDisch, {'numeric'}, {'scalar', '>=', 0, '<', 1})} = 0.002;
		
		% Discharge efficiency [0 - 1] (0.9)
		%
		% injected power = (output power)×dischEffi 
		dischEffi {validateattributes(dischEffi, {'numeric'}, {'scalar', '>=', 0, '<=', 1})} = 0.90;
		
		% Recharge efficiency [0 - 1] (0.9)
		%
		% charging power = (input power)/chargEffi
		chargEffi {util.TypesUtil.mustBeBetween(chargEffi, 0, 1), mustBePositive(chargEffi)} = 0.90;
	end
	
	properties(Constant, Access = protected)		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.COST_VARIABLE')">MGElement.COST_VARIABLE</a>
		COST_VARIABLE   = ['+Cb', microgrid_model.MGElement.ID_PLACEHOLDER, '(t)'];
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.POWER_VARIABLE')">MGElement.POWER_VARIABLE</a>
		POWER_VARIABLE  = ['+psd', microgrid_model.MGElement.ID_PLACEHOLDER, '(t)', '-psc', microgrid_model.MGElement.ID_PLACEHOLDER, '(t)'];
		
		% API developers' use only.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.SUPER_PARAMETERS_FILE')">MGElement.SUPER_PARAMETERS_FILE</a>
		SUPER_PARAMETERS_FILE = '#TEMPLATEbattery_generic-template_parameters.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.SUPER_EQUATIONS_FILE')">MGElement.SUPER_EQUATIONS_FILE</a>
		SUPER_EQUATIONS_FILE  = '#TEMPLATEbattery_generic-template_equations.gms';
	end
	
	methods(Access = public)
		
		function setCapacityInAh(this, capacityAh, batteryVoltage)
		% Converts Ah battery capacity to kWh before storing it.
		%
		% For this conversion is necessary to know the battery voltage,
		% usually included in the battery's user manual (stationary/car
		% batteries are usually 12-12.6V rated)
		%
		% Examples:
		%
		% To set the capacity of a 100Ah, 12V battery:
		% battery.setCapacityInAh(100, 12)
			this.capacity = capacityAh*batteryVoltage/1000;
		end
		
		function operationalCost = getOperationalCost(this)
		% Returns an array containing the operational cost of the battery at each discretization period
		% Always positive
		%
		% The calculation of an operational cost of a battery is the
		% subject of many papers and the one implemented here is based on
		% the work of Han (2013) and of the author of this package, Rhode
		% (2019)
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			operationalCost = this.timeRead('Cb');
		end
		
		function netPowerOutput = getPowerOutput(this)
		% Returns an array containing the power flowing to the microgrid at each discretization period
		% + when discharging, - when recharging
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			netPowerOutput = this.timeRead('psd') ...
						   - this.timeRead('psc');
		end

		function powerInjection = getPowerInjection(this)
		% Returns an array containing the gross power flow of the battery at each discretization period
		% + when discharging, - when recharging
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			powerInjection = this.timeRead('psd')*this.read('disEffic') ...
						   - this.timeRead('psc')/this.read('chaEffic');
		end
		
		function soc = getStateOfCharge(this)
		% Returns the state of charge (SOC) of the battery at each time interval
		%
		% Examples:
		% after running the model, the user can plot the resulting SOC using:
		%    plot(controller.getTime(), battery.getStateOfCharge())
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			soc = this.timeRead('soc');
		end
		
		function dod = getDepthOfDischarge(this)
		% Returns the depth of discharge of the battery at each time interval
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			dod = this.timeRead('dod');
		end
	end
	
	methods(Access = protected)
		
		function updateTimeInfo(varargin)
		% API developers' use only
		%
		% Method does nothing because the model doesn't depend on of the
		% time. Implementers should override this method if needed.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/updateTimeInfo')">MGElement.updateTimeInfo)</a>
			return;
		end
		
		function flushVariables(this)
		% API developers' use only
		%
		% Sends all the generalized Battery variables to GAMS
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/flushVariables')">MGElement.flushVariables)</a>
			
% 			% checks
% 			validateattributes(this.socIni, {'numeric'}, {'scalar', '<=', this.socMax, '>=', this.socMin});
% 			validateattributes(this.socFinLo, {'numeric'}, {'scalar', '<=', this.socMax, '>=', this.socMin});
% 			validateattributes(this.socFinUp, {'numeric'}, {'scalar', '<=', this.socMax, '>=', this.socMin});
		
			% sends everything to GAMS
			this.addScalar('batSize', this.capacity*this.quantity);
			this.addScalar('batPrice', this.totalPrice*this.quantity);
			this.addScalar('soc_max', this.socMax);
			this.addScalar('soc_min', this.socMin);
			this.addScalar('soc_ini', this.socIni);
			this.addScalar('socFinLo', this.socFinLo);
			this.addScalar('socFinUp', this.socFinUp);
			this.addScalar('psmax', this.maxDischRate*this.quantity);
			this.addScalar('psmin', this.maxChargRate*this.quantity);
			this.addScalar('nf', this.selfDisch);
			this.addScalar('disEffic', this.dischEffi);
			this.addScalar('chaEffic', this.chargEffi);
		end
		
		function checkIsReadyForExecution(this)
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/checkIsReadyForExecution')">MGElement.checkIsReadyForExecution()</a>
			if this.socMin > this.socMax
				error('Lower state of charge boundary is greater then upper boundary');
			end
						
			if this.socFinLo > this.socFinUp
				error('Lower limit of ending state of charge is greater than upper limit.');
			end
		
			if this.socIni < this.socMin || this.socIni > this.socMax ...
			   || this.socFinLo < this.socMin || this.socFinUp > this.socMax
				error('Initial and ending battery state of charge must be within the socMin (%0.4g) and socMax (%0.4g) limits', this.socMin, this.socMax);
			end
			
			if this.socMax < this.socMin
				error('Maximum state of charge (%2.2f) cannot be less than the minimum (%2.2f)', this.socMax, this.socMin);
			end
		end
	end
	
end

