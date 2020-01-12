classdef SolarPanelConstant < microgrid_model.Load
	% Class that represents a solar panel on a Microgrid.
	%
	% This model assumes the solar panel is always at its MPPT level and
	% will follow the generation curve exactly.
	%
	% Confusion-avoiding note: since the dynamics of a solar panel and a
	% constant load are basically the same EXCEPT for the sign of the power
	% output (PVs can be considered to have negative power consumption), this
	% class actually extends the <a href="matlab:doc('microgrid_model.Load')">Load</a> class and therefore some methods
	% have demand-related names.
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

		function opCost = getOperationalCost(this)
		% Always zero for the entire period, as there's no cost associated with using it.
			opCost = 0*this.getTimeArray();
		end
		
		%@override
		function netPowerOutput = getPowerOutput(this)
		% Returns an array containing the generation of this panel at each discretization period as seem by GAMS
		% Always positive.
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			netPowerOutput = -this.timeRead('baseDemand');
		end
		
% 		function generationProfile = getOriginalProfile(this)
% 		% Returns an array containing the original demand profile, before any transformation was applied to it
% 		% Always negative.
% 		%
% 		% See also: <a href="matlab:doc('microgrid_model.MGElement/getTimeArray')">MGElement.getTimeArray()</a>
% 			generationProfile = this.getOriginalProfile();
% 		end
	end

	methods(Access = public)
		function status = importGenerationProfile(this, varargin)
		% Reads an Excel or .csv file containing a time series of generation values
		%
		% The file should consist of two columns - a time column and a
		% power output column. There's no limit for row count, although the
		% simulation will get slower for longer simulations.
		%
		% If the first row is textual, it will be considered to be a header
		% and will be ignored.
		%
		% Time column: the first column of the file, positive values and
		% monotonically increasing, in minutes. The initial time is
		% considered to be midnight, meaning that a value of 65 is
		% interpreted as the power output at 01:05am.
		%
		% Generation column: second column of the file, should contain the
		% average power output [kW] computed at the end of the respective interval.
		%
		% Example of file:
		%
		% time [min], power output [kW]
		% 5,10.5
		% 10,10.4
		% 15,11.7
		%  ... and so on
		% 
		% Examples:
		% import microgrid.solarPanel
		% pv = SolarPanelConstant();
		%
		% pv.importGenerationProfile(); % shows a dialog for the user to choose the file to be loaded
		% pv.importGenerationProfile('C:/data/solarOutput.xlsx'); % read the solarOutput.xlsx file silently (no dialog)
		%
		% It's actually just mirror to <a href="matlab:doc('microgrid_model.SolarPanelConstant/importDemandProfile')">Load.importDemandProfile()</a> with a different name
			status = this.importDemandProfile(varargin{:});
		end
	end
	
	methods(Access = protected)
		
		% @override
		function flushVariables(this)
		% API developers' use only
		% 
		% See also: <a href="matlab:doc('microgrid_model.MGElement/flushVariables')">MGElement.flushVariables()</a>
			
			% flushes the generation profile of the panel but, since we're
			% extending the Load class, flushes it as a negative Load.
			this.timeAddParameter('baseDemand', -this.getDemandProfile());
		end
	end
	
end

