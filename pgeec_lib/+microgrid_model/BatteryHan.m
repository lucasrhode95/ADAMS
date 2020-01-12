classdef BatteryHan < microgrid_model.Battery
	% Class that represents a stationary battery as modeled by <a href="https://ieeexplore.ieee.org/document/6672402/">Han (2013)</a> & Rhode (2019).
	%
	% The model proposed by Han et. al. (2013) depends on the cycle life
	% vs. depth of discharge curve
	% TODO: link to detailed explanation here
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
		
		% Amount of points used to linearize SOC levels on the cost function, values from 7 to 11 performed well in our tests but anything above that gets too slow. If you have no idea what this is, just go with default (default=7)
		linearizationPointsSoc {mustBePositive(linearizationPointsSoc), mustBeInteger(linearizationPointsSoc)} = 7;
		
		% Amount of points used to linearize DOD levels on the cost function, values from 7 to 11 performed well in our tests but anything above that gets too slow. If you have no idea what this is, just go with default (default=7)
		linearizationPointsDod {mustBePositive(linearizationPointsDod), mustBeInteger(linearizationPointsDod)} = 7;
		
		% Curve fit coefficient ACC(dod) = a0*DOD^-a1. If you have no idea what this is, leave the default value (694)
		a0 {mustBeNumeric(a0)} = 694;
		
		% Curve fit coefficient [ACC(dod) = a0*DOD^-a1]. If you have no idea what this is, leave the default value (0.795)
		a1 {mustBeNumeric(a1)} = 0.795;
		
	end
	
	properties(Constant, Access = protected)
		% API developers' use only
		%
		% See <a href="matlab:doc('microgrid_model.MGElement.PARAMETERS_FILE')">MGElement.PARAMETERS_FILE</a>
		PARAMETERS_FILE = 'battery_han_parameters.gms';
		
		% API developers' use only
		%
		% See <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		EQUATIONS_FILE  = 'battery_han_equations.gms';
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
			this.flushVariables@microgrid_model.Battery(); % superclass method
		
			% checks if DOD point count is odd and corrects it if it's not
			correctionL = 1-rem(this.linearizationPointsDod, 2);
			if correctionL ~= 0 && this.WARNINGS
				warning('Number of DOD discretization points must be odd. Correcting from %d to %d', this.linearizationPointsDod, this.linearizationPointsDod+correctionL);
			end
			
			% creates the linearization indices
			setK = 1:this.linearizationPointsSoc; % SOC domain set
			setL = 1:(this.linearizationPointsDod+correctionL);	 % DOD domain set		
			setM = 1:(this.linearizationPointsSoc + this.linearizationPointsDod + correctionL - 1); % grid diagonals
			
			% creates the linearization grid points (same length as their
			% respetive indices)
			socData  = linspace(this.socMin, this.socMax, this.linearizationPointsSoc);
			dodData  = linspace(this.socMin-this.socMax, this.socMax-this.socMin, this.linearizationPointsDod+correctionL);
			
			% wear model parameters
			this.addScalar('a0', this.a0);
			this.addScalar('a1', this.a1);
			
			% discretization grid indices
			this.addSet('k', setK);
			this.addSet('L', setL);
			this.addSet('m', setM);
			
			% discretization grid values
			this.addParameter('socData', socData, strcat('k', this.ID_PLACEHOLDER));
			this.addParameter('dodData', dodData, strcat('L', this.ID_PLACEHOLDER));
		end
	end
	
end

