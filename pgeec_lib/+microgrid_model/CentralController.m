classdef CentralController < microgrid_model.MGElement
	% Class that represents a centralized Microgrid Central Controller (MGCC), controlling the flow of execution.
	%
	% - Synchronizes the clock of everyone
	% - Organizes method calls to dynamically create a GAMS .gms file that will be executed.
	% - Makes sure no temporary files are left behind after it's destroyed
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
		% Flag indicating whether or not this controller should remove or keep its temporary files (false)
		KEEP_FILES {util.TypesUtil.mustBeLogical(KEEP_FILES)} = false;
		
		% Sets the optCr parameter of the underlying MIP solver used, i.e. the relative tolerance of the solution's optimality [0 - 1] (0.1)
		relativeErrorTolerance {util.TypesUtil.mustBeBetween(relativeErrorTolerance, 0, 1)} = 0;
		
		% Size of each interval for the first half hour of simulation [multiples (integers or not) of 30, >=5 subject to rounding] (5)
		step1stHalfHour {mustBePositive(step1stHalfHour)} =  5;
		
		% Size of each interval for the second half hour of simulation [multiples (integers or not) of 30, >=5 subject to rounding] (30)
		step2ndHalfHour {mustBePositive(step2ndHalfHour)} = 30;
		
		% Size of each interval of the simulation, except the first hour (See also: <a href="matlab:doc('microgrid_model.Microgrid/step1stHalfHour')">Microgrid.step1stHalfHour</a> and <a href="matlab:doc('microgrid_model.Microgrid/step2ndHalfHour')">Microgrid.step2ndHalfHour</a>) [not subject to rounding, >=5 minutes] (60)
		stepDefault {mustBePositive(stepDefault)} = 60;
		
		% The time the simulation should start [minutes] (0)
		%
		% Note:
		% The simulation time is counted from midnight on, meaning that a
		% value of t0=65 means that the simulation will start at 01:05am
		t0 {mustBeNonnegative(t0)} = 0;
		
		% Flag indicating if the simulation is to be run at weekend tariffs (false)
		isWeekend {util.TypesUtil.mustBeLogical(isWeekend)} = false;
		
		% Array that indicates the beggining and end of each intermediate tarrif period [minute of day, <= 1440]
		periodIntermediate {validateattributes(periodIntermediate, {'numeric'}, {'integer', 'positive', '<=', 1440, 'ncols', 2})} = [17, 18; 21, 22]*60;
		
		% Array that indicates the beggining and end of each peak tarrif period [minute of day, <= 1440]
		periodPeak {validateattributes(periodPeak, {'numeric'}, {'integer', 'positive', '<=', 1440, 'ncols', 2})} = [18, 21]*60;
		
		% Hired demand for the off-peak period [kW];
		hiredDemandOffPeak {validateattributes(hiredDemandOffPeak, {'numeric'}, {'scalar'})} = 24.7577;
		
		% Hired demand for the intermediate period [kW]
		hiredDemandIntermediate {validateattributes(hiredDemandIntermediate, {'numeric'}, {'scalar'})} = 24.7577;
		
		% Hired demand for the peak period [kW]
		hiredDemandPeak {validateattributes(hiredDemandPeak, {'numeric'}, {'scalar'})} = 20;
		
		% Intended duration of the simulation. If left to 0, the demand curves will determine its value [subject to rounding to obey <a href="matlab:doc('microgrid_model.CentralController/stepDefault')">CentralController.stepDefault</a>, minutes] (24)
		intendedHorizon {mustBeNonnegative(intendedHorizon), mustBeInteger(intendedHorizon)} = 1440;
	end
	
	% prices - there were so many (18) we had them put here separately
	properties(Access = public)
		
		% VV---------- SELL
		
		% price for selling power to the microgrid @week days @peak [any $ unit/kWh] (0.2 R$/kWh)
		tariffSellWdayPeak {validateattributes(tariffSellWdayPeak, {'numeric'}, {'nonnegative'})} = 0.2;
		
		% price for selling power to the microgrid @week days @intermediate [any $ unit/kWh] (0.2 R$/kWh)
		tariffSellWdayIntermediate {validateattributes(tariffSellWdayIntermediate, {'numeric'}, {'nonnegative'})} = 0.2;
		
		% price for selling power to the microgrid @week days @off-peak [any $ unit/kWh] (0.2 R$/kWh)
		tariffSellWdayOffPeak {validateattributes(tariffSellWdayOffPeak, {'numeric'}, {'nonnegative'})} = 0.2;
		
		% price for selling power to the microgrid @weekends @peak [any $ unit/kWh] (0.2 R$/kWh)
		tariffSellWendPeak {validateattributes(tariffSellWendPeak, {'numeric'}, {'nonnegative'})} = 0.2;
		
		% price for selling power to the microgrid @weekends days @intermediate [any $ unit/kWh] (0.2 R$/kWh)
		tariffSellWendIntermediate {validateattributes(tariffSellWendIntermediate, {'numeric'}, {'nonnegative'})} = 0.2;
		
		% price for selling power to the microgrid @weekends days @off-peak [any $ unit/kWh] (0.2 R$/kWh)
		tariffSellWendOffPeak {validateattributes(tariffSellWendOffPeak, {'numeric'}, {'nonnegative'})} = 0.2;
		
		% VV---------- PURCHASE
		
		% price for selling power to the microgrid @week days @peak [any $ unit/kWh] (0.47987 R$/kWh)
		tariffPurcWdayPeak {validateattributes(tariffPurcWdayPeak, {'numeric'}, {'nonnegative'})} = 0.47987;
		
		% price for purchasing power to the microgrid @week days @intermediate [any $ unit/kWh] (0.29908 R$/kWh)
		tariffPurcWdayIntermediate {validateattributes(tariffPurcWdayIntermediate, {'numeric'}, {'nonnegative'})} = 0.29908;
		
		% price for purchasing power to the microgrid @week days @off-peak [any $ unit] (0.29908 R$/kWh)
		tariffPurcWdayOffPeak {validateattributes(tariffPurcWdayOffPeak, {'numeric'}, {'nonnegative'})} = 0.29908;
		
		% price for purchasing power to the microgrid @weekends @peak [any $ unit] (0.29908 R$/kWh)
		tariffPurcWendPeak {validateattributes(tariffPurcWendPeak, {'numeric'}, {'nonnegative'})} = 0.29908;
		
		% price for purchasing power to the microgrid @weekends days @intermediate [any $ unit] (0.29908 R$/kWh)
		tariffPurcWendIntermediate {validateattributes(tariffPurcWendIntermediate, {'numeric'}, {'nonnegative'})} = 0.29908;
		
		% price for purchasing power to the microgrid @weekends days @off-peak [any $ unit] (0.29908 R$/kWh)
		tariffPurcWendOffPeak {validateattributes(tariffPurcWendOffPeak, {'numeric'}, {'nonnegative'})} = 0.29908;
		
		% VV---------- FINE FOR EXCEEDING POWER
		
		% fine for exceeding hired demand @week days @peak [any $ unit/kWh] (57.7 R$/kW)
		fineWdayPeak {validateattributes(fineWdayPeak, {'numeric'}, {'nonnegative'})} = 57.7;
		
		% fine for exceeding hired demand @week days @intermediate [any $ unit/kWh] (17.64 R$/kW)
		fineWdayIntermediate {validateattributes(fineWdayIntermediate, {'numeric'}, {'nonnegative'})} = 17.64;
		
		% fine for exceeding hired demand @week days @off-peak [any $ unit] (17.64 R$/kW)
		fineWdayOffPeak {validateattributes(fineWdayOffPeak, {'numeric'}, {'nonnegative'})} = 17.64;
		
		% fine for exceeding hired demand @weekends @peak [any $ unit] (17.64 R$/kW)
		fineWendPeak {validateattributes(fineWendPeak, {'numeric'}, {'nonnegative'})} = 17.64;
		
		% fine for exceeding hired demand @weekends days @intermediate [any $ unit] (8.82 R$/kWh)
		fineWendIntermediate {validateattributes(fineWendIntermediate, {'numeric'}, {'nonnegative'})} = 8.82;
		
		% fine for exceeding hired demand @weekends days @off-peak [any $ unit] (8.82 R$/kWh)
		fineWendOffPeak {validateattributes(fineWendOffPeak, {'numeric'}, {'nonnegative'})} = 8.82;
	end
	
	properties(Constant, Access = public)
		% API developers' use only
		%
		% Name of the global variable that holds the time indices
		TIME_VARIABLE = 't';
	end
	
	properties(Constant, Access = private)
		
		% Whether or not weekends are off-peak exclusively
		%
		% This is motivated by the fact that some countries consider
		% weekends as off-peak demand
		WEEKEND_IS_OFF_PEAK = true;
		
		% Minimal time step allowed [minutes]
		MINIMAL_TIME_STEP = 1;
		
		% Minimal horizon allowed [minutes]
		MINIMAL_HORIZON = 60;
	end
	
	properties(Constant, Access = protected)
		% API developers' use only.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.PARAMETERS_FILE')">MGElement.PARAMETERS_FILE</a>
		PARAMETERS_FILE = 'central-controller_quites_parameters.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.EQUATIONS_FILE')">MGElement.EQUATIONS_FILE</a>
		EQUATIONS_FILE  = 'central-controller_quites_equations.gms';
		
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
		COST_VARIABLE   = [];
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.POWER_VARIABLE')">MGElement.POWER_VARIABLE</a>
		POWER_VARIABLE  = [];
	end
	
	properties(Constant, Access = private)
		% Pattern used to substitute the value of the relative error tolerance on the .gms template file
		RELATIVE_ERROR_PLACEHOLDER = '#RELATIVE_ERROR#';
			 
		% Label used for weekends
		WEEKEND_LABEL = 'weekend';
		
		% Label used for weekdays
		WEEKDAY_LABEL = 'weekday';
		
		% Labels used for week days
		WEEK_LABELS = {'weekend', 'weekday'};
		
		% Peak or off-peak demand strings used
		PERIOD_LABELS = {'peak', 'intermediate', 'off-peak'};
		
		% Label used to describe the off peak tariff period
		OFF_PEAK_LABEL = 'off-peak';
		
		% Label used to describe the intermediate tariff period
		INTERMEDIATE_LABEL = 'intermediate';
		
		% Label used to describe the peak tariff period
		PEAK_LABEL = 'peak';
		
		
		
		% Name of the file that will be dynamically created by CentralController
		%
		% Here #TIMESTAMP# will be replaced by the timestamp at the time of
		% execution, this is done to minize the risks of name collision
		% when multiple models are run in parallel
		GAMS_TMP_FILE_TEMPLATE = 'mgcc_#TIMESTAMP#.gms';
		
		% Name of the variable loader file that will be dynamically created by GAMSModel
		%
		% Here #TIMESTAMP# will be replaced by the timestamp at the time of
		% execution, this is done to minize the risks of name collision
		% when multiple models are run in parallel
		LOADER_FILE_TEMPLATE   = 'loader_#TIMESTAMP#.gms';
	end
	
	properties(Access = private)
		% Microgrid object reference, used to micro-manage the MGElements.
		%
		% See also: Microgrid
		microgrid microgrid_model.Microgrid;
		
		% Path to the temporary file that will be created and sent to GAMS (buit dynamically)
		gamsTmpFile {util.TypesUtil.mustBeTxt(gamsTmpFile)} = '';
		
		% Path to the temporary loader.gms file (buit dynamically)
		varLoaderFile {util.TypesUtil.mustBeTxt(varLoaderFile)} = '';
		
		% Size of each interval [minutes]
		dtArray {validateattributes(dtArray, {'numeric'}, {'2d'})};
		
		% Interval numbers vs peak demand times
		periodMapping {util.TypesUtil.mustBeCellArray(periodMapping)} = util.TypesUtil.emptyCellArray;
		
		% Whether or not this model has already been executed, meaning it is ready to export data
		hasBeenRun {util.TypesUtil.mustBeLogical(hasBeenRun)} = false;
	end
	
	methods(Access = public)
		% VV CONSTRUCTOR && DESTRUCTOR
		function this = CentralController(microgrid, keepTempFiles)
		% Constructor that accepts 4 parameters: microgrid (required), debugMode (optional, default = false), keepTempFiles (optional, default = false), warningsOn (optional, default = true).
			import util.TypesUtil
			import util.CommonsUtil
			
			% super constructor
			this = this@microgrid_model.MGElement();
			
			% global settings
			if nargin >= 1
				this.setMicrogrid(microgrid);
			else
				% initializes the microgrid object
				this.setMicrogrid(microgrid_model.Microgrid());
			end
			if nargin >= 2
				TypesUtil.mustBeLogical(keepTempFiles);
				this.KEEP_FILES = keepTempFiles;
			end
			
			% generates a timestamp, used to create unique filenames
			timestamp = CommonsUtil.getTimestamp(true);
			
			% sets the file names that will be used to communicate with GAMS.
			this.setVarLoaderFile(strrep(this.LOADER_FILE_TEMPLATE, '#TIMESTAMP#', timestamp));
			this.setGamsTmpFile(strrep(this.GAMS_TMP_FILE_TEMPLATE, '#TIMESTAMP#', timestamp));
		end
		
		function delete(this)
		% Handles the deletion of this object after is no longer referenced
			import util.CommonsUtil
			
			if this.DEV
				CommonsUtil.log('Destroying unused CentralController object... ');
			end
			
			% removes temporary files
			if ~this.KEEP_FILES
				this.removeTempFiles();
			end
			
			if this.DEV
				CommonsUtil.log('Done!\n');
			end
		end
		% ^^ CONSTRUCTOR && DESTRUCTOR
		
		% VV Microgrid related methods
		function microgrid = getMicrogrid(this)
			if isempty(this.microgrid)
				this.setMicrogrid(microgrid_model.Microgrid());
			end
			
			microgrid = this.microgrid;
		end
		
		function addMGElement(this, mgElement)
		% Mirror to <a href="matlab:doc('microgrid_model.Microgrid/addMGElement')">Microgrid.addMGElement()</a>
			this.setHasBeenRun(false);
			this.getMicrogrid().addMGElement(mgElement);
		end
		
		function removeMGElement(this, input)
		% Mirror to <a href="matlab:doc('microgrid_model.Microgrid/removeMGElement')">Microgrid.removeMGElement()</a>
			this.getMicrogrid().removeMGElement(input);
		end
		
		function mgElements = getMGElements(this, varargin)
		% Returns a column-array with all the MGElements added to the microgrid controlled by this CentralController.
		%
		% Examples:
		% mgElements = model.GETMGELEMENTS() returns all MGElements added
		% to this Microgrid
		%
		% mgElements = model.GETMGELEMENTS(true) returns all active
		% MGElements
		%
		% Actually just a mirror to <a href="matlab:doc('microgrid_model.Microgrid/getMGElements')">Microgrid.getMGElements()</a>
			mgElements = this.getMicrogrid().getMGElements(varargin{:});
		end
		% ^^ Microgrid related methods
		
		% VV GETTERS AND SETTERS
		function hasBeenRun = getHasBeenRun(this)
		% Tells whether or not this model has been run and is ready to export data
		% Whenever a new MGElement is added to the simulation, this flag is
		% reset.
			hasBeenRun = this.hasBeenRun;
		end
		
		function timeArray = getTime(this)
		% Public method that reads and returns the time array used on the simulation process
		%
		% Examples:
		%
		% t = mgcc.GETTIME()
		% plot(t, microgrid.getHiredDemands())
			dt = this.timeReadGlobal('dt');
			timeArray = this.t0/60 + cumsum(dt);
		end
		
		function hiredDemand = getHiredDemand(this)
		% Returns the hired demand for each discretization period
			hiredDemand = this.readGlobal('demandas_contratadas', 'map_th');
		end
		
		function varLoaderFile = getVarLoaderFile(this)
		% Returns the name of the loader.gms file
			varLoaderFile = this.varLoaderFile;
		end

		function operationalCost = getOperationalCost(this)
		% Mirror to <a href="matlab:doc('microgrid_model.Microgrid/getOperationalCost')">Microgrid.getOperationalCost()</a>
			operationalCost = this.getMicrogrid().getOperationalCost();
		end

		function netPowerOutput = getPowerOutput(this)
		% Mirror to <a href="matlab:doc('microgrid_model.Microgrid/getPowerOutput')">Microgrid.getPowerOutput()</a>
			netPowerOutput = this.getMicrogrid().getPowerOutput();
		end
		
		function horizon = getActualHorizonInHours(this)
			horizon = this.getTime();
			horizon = horizon(end);
		end
		
		function tmpOutputPath = getTmpOutputPath(this)
		% Returns the path to the temporary GDX output file
			tmpOutputPath = this.getGamsObject().getTmpOutputPath();
		end
		
		function gdxContent = getTmpOutputBinary(this)
		% Returns the contents of the temporary GDX output file.
		%
		% This is a low-level method, meaning it doesn't check much for errors.
			gdxContent = util.FilesUtil.readBinary(this.getGamsObject().getTmpOutputPath());
		end
		
		function setTmpOutputBinary(this, binaryData)
		% Allows the user to manually set the temporary GDX output file.
		%
		% This is a low-level method, meaning it doesn't check much for errors.
			util.FilesUtil.writeBinary(this.getGamsObject().getTmpOutputPath(), binaryData);
		end
		% ^^ GETTERS AND SETTERS
		
		function totalTime = run(this)
		% Runs the optimization process.
		%
		% After all the elements of the Microgrid have been configured,
		% this method should be called to execute the model. It will:
		% - initialize the GAMS interface
		% - dynamically create the optimization variables and equations of every MG element
		% - simulate
		% - make the results available to every <a href="matlab:doc('microgrid_model.MGElement')">MGElement</a>
		%
		% See also: microgrid_model
			totalTime = 0;
			this.setHasBeenRun(false);
			try
				controllerTime = tic();

				import util.CommonsUtil
				if this.DEV
					CommonsUtil.log('Run process started.\n');
				end

				% dynamically creates the .gms file that GAMSModel will read.
				totalTime = totalTime + this.exportModelString(this.getGamsTmpFile());

				% once the model file is created and saved to disk, the GAMS
				% interface can be initialized
				this.initializeGamsObject();

				% sync everyone
				this.synchronizeHorizons();

				% builds the time arrays (t and dt)
				this.updateTimeArrays();

				% updates all the time-dependand variables
				this.updateTimeInfo();

				% flushes global variables
				this.flushVariables();

				% passes the variables from each MGElement to the GAMSModel
				% interface
				mgElements = [{this.getMicrogrid}; this.getMicrogrid().getMGElements(true)];
				for i = 1:length(mgElements)
					mgElement = mgElements{i};

					mgElement.setTimeArray(this.getTimeArray()); % makes sure everyone has a copy of the time array
					mgElement.updateTimeInfo(this.getTimeArray());
					mgElement.setGamsObject(this.getGamsObject());

					if this.DEV
						CommonsUtil.log('Flushing variables of MGElement #%d (%s)...\n', mgElement.getId(), mgElement.getClassName());
					end

					mgElement.flushVariables();

					if this.DEV
						CommonsUtil.log('Variables flushed.\n');
					end
				end

				% checks if everyone is ready for execution
				this.checkIsReadyForExecution();

				% executes
				totalTime = totalTime + this.getGamsObject().run();


				% removes temporary files
				if ~this.KEEP_FILES
					totalTime = totalTime + this.removeTempFiles(false);
				end

				% exec time
				totalTime = totalTime + toc(controllerTime);

				if this.DEV
					CommonsUtil.log('\n');
					CommonsUtil.log('Simulation finished in %0.3f s.\n', totalTime);
					CommonsUtil.log('\n');
				end
				
				this.setHasBeenRun(true);
			catch e
				if this.DEV
					CommonsUtil.log('\n');
					CommonsUtil.log('Simulation failed after %0.3f s.\n', totalTime);
					CommonsUtil.log('\n');
				end
				rethrow(e);
			end
		end
		
		function elapsedTime = exportExecutionReport(this, varargin)
		% Mirror to <a href="matlab:doc('gams.GAMSModel/exportExecutionReport')">GAMSModel.exportExecutionReport()</a>
			elapsedTime = this.getGamsObject().exportExecutionReport(varargin{:});
		end

		function elapsedTime = save(this, fileName, path)
		% Persists the current case to a file.
		% If <a href="matlab:doc('microgrid_model.CentralController/getHasBeenRun')">CentralController.getHasBeenRun()</a> is true, then this also
		% saves the results file, meaning that, when you reload this
		% object, you're gonna be able to read all the variables without
		% a call to <a href="matlab:doc('microgrid_model.CentralController/run')">CentralController.run()</a>.
		%
		% Examples:
		% mgcc.save('Case_1') will create the file Case_1.mat on the
		% current MATLAB directory
		
		% mgcc.save('Case_1', 'C:\simulation_cases\') will create the file
		% C:\simulation_cases\Case_1.mat
			elapsedTime = tic();
			
			% some logging
			if this.DEV
				util.CommonsUtil.log('Saving case... ');
			end
			
			% input sanitizing
			if nargin < 3
				path = '';
			end
			if ~util.StringsUtil.endsWith(fileName, '.mat')
				fileName = [fileName, '.mat'];
			end
			filePath = fullfile(path, fileName);
			
			mgcc = this;
			if this.getHasBeenRun()
				gdxFile = this.getTmpOutputBinary();
				save(filePath, 'mgcc', 'gdxFile');
			else
				save(filePath, 'mgcc');
			end
			
			elapsedTime = toc(elapsedTime);
			
			% some logging
			if this.DEV
				util.CommonsUtil.log('Done! %0.2g ms\n', elapsedTime*1000);
			end
		end
		
		function elapsedTime = exportModelString(this, filePath)
		% Exports the generated str model to a .txt file and returns the execution time.	
			import util.CommonsUtil
			import util.FilesUtil
		
			% If no path is informed, display a popup for the user to
			% select the path to save the file
			if nargin < 2
				if this.DEV
					CommonsUtil.log('Waiting for user input... ');
				end
				
				filePath = FilesUtil.uiPutFile('microgrid.gms');
				
				if isempty(filePath)
					if this.DEV
						CommonsUtil.log('Canceled\n');
					end
					return;
				end
			else
				% makes sure the path is absolute
				filePath = FilesUtil.getFullPath(filePath, false);
			end
			
			% starts the clock
			elapsedTime = tic();
			
			% little logging...
			if this.DEV
				CommonsUtil.log('Exporting model file...\n');
			end
			
			try				
				% tries to open the informed file
				fid = fopen(filePath, 'w');
				if fid == -1
					error('Unable to create/overwrite file <%s>', filePath);
				end
				
				% retrieves the model file
				content = this.buildGamsCode();
				
				% writes to a file and closes it
				fprintf(fid, '%s', content);
				fclose(fid);
				
				% stops the clock and more logging...
				elapsedTime = toc(elapsedTime);
				if this.DEV
					CommonsUtil.log('Model file saved on disk! %5.0f ms', elapsedTime*1000);
					CommonsUtil.log(' <<a href="matlab:open(''%s'')">%s</a>>\n', filePath, filePath);
				end
			catch e % pretty standard error handling
				try
					fclose(fid);
				catch
				end
				
				elapsedTime = toc(elapsedTime);
				if this.DEV
					CommonsUtil.log('Fail. %5.0f ms\n', elapsedTime*1000);
				end
				
				rethrow(e);
			end
		end
		
		% VV HELPER METHODS
		function timeElapsed = removeTempFiles(this, deleteOutput)
		% Removes the temporary files used to communicate with GAMS.
		%
		% Examples:
		%
		% model.REMOVETEMPFILES() Removes the temporary files used to
		% communicate with GAMS. After this, is impossible to read any more variables.
		%
		% model.REMOVETEMPFILES(deleteTmpOutput) if deleteTmpOutput is set
		% to FALSE, removes all the temporary files EXCEPT the one used to
		% retrieve variables.
			import util.TypesUtil
			import util.FilesUtil
			import util.CommonsUtil
		
			timeElapsed = tic();
			
			if nargin < 2
				deleteOutput = true;
			else
				TypesUtil.mustBeLogical(deleteOutput);
			end
			
			if this.DEV
				CommonsUtil.log('Removing temporary files... ');
			end
			
			% Set a couple of warnings to temporarily issue errors (exceptions)
			s = warning('error', 'MATLAB:DELETE:Permission');
			warning('off', 'MATLAB:DELETE:FileNotFound');
			
			try
				if ~isempty(this.getGamsTmpFile)
					FilesUtil.forceDelete(this.getGamsTmpFile());
				end
				
				% deletes the cplex.opt file and ignores any errors that
				% might come from it
				try
					FilesUtil.forceDelete('cplex.opt');
				catch
				end
				
				clazz = ?gams.GAMSModel;
				clazz = clazz.Name;
				
				if TypesUtil.instanceof(this.getGamsObject(), clazz)
					this.getGamsObject().removeTempFiles(deleteOutput);
				end
			catch e
				if this.DEV
					CommonsUtil.log(' *error while deleting files: "%s"* \n', getReport(e, 'basic'));
				end
			end
			
			% Restore the warnings back to their previous state
			warning('on', 'MATLAB:DELETE:FileNotFound');
			warning(s);
			
			timeElapsed = toc(timeElapsed);
			if this.DEV
				CommonsUtil.log('Done! %5.0f ms\n', timeElapsed*1000);
			end
		end
		% ^^ HELPER METHODS
	end
	
	methods(Access = protected)
		function updateTimeInfo(this, ~)
		% API developers' use only
		%
		% Updates all the time-dependant variables, namely the tarrif period (off-peak/intermediate/peak).
		
			function map = processMap(map, i, periodMap, label, timeArray)
			% Local function so that we don't need to ctrl+c ctrl+v the
			% code for "peak" and "intermediate" tariff period mapping
			
				% calculates the current minute of the current day
				% for when the simulation spans across more than one day
				currentTime = timeArray(i);
				currentTime = currentTime - floor(currentTime/1440)*1440;
					
				[periodCount, ~] = size(periodMap);
				for j = 1:periodCount
					startTime = periodMap(j, 1);
					endTime   = periodMap(j, 2);
					
					if endTime <= startTime
						error('Period for label "%s" is invalid. startTime=%d; endTime=%d', label, startTime, endTime);
					end
					
					% Note about the less equal operator: usually the test would be "startTime <= timeArray(i) && timeArray(i) < endTime", BUT since every time index refers to what happened BEFORE it and AFTER the time index before, the comparisson operators change.
					if startTime < currentTime && currentTime <= endTime
						map{i, 1} = num2str(i);
						map{i, 2} = label;
					end
				end
			end
		
			timeArray = this.getTimeArray();
			
			% creates a clean periodMapping cell array
			this.periodMapping = cell(length(timeArray), 2);
			
			% at weekends
			if this.isWeekend && this.WEEKEND_IS_OFF_PEAK
				return;
			end
			
			% populates the mapping array
			for i = 1:length(timeArray)
				% default is off peak if nothing is found
				this.periodMapping{i, 1} = num2str(i);
				this.periodMapping{i, 2} = this.OFF_PEAK_LABEL;
				
				% looks into the intermediate period array
				this.periodMapping = processMap(this.periodMapping, i, this.periodIntermediate, this.INTERMEDIATE_LABEL, timeArray);
				
				% looks into the peak period array
				this.periodMapping = processMap(this.periodMapping, i, this.periodPeak, this.PEAK_LABEL, timeArray);
			end
			
% 			this.periodMapping
		end
		
		function flushVariables(this)
		% API developers' use only
		% See also: <a href="matlab:doc('microgrid_model.MGElement.flushVariables')">MGElement.flushVariables</a>.
			import util.CommonsUtil
			
			if this.DEV
				CommonsUtil.log('Flushing global variables...\n');
			end
		
			% --------- calculates everything we need
		
			% hired demands for each period [kW]
			hiredDemand = {this.PEAK_LABEL,         this.hiredDemandPeak;
						   this.INTERMEDIATE_LABEL, this.hiredDemandIntermediate;
						   this.OFF_PEAK_LABEL,     this.hiredDemandOffPeak};
			 
			% the day of week mapping
			if this.isWeekend
				dayLabel = this.WEEKEND_LABEL;
			else
				dayLabel = this.WEEKDAY_LABEL;
			end
			
			% mapping of prices
			weekD = this.WEEKDAY_LABEL;
			weekE = this.WEEKEND_LABEL;
			timeP = this.PEAK_LABEL;
			timeI = this.INTERMEDIATE_LABEL;
			timeO = this.OFF_PEAK_LABEL;
			pricesPurchase = {weekD, timeP, this.tariffPurcWdayPeak;
							  weekD, timeI, this.tariffPurcWdayIntermediate;
				              weekD, timeO, this.tariffPurcWdayOffPeak;
							  weekE, timeP, this.tariffPurcWendPeak;
							  weekE, timeI, this.tariffPurcWendIntermediate;
				              weekE, timeO, this.tariffPurcWendOffPeak;
							  };
						  
			pricesSelling = {weekD, timeP, this.tariffSellWdayPeak;
							 weekD, timeI, this.tariffSellWdayIntermediate;
				             weekD, timeO, this.tariffSellWdayOffPeak;
							 weekE, timeP, this.tariffSellWendPeak;
							 weekE, timeI, this.tariffSellWendIntermediate;
				             weekE, timeO, this.tariffSellWendOffPeak;
							 };
			
			fines =  {weekD, timeP, this.fineWdayPeak;
					  weekD, timeI, this.fineWdayIntermediate;
				      weekD, timeO, this.fineWdayOffPeak;
					  weekE, timeP, this.fineWendPeak;
					  weekE, timeI, this.fineWendIntermediate;
				      weekE, timeO, this.fineWendOffPeak;
					  };
				  
			% --------- flushes everything
			
			% first of all: the time array
			this.addGlobalSet('t', 1:length(this.dtArray));
			
			% week days mapping
			this.addGlobalSet('tdia', this.WEEK_LABELS);
			this.addGlobalSet('tp_dia', dayLabel, 'tdia');
			
			% hour of the day mapping
			this.addGlobalSet('thora', this.PERIOD_LABELS);
			this.addGlobalSet('map_th', this.periodMapping, this.TIME_VARIABLE, 'thora');
			
			% hired demands mapping
			this.addGlobalParameter('demandas_contratadas', hiredDemand, 'thora');
			this.timeAddGlobalParameter('dt', this.dtArray/60); % dt is actually in hours on GAMS
			
			% mapping of prices
			this.addGlobalParameter('precos_cr_venda', pricesSelling, 'tdia', 'thora');
			this.addGlobalParameter('precos_cr_compra', pricesPurchase, 'tdia', 'thora');
			this.addGlobalParameter('exceededDemandPenalty', fines, 'tdia', 'thora');
			
			if this.DEV
				CommonsUtil.log('Global variables flushed.\n');
			end
		end
		
		function checkIsReadyForExecution(this)
		% Checks if all depencies are ready for execution, throws error if not.
			import util.CommonsUtil
			import util.StringsUtil
			
			if this.DEV
				CommonsUtil.log('Checking if CentralController is ready for execution... \n');
			end

			if this.WARNINGS && round(abs(rem(this.t0, 1440))) ~= this.t0
				warning('Variable "t0" sanitized from %0.4g to %0.4g', this.t0, round(abs(rem(this.t0, 1440))));
			end
			this.t0 = round(abs(rem(this.t0, 1440)));
			
			timeArray = this.getTimeArray();
			if timeArray(end) < this.MINIMAL_HORIZON
				error('Simulation time must be at least %d minutes long', this.MINIMAL_HORIZON);
			end
			
			if this.DEV
				CommonsUtil.log('Checking if GAMS interface is ready for execution... ');
			end
			if ~this.getGamsObject().getIsReadyForExecution()
				error('GAMS interface is not ready for execution.');
			end
			if this.DEV
				CommonsUtil.log('Ok!\n');
			end
			
			% retrieves an list with all the MGElements + the Microgrid
			% object
			mgElements = [{this.getMicrogrid()}; this.getMicrogrid().getMGElements(true)];
			
			% iterates over the list checking if everyone is fine, throws
			% error if any isn't
			for i = 1:length(mgElements)
				mgElement = mgElements{i};
				id = mgElement.getId();
				clazz = mgElement.getClassName();
				
				if this.DEV
					CommonsUtil.log('Checking if MGElement #%d (%s) is ready for execution... ', id, clazz);
				end
				
				mgElement.checkIsReadyForExecution();
				
				if ~isequal(this.getTimeArray(), mgElement.getTimeArray())
					error('MGElement time array is different from %s''s time array.', this.getClassName());
				end
				
				if this.DEV
					CommonsUtil.log('Ok!\n');
				end
			end
			
			% if no errors were thrown until here, everything should be
			% fine
			if this.DEV
				CommonsUtil.log('CentralController is ready for execution!\n');
			end
		end
		
		function modelStr = getEquationsModel(this)
		% API developers' use only
		% Builds the equations file from the template informed by
		% CentralController.EQUATIONS_FILE and replaces all the global
		% parameters defined (right now, only the relative error tolerance)
			modelStr = this.getEquationsModel@microgrid_model.MGElement();
			
			modelStr = strrep(modelStr, this.RELATIVE_ERROR_PLACEHOLDER, num2str(this.relativeErrorTolerance, 10));
		end
	end
	
	methods(Access = private)
		% VV GETTERS AND SETTERS
		function setMicrogrid(this, microgrid)
		% Sets the Microgrid reference
		%
		% See also: Microgrid
			microgrid.setCentralController(this);
			this.microgrid = microgrid;
		end
		
		function setHasBeenRun(this, hasBeenRun)
		% Sets whether or not this model has been run and is ready to export data
			this.hasBeenRun = hasBeenRun;
		end
		% ^^ GETTERS AND SETTERS
		
		function synchronizeHorizons(this)
		% Synchronizes the time arrays of everyone.
		%
		% Currently, only loads are time-dependant, but any MGElement that
		% initializes its timeArray has the hability to be part of the sync
		% process. The synchronization logic is the following:
		% - If the CentralController horizon is set to zero, the global
		%   horizon will be the longest one across all the MGElements.
		% - If the CentralController horizon is different than zero,
		%   nothing's changed here, but every MGElement (including the
		%   Microgrid object itself) will receive a call to updateTimeInfo(t)
		%   with the argument t the CentralController's time array.
			import util.TypesUtil
			
			% if the horizon here is not zero, that means the caller
			% changed that manually, so we do nothing.
			if this.intendedHorizon > 0
				return
			end
			
			% if this.intendedHorizon is zero, than the MGElement with the
			% longest horizon is used
			
			mgElements = this.getMicrogrid().getMGElements(true);

			% get biggest horizon (remember that this.intendedHorizon
			% starts with zero)
			for i = 1:length(mgElements)
				this.intendedHorizon = max(this.intendedHorizon, mgElements{i}.getHorizon());
			end
		end
		
		function updateTimeArrays(this)
		% Updates the dtArray and the time indices array.
		
			% input validation
			if this.step1stHalfHour > 30
				if this.WARNINGS
					warning('1st half hour step exceeds maximum step size truncating to 30 minutes');
				end
				this.step1stHalfHour = 30;
			elseif this.step1stHalfHour < this.MINIMAL_TIME_STEP
				if this.WARNINGS
					warning('1st half hour step exceeds minimum step size truncating to %d minutes', this.MINIMAL_TIME_STEP);
				end
				this.step1stHalfHour = this.MINIMAL_TIME_STEP;
			end
			if this.step2ndHalfHour > 30
				if this.WARNINGS
					warning('2nd half hour step exceeds maximum step size truncating to 30 minutes');
				end
				this.step2ndHalfHour = 30;
			elseif this.step2ndHalfHour < this.MINIMAL_TIME_STEP
				if this.WARNINGS
					warning('2nd half hour step exceeds minimum step size truncating to %d minutes', this.MINIMAL_TIME_STEP);
				end
				this.step2ndHalfHour = this.MINIMAL_TIME_STEP;
			end
			if this.stepDefault <= this.MINIMAL_TIME_STEP
				if this.WARNINGS
					warning('default step exceeds minimum step size truncating to %d minutes', this.MINIMAL_TIME_STEP);
				end
				this.stepDefault = this.MINIMAL_TIME_STEP;
			end
			if this.intendedHorizon < this.MINIMAL_HORIZON
				error('Simulation time (%d min) under minimum limit (%d min). Wild shot: you forgot to load the demand curves.', this.intendedHorizon, this.MINIMAL_HORIZON);
			end
			
			% remaining time, aside from the first hour that is fixed.
			remainingTime = max(0, this.intendedHorizon - 60);
			countRest     = ceil(remainingTime/this.stepDefault);
			
			% number of points for the first half hour
			count1stHH = round(30/this.step1stHalfHour);
			
			% number of points for the second half hour
			count2ndHH = round(30/this.step2ndHalfHour);
		
			% rounding error alarms
			if ((30/count1stHH) ~= this.step1stHalfHour) && this.WARNINGS
				warning('Rounding the first half hour step from %d min to %d min', this.step1stHalfHour, 30/count1stHH);
			end
			if ((30/count2ndHH) ~= this.step2ndHalfHour) && this.WARNINGS
				warning('Rounding the second half hour step from %d min  to %d min', this.step2ndHalfHour, 30/count2ndHH);
			end
			if countRest*this.stepDefault ~= remainingTime && this.WARNINGS
				warning('Rounding simulation horizon from %d min to %d min', remainingTime+60, this.stepDefault*countRest+60);
			end
			
			% this rounds the steps to valid values.
			this.step1stHalfHour = 30/count1stHH;
			this.step2ndHalfHour = 30/count2ndHH;
			
			% saves the result
			this.dtArray = [(this.step1stHalfHour)*ones(count1stHH, 1);
							(this.step2ndHalfHour)*ones(count2ndHH, 1);
							(this.stepDefault)    *ones(countRest, 1)];
			
			this.setTimeArray(this.t0 + cumsum(this.dtArray)); % notice the t0 element
		end
		
		function setVarLoaderFile(this, varLoaderFile)
		% Sets the name of the loader.gms file
			this.varLoaderFile = varLoaderFile;
		end
		
		function setGamsTmpFile(this, gamsTmpFile)
		% Sets the value of the main.gms file
			this.gamsTmpFile = gamsTmpFile;
		end
		
		function gamsTmpFile = getGamsTmpFile(this)
		% Returns the name of the loader.gms file
			gamsTmpFile = this.gamsTmpFile;
		end
		
		function loadStatement = buildLoadStatement(this)
		% Builds the load.gms statement
			loadStatement = sprintf('$include "%s"', util.FilesUtil.getFullPath(this.getVarLoaderFile(), false));
		end
		
		function initializeGamsObject(this)
		% Everything needed to initialize the GAMS-MATLAB interface.
			import gams.*
			this.setGamsObject(GAMSModel(this.getGamsTmpFile(), this.DEV, this.getVarLoaderFile()));
			this.getGamsObject().KEEP_FILES = this.KEEP_FILES;
			this.getGamsObject().WARNINGS = this.WARNINGS;
		end
		
		function gamsCode = buildGamsCode(this)
		% Builds a string of the MGCC's GAMS model that this class represents. 
			import util.FilesUtil
			
			mgElements =  this.getMicrogrid().getMGElements(true);
			
			% preamble: MGCC's ans Microgrid's
			gamsCode = this.getParametersModel();
			gamsCode = sprintf('%s\n\n%s', gamsCode, this.getMicrogrid().getParametersModel());
			
			% variable declaration of each MGElement
			for i = 1:length(mgElements)
				mgElement = mgElements{i};
				
				gamsCode = sprintf('%s\n\n%s', gamsCode, mgElement.getParametersModel());
			end
			
			% statement that will load dynamic data
			loadSeparatorTop = '*----------------------------VV LOAD VARIABLES VV-------------------------------';
			loadSeparatorBot = '*----------------------------^^ LOAD VARIABLES ^^-------------------------------';
			gamsCode = sprintf('%s\n\n%s\n\n%s\n\n%s', gamsCode, loadSeparatorTop, this.buildLoadStatement(), loadSeparatorBot);
			
			% equations of each MGElement
			for i = 1:length(mgElements)
				mgElement = mgElements{i};
				
				gamsCode = sprintf('%s\n\n%s', gamsCode, mgElement.getEquationsModel());
			end
			
			% final part: microgrid and MGCC
			gamsCode = sprintf('%s\n\n%s', gamsCode, this.getMicrogrid().getEquationsModel());
			gamsCode = sprintf('%s\n\n%s', gamsCode, this.getEquationsModel());
		end
		
	end
	
	methods(Static)
		function mustBeCentralController(object)
		% Checks if a variable is instance of CentralController (allows null). Throws error if not.
			import util.TypesUtil
			
			% this makes sure that an error is thrown if CentralController is
			% renamed
			clazz = ?microgrid_model.CentralController;
			clazz = clazz.Name;
			if ~TypesUtil.instanceof(object, clazz) && ~isempty(object)
				error('Variable "%s" must be %s instance.', inputname(1), clazz);
			end
		end
		
		function [mgcc, elapsedTime] = load(fileName, path)
		% Reads a MAT file and
			elapsedTime = tic();
			
			% some logging
			if microgrid_model.MGElement.developmentMode()
				util.CommonsUtil.log('Loading new case...\n');
			end
			
			% variable sanitizing
			if nargin < 3
				path = '';
			end
			if ~util.StringsUtil.endsWith(fileName, '.mat')
				fileName = [fileName, '.mat'];
			end
			filePath = fullfile(path, fileName);
			
			% retrieves the mgcc variable and checks it
			loadedVariables = load(filePath);
			mgcc = loadedVariables.('mgcc');
			microgrid_model.CentralController.mustBeCentralController(mgcc);

			% if the model has data in it, loads it as well
			if isfield(loadedVariables, 'gdxFile')
				if  ~mgcc.getHasBeenRun() && microgrid_model.MGElement.warningsOn()
					warning('Result file found but CentralController says it hasn''t been run. Overriding and loading the result set anyway.')
				end
				
				% little logging
				if microgrid_model.MGElement.developmentMode()
					util.CommonsUtil.log('Result set "%s" found, loading it as well\n', mgcc.getTmpOutputPath());
				end
				
				
				gdxFile = loadedVariables.('gdxFile');
				mgcc.setTmpOutputBinary(gdxFile);
			else
				if microgrid_model.MGElement.developmentMode()
					util.CommonsUtil.log(' *model with no result set* ');
				end
				mgcc.setHasBeenRun(false);
			end
			
			elapsedTime = toc(elapsedTime);
			
			% some more logging
			if microgrid_model.MGElement.developmentMode()
				util.CommonsUtil.log('Done! %0.0f ms\n', elapsedTime*1000);
			end
		end
	end
	
end

