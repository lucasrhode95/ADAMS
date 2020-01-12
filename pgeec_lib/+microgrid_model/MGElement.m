classdef (Abstract) MGElement < handle
	% Generic Microgrid (MG) Element. MG elements can be easily implemented by extending this class.
	%
	% MATLAB conventions adopted (inspired by Java environment)
	%   - all models have default values for all their properties
	%   - the use of MATLAB +packages (I very much regret it, tho)
	%   - generic models are named only with the physical element name, specific models append the model name or the author of it. e.g. Battery is the generic abstract class, BatteryHan is the concrete model.
	%   - camelCase for variable/method naming, PascalCase for classes and all-caps SNAKE_CASE for constants.
	%   - simulation attributes are public
	%   - if it can be made private, it should be made private (same goes for protected) unless it's a naturally public property (like model parameters)
	%   - all attributes are validated and sanitized before the simulation is run
	%   - the summary of protected methods and attributes are marked with "API developers' use only"
	%   - variable description placed above it, not on its side
	%   - links provided whenever important/interesting
	%   - tab spacing and lots of comments
	%   - logging on everything (even to the point of being too verbose (sorry))
	%   
	% GAMS conventions adopted:
	%   - two files for each model: parameters & equations
	%   - file naming: <physical-element-name>_<model-name-or-author>_<parameters|equations>.gms
	%   - keyworks always written in ALL CAPS
	%
	% See also: microgrid_model
	
	properties(Access = public)
		% Element count: if you want N copies of the same model is way more efficient to use this value than to create multiple instances (1)
		quantity  {mustBePositive(quantity), mustBeInteger(quantity)} = 1;
		
		% Whether or not this element is active on the microgrid - if set to false, the element is not added/considered on the simulation. (true)
		active {util.TypesUtil.mustBeLogical(active)} = true;
	end
	
	properties(Constant, Access = protected)
		% API developers' use only
		%
		% Placeholder to the MGElement's ID, append this to the end of your
		% GAMS variable. When the model is run, this symbol is replaced by
		% the element's ID, so that instances of the same MGElement model
		% with different parameters (_#_)
		ID_PLACEHOLDER = '_#_';
		
		% API developers' use only
		%
		% Folder that contains the .gms model files (+microgrid/+models/),
		% considering that the +pgeec_framework package is on MATLAB's path
		MODELS_PATH = ['+microgrid_model', filesep, '+models', filesep];
		
		% API developers' use only
		%
		% Placeholder replaced by the absolute path of the +models. This is
		% useful to use GAMS' $include command
		MODELS_PATH_PLACEHOLDER = '#MODELS_PATH#';
	end
	
	% Each model should have a parameter declaration file and an equation
	% definition file. This is need because they are loaded at different
	% points of execution.
	properties(Constant, Access = protected, Abstract)
		% API developers' use only
		%
		% File that will be loaded BEFORE the $gdxin GAMS statement. This
		% should concern only the programmer creating a new
		% MGElement-extended class.
		PARAMETERS_FILE;
		
		% API developers' use only
		%
		% File that will be loaded AFTER the $gdxin GAMS statement. This
		% should concern only the programmer creating a new
		% MGElement-extended class.
		EQUATIONS_FILE;
		
		% API developers' use only
		%
		% If a model extends another, this where you define the parent's
		% parameter file. If left empty, the framework does nothing.
		% (Default value = [])
		% This file will be loaded right before the child's. Default = none
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.PARAMETERS_FILE')">MGElement.PARAMETERS_FILE</a>
		SUPER_PARAMETERS_FILE;
		
		% API developers' use only
		%
		% If a model extends another, this where you define the parent's
		% equation file. If left empty, the framework does nothing.
		% (Default value = [])
		% This file will be loaded right before the child's.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		SUPER_EQUATIONS_FILE;
		
		% API developers' use only
		%
		% This should concern only the developer creating a new
		% MGElement-extended class, not left to the end-user.
		%
		% When defining a new MGElement is usual that it adds costs or
		% revenues to the total MG operation. These values ought to be
		% informed here, so that the <a href="matlab:doc('microgrid_model.CentralController')">CentralController</a> 
		% can correctly account for it.
		%
		% When defining these variables is important to inform the sign of
		% it as well. The engine understands + as costs and - as revenue.
		% Is also important to set the ID placeholder for your variable, so
		% that the end user can add multiple instances of the element with
		% no name conflicts
		%
		% Examples:
		%
		% COST_VARIABLE = ['+dieselGenFuelCost_#_(t)']
		% COST_VARIABLE = ['-energySales_#_(t)']
		% COST_VARIABLE = ['+cost_#_(t)-revenue_#_(t)']
		% where _#_ is the <a href="matlab:doc('microgrid_model.MGElement.ID_PLACEHOLDER')">ID placeholder</a>
		COST_VARIABLE;
		
		% API developers' use only
		%
		% This should concern only the developer creating a new
		% MGElement-extended class, not left to the end-user.
		%
		% When defining a new MGElement is usual that the element has a
		% power output variable, altering the microgrid's power-balance.
		% These values ought to be informed here, so that <a href="matlab:doc('microgrid_model.CentralController')">CentralController</a>
		% can correctly account for it.
		%
		% When defining these variables is important to inform the sign of
		% it as well. This string is going to be concatenated to the 
		% microgrid's power balance equation. When writing it, use + for
		% generation and - for loads.
		% Is also important to write all the variables with the ID
		% placeholder preppended so that the end user can add multiple
		% instances of the element without name conflicts.
		%
		% Examples:
		%
		% POWER_VARIABLE = ['+dieselGenOutputPower_#_(t)']
		% POWER_VARIABLE = ['-batteryChargingRate_#_(t)']
		% POWER_VARIABLE = ['+powerOut_#_(t)-load_#_(t)']
		% where _#_ is the <a href="matlab:doc('microgrid_model.MGElement.ID_PLACEHOLDER')">ID placeholder</a>
		POWER_VARIABLE;
	end
	
	properties(Access = private)
		% Unique identifier within a microgrid. Every MGElement that is added to a Microgrid object receives an ID number so that its variables can be uniquely named.
		id {mustBeInteger(id)} = 0;
		
		% GAMS communication object.
		%
		% MGElement uses GAMSModel class to interface with GAMS. The
		% CentralController is responsible for initializing it and by
		% passing a GAMSModel reference to each MGElement registered on the
		% Microgrid object.
		gamsObject gams.GAMSModel
		
		% The microgrid to which this MGElement belongs. I.e. every microgrid element knows its parent microgrid.
		%
		% When a call to CentralController.addMGElement(mgElement) is made,
		% mgElement receives and ID number and a CentralController object
		% reference.
% 		centralController {microgrid_model.CentralController.mustBeCentralController(centralController)};
		centralController microgrid_model.CentralController
		
		% Time array of the MGElement, should be the same across all MGElements.
		%
		% Before flushing the variables to the GAMS object, everyone
		% receives a copy of the CentralController time array via
		% MGElement.updateTimeInfo(timeArray).
		%
		% After the model has been run, all MGElements will have a copy of
		% the CentralController's time array. If not, the framework is
		% broken.
		timeArray {validateattributes(timeArray, {'numeric'}, {'nonnegative', 'increasing'})};
	end
	
	methods(Abstract, Access = public)
		
		% Returns an array containing the operational cost of the element at each discretization period.
		%
		% + for expenses, - for revenue.
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
		operationalCost = getOperationalCost(this);
		
		% Returns an array containing the net power flow of the element at each discretization period.
		%
		% + for generation, - for consumption
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
		netPowerOutput = getPowerOutput(this);
		
	end
	
	methods(Abstract, Access = protected)
		% API developers' use only
		%
		% Method called by CentralController when it's time for the MGElement to send all its variables to GAMS.
		flushVariables(this);
		
		% API developers' use only
		%
		% Method called before executing the optimization process.
		%
		% Implementers should check if the model dependencies are ready and
		% validate parameter values throwing meaningful error messages if
		% something is wrong.
		checkIsReadyForExecution(this);
		
		% API developers' use only
		%
		% When CentralController has finished calculating the time array
		% for the simulation, it is broadcasted to every MGElement through
		% this method.
		updateTimeInfo(this, timeArray);
	end
	
	methods(Access = public)
		
		% VV CONSTRUCTOR
		function this = MGElement()
		% If running in <a href="matlab:doc('microgrid_model.MGElement/developmentMode')">development mode</a>, logs a "New Model instantiated" message.
			if this.DEV
				util.CommonsUtil.log('New "%s" instantiated\n', this.getClassName());
			end
		end
		% ^^ CONSTRUCTOR
		
		function str = toString(this)
		% String representation of this object
			str = this.getClassName();
		end
		
		function totalCost = getTotalOperationalCost(this)
		% Returns the net operational cost of the element over the entire simulation period
			totalCost = sum(this.getOperationalCost());
		end
		
		function setActive(this, active)
		% Sets the flag that tells if the MGElement is active or not. If set to false, the element will not be considered on the simulation.
			this.active = active;
		end
		function active = getActive(this)
		% Returns the flag that tells if the MGElement is active or not. If set to false, the element will not be considered on the simulation.
			active = this.active;
		end
	end
	
	methods(Access = public, Sealed = true)
		function clazz = getClassName(this)
		% Returns the class name of the MGElement
			clazz = class(this);
			clazz = util.StringsUtil.split(clazz, '.');
			clazz = clazz{end};
		end
		
		% VV PUBLIC GETTERS
		function timeArray = getTimeArray(this)
		% Returns the time array of the MGElement.
		%
		% Before flushing the variables to the GAMS object, everyone
		% receives a copy of the <a href="microgrid_model.CentralController">CentralController</a> time array via
		% <a href="microgrid_model.MGElement/updateTimeInfo">MGElement.updateTimeInfo(timeArray)</a>.
		%
		% After the model has been run, all MGElements will have a copy of
		% the CentralController's time array. If not, the framework is
		% broken.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/setTimeArray')">MGElement.setTimeArray()</a>, <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			timeArray = this.timeArray;
		end
		
		function id = getId(this)
		% API developers' use only
		%
		% Returns the MGElement identifier (unique within a Microgrid).
			id = this.id;
		end
		% ^^ PUBLIC GETTERS
	end
	
	methods(Access = protected)
		% VV GETTERS AND SETTERS
		function horizon = getHorizon(this)
		% API developers' use only
		%
		% Returns duration of the timeArray (0 if it's empty).
			t = this.getTimeArray();
			
			if isempty(t)
				horizon = 0;
			else
				horizon = t(end);
			end
		end
		
		function setTimeArray(this, timeArray)
		% API developers' use only
		%
		% Sets the time array of the MGElement.
		%
		% Before flushing the variables to the GAMS object, everyone
		% receives a copy of the <a href="microgrid_model.CentralController">CentralController</a> time array via
		% <a href="microgrid_model.MGElement/updateTimeInfo">MGElement.updateTimeInfo(timeArray)</a>.
		%
		% After the model has been run, all MGElements will have a copy of
		% the CentralController's time array. If not, the framework is
		% broken.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/getTimeArray')">MGElement.getTimeArray()</a>, <a href="matlab:doc('microgrid_model.CentralController/getTime')">CentralController.getTime()</a>
			this.timeArray = timeArray;
		end
		
		function setGamsObject(this, gamsObject)
		% API developers' use only
		%
		% Set the GAMSModel object used to communicate with GAMS software
		%
		% See also: <a href="matlab:doc('gams.GAMSModel')">GAMSModel</a>
			this.gamsObject = gamsObject;
		end
		function gamsObject = getGamsObject(this)
		% API developers' use only
		%
		% Returns the currently handle used to communicate with GAMS software.
		%
		% See also: <a href="matlab:doc('gams.GAMSModel')">GAMSModel</a>
			gamsObject = this.gamsObject;
		end
		
		function setId(this, id)
		% API developers' use only
		%
		% Sets the MGElement identifier (unique within a Microgrid).
			this.id = id;
		end
		
		function modelStr = getParametersModel(this)
		% API developers' use only
		%
		% Builds the parameters file from the template informed by
		% the constant PARAMETERS_FILE and replaces all the id
		% placeholders by the actual MGElement's ID.
			modelStr = sprintf('%s\n\n%s', this.getModelStr(this.SUPER_PARAMETERS_FILE, false) ...
										 , this.getModelStr(this.PARAMETERS_FILE));
		end
		function modelStr = getEquationsModel(this)
		% API developers' use only
		%
		% Builds the equations file from the template informed by
		% the constant EQUATIONS_FILE and replaces all the id
		% placeholders by the actual MGElement's ID.
			modelStr = sprintf('%s\n\n%s', this.getModelStr(this.SUPER_EQUATIONS_FILE, false) ...
										 , this.getModelStr(this.EQUATIONS_FILE));
		end
		
		function variableStr = getPowerVariable(this)
		% API developers' use only
		%
		% Replaces the id placeholder on the constant POWER_VARIABLE by the
		% actual MGElement's ID.
			if ~isempty(this.POWER_VARIABLE)
				variableStr = this.insertId(this.POWER_VARIABLE);
			else
				variableStr = '';
				
				% if in development mode, warns the programmer
				if this.DEV && this.WARNINGS
					warning('Class "%s" has no power variable defined.', this.getClassName());
				end
			end
		end
		function variableStr = getCostVariable(this)
		% API developers' use only
		%
		% Replaces the id placeholder on the constant COST_VARIABLE by the
		% actual MGElement's ID.
			if ~isempty(this.COST_VARIABLE)
				variableStr = this.insertId(this.COST_VARIABLE);
			else
				variableStr = '';
				
				% if in development mode, warns the programmer
				if this.DEV && this.WARNINGS
					warning('Class "%s" has no cost variable defined.', this.getClassName());
				end
			end
		end
		
		function centralController = getCentralController(this)
		% API developers' use only
		%
		% Returns the CentralController object that this MGElement belongs to. 
			centralController = this.centralController;
		end
		function setCentralController(this, centralController)
		% API developers' use only
		%
		% Sets the Microgrid object that this MGElement is inserted on.
			this.centralController = centralController;
		end
		% ^^ GETTERS AND SETTERS
	end
	
	methods(Access = protected, Sealed = true)
		% VV HELPER METHODS
		
		function devMode = DEV(~)
		% API developers' use only
		%
		% Method designed to act as a local constant
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/developmentMode')">MGElement.developmentMode()</a>
			devMode = microgrid_model.MGElement.developmentMode();
		end
		
		function warningsOn = WARNINGS(~)
		% API developers' use only
		%
		% Method designed to act as a global variable turning warnings on and off.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/warningsOn')">MGElement.warningsOn()</a>
			warningsOn = microgrid_model.MGElement.warningsOn();
		end
		
		function [name, varargin] = addGlobalVariablePreamble(this, name, varargin)
		% API developers' use only
		%
		% Method executed before adding any new global variable.
			if ~this.getActive()
				error('MGElement "%s" is not active. It must be activated in order to add variables.', this.getClassName());
			end
		end
		
		function [name, varargin] = addVariablePreamble(this, name, varargin)
		% API developers' use only
		%
		% Method executed before adding any new variable.
			if ~this.getActive()
				error('MGElement "%s" is not active. It must be activated in order to add variables.', this.getClassName());
			end
		
			name = strcat(name, num2str(this.getId()));
			
			for i = 1:length(varargin)
				varargin{i} = this.insertId(varargin{i});
			end
		end
		
		function [name, varargin] = readVariablePreamble(this, name, varargin)
		% API developers' use only
		%
		% Method executed before reading any variable.
			if ~this.getActive()
				error('MGElement "%s" is not active. It must be activated in order to retrieve variables.', this.getClassName());
			elseif isempty(this.getGamsObject())
				error('GAMS interface not initialized. Long shot guess: you forgot to add "%s" to the simulation or tried to read an output variable without running the model.', this.getClassName());
			elseif ~this.getGamsObject().getIsReadyForExport()
				error('Model not ready to export data. That''s all we know.');
			end
		
			% concatenates the ID placeholder _#_ to the variable name
			name = strcat(name, num2str(this.getId()));
			
			% replaces the ID placeholder _#_ on all Domain Sets of this
			% variable
			for i = 1:length(varargin)
				varargin{i} = this.insertId(varargin{i});
			end
		end
		
		function [name, varargin] = readGlobalVariablePreamble(this, name, varargin)
		% API developers' use only
		%
		% Method executed before reading any global variable.
			if ~this.getActive()
				error('MGElement "%s" is not active. It must be activated in order to retrieve variables.', this.getClassName());
			elseif isempty(this.getGamsObject())
				error('GAMS interface not initialized. Long shot guess: you forgot to add "%s" to the simulation or tried to read an output variable without running the model.\nSee <a href="matlab:doc(''microgrid_model.CentralController/run'')">CentralController.run()</a>', this.getClassName());
			elseif ~this.getGamsObject().getIsReadyForExport()
				error('Model not ready to export data. That''s all we know.');
			end
		end
		% ^^ HELPER METHODS
		
		% VV VARIABLE WRITING
		function addGlobalSet(this, name,  declaration, varargin)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('gams.GAMSModel/addSet')">GAMSModel.addSet(name, declaration, varargin)</a>. Doesn't replace any ID placeholder.
			[name, varargin] = this.addGlobalVariablePreamble(name, varargin{:});
			
			this.getGamsObject().addSet(name, declaration, varargin{:});
		end
		
		function addGlobalScalar(this, name,  value)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('gams.GAMSModel/addScalar')">GAMSModel.addScalar(name, value)</a>. Doesn't replace any ID placeholder.
			name = this.addGlobalVariablePreamble(name);
			
			this.getGamsObject().addScalar(name, value);
		end
		
		function addGlobalParameter(this, name,  declaration, varargin)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('gams.GAMSModel/addParameter')">GAMSModel.addParameter(name, value, varargin)</a>. Doesn't replace any ID placeholder.
			[name, varargin] = this.addGlobalVariablePreamble(name, varargin{:});
			
			this.getGamsObject().addParameter(name, declaration, varargin{:});
		end
		
		function addSet(this, name,  declaration, varargin)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('gams.GAMSModel/addSet')">GAMSModel.addSet(name, declaration, varargin)</a> with the added funcionality of automatically appending the _#_ ID placeholder to the variable name and replacing _#_ by the own ID on the domain sets.
			[name, varargin] = this.addVariablePreamble(name, varargin{:});
			
			this.getGamsObject().addSet(name, declaration, varargin{:});
		end
		
		function addScalar(this, name,  value)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('gams.GAMSModel/addScalar')">GAMSModel.addScalar(name, value)</a> with the added funcionality of automatically appending the _#_ ID placeholder to the variable name and replacing _#_ by the own ID on the domain sets.
			name = this.addVariablePreamble(name);
			
			this.getGamsObject().addScalar(name, value);
		end
		
		function addParameter(this, name,  declaration, varargin)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('gams.GAMSModel/addParameter')">GAMSModel.addParameter(name, value, varargin)</a> with the added funcionality of automatically appending the _#_ ID placeholder to the variable name and replacing _#_ by the own ID on the domain sets.
			[name, varargin] = this.addVariablePreamble(name, varargin{:});
			
			this.getGamsObject().addParameter(name, declaration, varargin{:});
		end
		
		function timeAddGlobalSet(this, name, declaration)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('microgrid_model.Microgrid/addGlobalSet')">Microgrid.addGlobalSet(name, declaration)</a> with the added funcionality of automatically defining the variable as time-dependant 
			this.addGlobalSet(name, declaration, microgrid_model.CentralController.TIME_VARIABLE);
		end
		
		% there's no timeAddGlobalScalar because scalars don't have domain sets
		
		function timeAddGlobalParameter(this, name, declaration)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('microgrid_model.Microgrid/addGlobalParameter')">Microgrid.addGlobalParameter(name, declaration)</a> with the added funcionality of automatically defining the variable as time-dependant 
			this.addGlobalParameter(name, declaration, microgrid_model.CentralController.TIME_VARIABLE);
		end
		
		function timeAddSet(this, name, declaration)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('microgrid_model.Microgrid/addSet')">Microgrid.addSet(name, declaration)</a> with the added funcionality of automatically defining the variable as time-dependant 
			this.addSet(name, declaration, microgrid_model.CentralController.TIME_VARIABLE);
		end
		
		% there's no timeAddScalar because scalars don't have domain sets.
		
		function timeAddParameter(this, name, declaration)
		% API developers' use only
		%
		% Gateway to <a href="matlab:doc('microgrid_model.Microgrid/addParameter')">Microgrid.addParameter(name, declaration)</a> with the added funcionality of automatically defining the variable as time-dependant 
			this.addParameter(name, declaration, microgrid_model.CentralController.TIME_VARIABLE);
		end
		% ^^ VARIABLE WRITING
		
		% VV VARIABLE READING
		function [value, labeled] = timeRead(this, name)
		% API developers' use only
		% Gateway to <a href="matlab:doc('microgrid_model.Microgrid/read')">Microgrid.read(name)</a> with the added funcionality of automatically defining the variable as time-dependant 
			[value, labeled] = this.read(name, microgrid_model.CentralController.TIME_VARIABLE);
		end
		
		function [value, labeled] = timeReadGlobal(this, name)
		% API developers' use only
		% Gateway to <a href="matlab:doc('microgrid_model.Microgrid/readGlobal')">Microgrid.readGlobal(name)</a> with the added funcionality of automatically defining the variable as time-dependant 
			[value, labeled] = this.readGlobal(name, microgrid_model.CentralController.TIME_VARIABLE);
		end
		
		function [value, labeled] = read(this, name, varargin)
		% API developers' use only
		% Gateway to <a href="matlab:doc('gams.GAMSModel/read')">GAMSModel.read(name, domainSet)</a> with the added funcionality of automatically appending the _#_ ID placeholder to the variable name and replacing _#_ by the own ID on the domain sets.
			[name, varargin] = this.readVariablePreamble(name, varargin{:});
			
			[value, labeled] = this.getGamsObject().read(name, varargin{:});
		end
		
		function [value, labeled] = readGlobal(this, name, varargin)
		% API developers' use only
		% Gateway to <a href="matlab:doc('gams.GAMSModel/read')">GAMSModel.read(name, domainSet)</a> with the added funcionality of automatically appending the _#_ ID placeholder to the variable name and replacing _#_ by the own ID on the domain sets.
			[name, varargin] = this.readGlobalVariablePreamble(name, varargin{:});
			
			[value, labeled] = this.getGamsObject().read(name, varargin{:});
		end
		% ^^ VARIABLE READING
	end
	
	methods(Access = private)
		
		% VV HELPER METHODS		
		function modelStr = getModelStr(this, modelPath, warningIfEmpty)
		% Returns the string of either the parameters model or the equations model (according to Path) with the ID placeholder already replaced.
			import util.StringsUtil
			import util.FilesUtil
			import util.TypesUtil
			
			if nargin >= 3
				TypesUtil.mustBeLogical(warningIfEmpty)
			else
				warningIfEmpty = true;
			end
			
			% checks if path is empty (allowed, since there are microgrid
			% elements that don't need equations and/or parameters)
			if isempty(modelPath)
				modelStr = '';
				
				% if running in development mode, warns the programmer
				if this.DEV && this.WARNINGS && warningIfEmpty
					warning('Model path empty on class "%s".', this.getClassName());
				end
				
				return;
			end
		
			modelPath = strrep(modelPath, '/', filesep);
			modelPath = strrep(modelPath, '\', filesep);
			
			if ~StringsUtil.startsWith(modelPath, this.MODELS_PATH)
				modelPath = [this.MODELS_PATH, modelPath];
			end
			
			% replaces the id placeholders by actual MGElement's ID
			modelStr = this.insertId(fileread(modelPath));
		end
		
		function text = insertId(this, text)
		% Replaces the ID placeholder _#_ by the current ID of this MGElement.
			text = strrep(text, this.ID_PLACEHOLDER, num2str(this.getId()));
		end
		% ^^ HELPER METHODS
	end
	
	methods(Static)
		function [out, clazz] = isMGElement(object)
			import util.TypesUtil
			
			% this makes sure that an error is thrown if MGElement is
			% renamed
			clazz = ?microgrid_model.MGElement;
			clazz = clazz.Name;
			
			out = TypesUtil.instanceof(object, clazz);
		end
		
		function mustBeMGElement(object)
		% Checks if a variable is instance of MGElement (allows null). Throws error if not.
			[isMGElement, clazz] = microgrid_model.MGElement.isMGElement(object);
			
			if ~isMGElement && ~isempty(object)
				error('Variable "%s" must instance of %s.', inputname(1), clazz);
			end
		end
		
		function warningsOn = warningsOn(warningsOn)
		% Getter/setter of a flag shared between all MGElements indicating whether or not to use warnings (true)
		%
		% This method was made static so that all the MGElements access the
		% same value
		%
		% <a href="matlab:doc('microgrid_model.MGElement/WARNINGS')">MGElement.WARNINGS()</a> method on the other hand is just a mirror to this
		% method so that children dont need to use the fully qualified path
			persistent persistentWarningOn;
		
			if nargin >= 1
				util.TypesUtil.mustBeLogical(warningsOn);
				persistentWarningOn = warningsOn;
			else
				if isempty(persistentWarningOn)
					persistentWarningOn = true;
				end
			end
			
			warningsOn = persistentWarningOn;
		end

		function isDev = developmentMode(isDev)
		% Getter/setter of a flag shared between all MGElements indicating whether or not to run in development mode, with verbose logging (false)
		%
		% This method was made static so that every MGElement can access its
		% value
		%
		% <a href="matlab:doc('microgrid_model.MGElement/DEV')">MGELEMENT.DEV()</a> method on the other hand is just a mirror to this
		% method so that children dont need to use the fully qualified path
			persistent persistentIsDev;
		
			if nargin >= 1
				util.TypesUtil.mustBeLogical(isDev);
				persistentIsDev = isDev;
			else
				if isempty(persistentIsDev)
					persistentIsDev = false;
				end
			end
			
			isDev = persistentIsDev;
		end
	end
	
end

