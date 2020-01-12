classdef Microgrid < microgrid_model.MGElement
	%MICROGRID Class that represents a microgrid (MG), manages the MGElements and their effect on the global scope (total operational cost calculation, power balance, etc.).
	%
	% Microgrid handles the ID distribution for MGElements and dynamically
	% creates the cost and power balance equations deciding when to or when
	% not to purchase power from the outside network (a.k.a macrogrid).
	%
	% --
	%
	% This model presents default values for all its parameters, so that you
	% only need to worry about what you really want to change (if anything).
	%
	% In each property description the engineering unit (or the valid range
	% in some cases) is displayed inside square brackets [] and the default
	% value is found between parenthesis ().
	%
	% See also: microgrid_model
	
	properties(Access = public)
		% Indicates wheter or not the MG is operating in island mode
		isIsland {util.TypesUtil.mustBeLogical(isIsland)} = false;
	end
	
	properties(Constant, Access = protected)
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.PARAMETERS_FILE')">MGElement.PARAMETERS_FILE</a>
		PARAMETERS_FILE = 'microgrid_quites_parameters.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		EQUATIONS_FILE = 'microgrid_quites_equations.gms';
		
		% API developers' use only.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.SUPER_PARAMETERS_FILE')">MGElement.SUPER_PARAMETERS_FILE</a>
		SUPER_PARAMETERS_FILE = util.CommonsUtil.empty;
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.SUPER_EQUATIONS_FILE')">MGElement.SUPER_EQUATIONS_FILE</a>
		SUPER_EQUATIONS_FILE  = util.CommonsUtil.empty;
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.COST_VARIABLE')">MGElement.COST_VARIABLE</a>
		COST_VARIABLE = '+cr(t, tp_dia, thora)-rvr(t, tp_dia, thora)';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.POWER_VARIABLE')">MGElement.POWER_VARIABLE</a>
		POWER_VARIABLE  = '+prc(t, tp_dia, thora)+prcd(t, tp_dia, thora)-prv(t, tp_dia, thora)';
	end
	
	properties(Constant, Access = private)
		% Placeholder for the power variables summation (power balance)
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.POWER_VARIABLE')">MGElement.POWER_VARIABLE</a>
		POWER_VARIABLES_PLACEHOLDER = '#POWER_VARIABLES#';
		
		% Placeholder for the cost variables summation (total operational cost)
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.COST_VARIABLE')">MGElement.COST_VARIABLE</a>
		COST_VARIABLES_PLACEHOLDER = '#COST_VARIABLES#';
	end
	
	properties(Access = private)
		% List of elements of the microgrid (diesen generators, batteries, etc.)
		mgElements {util.TypesUtil.mustBeCellArray(mgElements)} = util.TypesUtil.emptyCellArray;
		
		% Last ID assigned to the MGElement list, incremented everytime an MGElement is added to the Microgrid
		lastId {mustBeInteger(lastId)} = 0;
	end
	
	methods(Access = public)
		
		function operationalCost = getOperationalCost(this)
		% Returns an array containing the operational cost of the microgrid
		% at each discretization period
		% + for expenses, - for revenue
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			operationalCost = this.readGlobal('Cz');
		end

		function netPowerOutput = getPowerOutput(this)
		% Returns an array containing the net power flow from the mIcrogrid to the mAcrogrid
		% + for buying, - for selling
		% at each discretization period
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			netPowerOutput =  this.getImportedPower() ...
							- this.getExportedPower();
		end
		
		function exportedPower = getExportedPower(this)
		% Returns an array containing the exported (sold) power from the mIcrogrid to the mAcrogrid
		% Always positive.
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			exportedPower = this.timeReadGlobal('prv');
		end

		function importedPower = getImportedPower(this)
		% Returns an array containing the imported (bought) power from the mAcrogrid to the mIcrogrid
		% Always positive.
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			importedPower = this.timeReadGlobal('prc') ...
						  + this.timeReadGlobal('prcd');
		end
		
		function loadElements = getLoadElements(this, activeOnly)
		% Returns a column-array with all the Load elements added to this Microgrid.
		%
		% Examples:
		% mgElements = model.GETLOADELEMENTS() returns all Load elements
		% added to this Microgrid
		%
		% mgElements = model.GETLOADELEMENTS(true) returns all active
		% Load elements
			import util.TypesUtil
			import util.CommonsUtil
			
			% optional args
			if nargin < 2
				activeOnly = false;
			else
				util.TypesUtil.mustBeLogical(activeOnly);
			end
			
			% this is done so that MATLAB throws an error if the Load class
			% is renamed.
			loadClazz = ?microgrid_model.Load;
			loadClazz = loadClazz.Name;
			
			% initialization
			loadElements = TypesUtil.emptyCellArray;
			
			% filtering
			for i = 1:length(this.mgElements)
				if TypesUtil.instanceof(this.mgElements{i}, loadClazz) && ...
						(this.mgElements{i}.getActive() || ~activeOnly)
					loadElements = [loadElements; this.mgElements(i)];
				end
			end
		end
		
		function mgElements = getMGElements(this, activeOnly)
		% Returns a column-array with all the MGElements added to this Microgrid.
		%
		% Examples:
		% mgElements = model.GETMGELEMENTS() returns all MGElements added
		% to this Microgrid
		%
		% mgElements = model.GETMGELEMENTS(true) returns all active
		% MGElements
			import util.TypesUtil
		
			if nargin < 2 || ~activeOnly
				mgElements = this.mgElements;
				return;
			end
			
			mgElementsFiltered = TypesUtil.emptyCellArray;
			for i = 1:length(this.mgElements)
				if this.mgElements{i}.getActive()
					mgElementsFiltered = [mgElementsFiltered; this.mgElements(i)];
				end
			end
			
			mgElements = mgElementsFiltered;
		end
		
		function setActive(~)
		% Deactivated inherited method (you cannot disable the Microgrid itself)
			return;
		end
		% ^^ PUBLIC GETTERS AND SETTERS
		
		% VV FUNCTIONALITIES
		function addMGElement(this, mgElement)
		% Adds a new MGElement to the Microgrid and assigns it an unique ID number.
			import microgrid_model.MGElement
			MGElement.mustBeMGElement(mgElement);
			
			% increments the last ID and passes it to the MGElement
			mgElement.setId(this.incrementLastId());
			
			% passes CentralController reference to the MGElement
			mgElement.setCentralController(this.getCentralController());
			
			% adds it to the list
			this.mgElements = [this.mgElements; {mgElement}];
			
			% little logging
			if this.DEV
				util.CommonsUtil.log('New element "%s" added to the Microgrid (ID=#%d)\n', mgElement.getClassName(), mgElement.getId());
			end
		end
		
		function removeMGElement(this, input)
		% Removes an MGElement from the simulation using its ID or its own reference.
		%
		% Examples:
		% microgrid.removeMGElement(5) removes the MGElement #5
		% microgrid.removeMGElement(battery) reads the battery ID and then removes it.
			if microgrid_model.MGElement.isMGElement(input)
				id = input.getId();
			else
				id = input;
			end
			
			if this.DEV
				util.CommonsUtil.log('Removing element #%d... ', id);
			end
			
			mgElements = this.getMGElements();
			for i = 1:length(mgElements)
				mgElement = mgElements{i};
				
				if mgElement.getId() == id
					this.mgElements(i) = [];
					
					if this.DEV
						util.CommonsUtil.log(' Done!.\n');
					end
					return;
				end
			end
			
			if this.DEV
				util.CommonsUtil.log('No element found.\n');
			end
		end
		% ^^ FUNCTIONALITIES
	end
		
	methods(Access = protected)
		
		% VV IMPLEMENTATION OF ABSTRACT METHODS
		function updateTimeInfo(this, timeArray)
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/updateTimeInfo')">MGElement.updateTimeInfo()</a>
			this.setTimeArray(timeArray);
		end
		
		%override
		function modelStr = getEquationsModel(this)
		% API developers' use only
		%
		% Adds all the cost and power variables to the model.
			modelStr = this.getEquationsModel@microgrid_model.MGElement();
			
			% starts by inserting the Microgrid's cost variables, removing
			% leading summation + operators
			costSummation = regexprep(this.getCostVariable(), '^\+', '');
			
			% inserts the Microgrid's power variables
			powerSummation = regexprep(this.getPowerVariable(), '^\+', '');
			
			% inserts all the active MGElements' variables
			mgElements = this.getMGElements();
			for i = 1:length(mgElements)
				mgElement = mgElements{i};
				
				if mgElement.getActive()
					costSummation  = strcat(costSummation,  mgElement.getCostVariable());
					powerSummation = strcat(powerSummation, mgElement.getPowerVariable());
				end
			end
			
			% replaces it on the model
			modelStr = strrep(modelStr, this.COST_VARIABLES_PLACEHOLDER, costSummation);
			modelStr = strrep(modelStr, this.POWER_VARIABLES_PLACEHOLDER, powerSummation);
		end
		
		function flushVariables(this)
		% API developers' use only
		% 
		% See also: <a href="matlab:doc('microgrid_model.MGElement/flushVariables')">MGElement.flushVariables()</a>
			this.addGlobalScalar('isIsland', double(this.isIsland));
		end
		
		function checkIsReadyForExecution(~)
		% API developers' use only
		%
		% Checks if the model is ready for execution and validates parameter values. Throws error if not.
			return;
		end
		% ^^ IMPLEMENTATION OF ABSTRACT METHODS
	end
	
	methods(Access = private)
		% VV HELPER METHODS		
		function lastId = incrementLastId(this)
		% Increments the last MGElement ID
			lastId = this.lastId + 1;
			this.lastId = lastId;
		end
		% ^^ HELPER METHODS
	end
	
	methods(Access = public, Static)
		% VV PUBLIC HELPER METHODS
		function mustBeMicrogridObject(object)
		% Checks if a variable is instance of Microgrid (allows null). Throws error if not.
			import util.TypesUtil
			
			% this makes sure that an error is thrown if Microgrid is
			% renamed
			clazz = ?microgrid_model.Microgrid;
			clazz = clazz.Name;
			if ~TypesUtil.instanceof(object, clazz) && ~isempty(object)
				error('Variable "%s" must be %s instance.', inputname(1), clazz);
			end
		end
		% ^^ PUBLIC HELPER METHODS
	end
	
end
