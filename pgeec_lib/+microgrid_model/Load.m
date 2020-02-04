classdef (Abstract) Load < microgrid_model.MGElement
	% Generic load model. Different models of loads should extend this class.
	% It has methods for handling the import and resizing of demand curves
	% (predicted hourly demand) to fit the <a href="matlab:doc('microgrid_model.CentralController')">CentralController</a> horizon.
	% If you try to run the simulation with no demand profile loaded
	% (<a href="matlab:doc('microgrid_model.LoadConstant/importDemandProfile')">LoadConstant.importDemandProfile()</a>) an error will be thrown
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
		% API developers' use only.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.SUPER_PARAMETERS_FILE')">MGElement.SUPER_PARAMETERS_FILE</a>
		SUPER_PARAMETERS_FILE = '#TEMPLATEload_generic-template_parameters.gms';
		
		% API developers' use only
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement.SUPER_EQUATIONS_FILE')">MGElement.SUPER_EQUATIONS_FILE</a>
		SUPER_EQUATIONS_FILE  = [];
	end
	
	% simulation properties
	properties(Access = private)
		% Minute of the day that a demand value is predicted to happen [minute of day]
		originalTimeArray {validateattributes(originalTimeArray, {'numeric'}, {'nonnegative', 'increasing'})};
		
		% Base demand profile as originally read [kWh]
		originalProfile {validateattributes(originalProfile, {'numeric'}, {'finite'})};
		
		% Transient base demand, where resizing actions are stored.
		% 
		% After the resizing/resampling actions transform the demand
		% profile curve, the result is save here.
		%
		% The public method getDemandProfile actually returns this value. [kWh]
		processedProfile {validateattributes(processedProfile, {'numeric'}, {'finite'})};
	end
	
	methods(Access = public)
		% VV GETTERS AND SETTERS
		function demandProfile = getOriginalProfile(this)
		% Returns the originally loaded demand profile
		%
		% Before executing the optimization model, all the time series of
		% the simulation need to be transformed in order to be in sync with
		% the rest of the simulation. This method returns the original
		% demand time series, before any transformation was applied.
		%
		% See also: getDemandProfile, setOriginalProfile, getProcessedProfile, setProcessedProfile, getOriginalTimeArray, setOriginalTimeArray, getTimeArray, setTimeArray, updateTimeInfo
			demandProfile = this.originalProfile;
		end
		
		function originalTimeArray = getOriginalTimeArrayHour(this)
		% Returns the originally loaded time stamps in hours from midnight
		%
		% See also: getDemandProfile, getOriginalProfile, setOriginalProfile, getProcessedProfile, setProcessedProfile, setOriginalTimeArray, getTimeArray, setTimeArray, updateTimeInfo
			originalTimeArray = this.originalTimeArray/60;
		end
		
		function originalTimeArray = getOriginalTimeArray(this)
		% Returns the originally loaded time stamps
		%
		% Before executing the optimization model, all the time series of
		% the simulation need to be transformed in order to be in sync with
		% the rest of the simulation. This method returns the original
		% time stamp series, before any transformation was applied.
		%
		% See also: getDemandProfile, getOriginalProfile, setOriginalProfile, getProcessedProfile, setProcessedProfile, setOriginalTimeArray, getTimeArray, setTimeArray, updateTimeInfo
			originalTimeArray = this.originalTimeArray;
		end
		
		function demandProfile = getDemandProfile(this)
		% Returns the current base demand array
			demandProfile = this.processedProfile;
		end
		% ^^ GETTERS AND SETTERS
		
		% VV FUNCTIONALITY
		function status = importDemandProfile(this, filePath)
		% Reads an Excel or .csv file containing a time series of demand values
		%
		% The file should consist of two columns - a time column and a
		% power output column. There's no limit for row count.
		%
		% If the first row is textual, it will be considered to be a header
		% and will be ignored.
		%
		% Time column [minutes]: the first column of the file, positive
		% values and strictly increasing. The initial time is considered to
		% be midnight, meaning that a value of 65 is interpreted as the
		% demand at 01:05am. Also, since this is considered to be an
		% aggregate, you can't start the time column at zero minutes.
		%
		% Power column [kW]: second column of the file, should contain the
		% average power computed at the end of the respective interval.
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
		% import microgrid.LoadConstant % LoadConstant is a child of the Load class
		% pv = LoadConstant();
		%
		% status = pv.importDemandProfile(); % shows a dialog for the user to choose the file to be loaded
		% status = pv.importDemandProfile('C:/data/demandData.xlsx'); % read the demandData.xlsx file silently (no dialog)
		%
		% the output variable status will be true if and only if the import
		% worked correctly.
			import util.FilesUtil
			import util.CommonsUtil
			
			% initializes output variable
			status = false;
			
			% allowed file extensions
			fileExtensions = {'*.xls*'; '*.csv'};
			title = 'Select a file containing the power time-series';
		
			% If no path is informed, display a popup for the user to
			% select the path to save the file
			if nargin < 2
				filePath = FilesUtil.uiGetFile(fileExtensions, title);
				if isempty(filePath); return; end
				
				if this.DEV
					CommonsUtil.log('Done.\n');
				end
			else
				filePath = FilesUtil.getFullPath(filePath);
			end
			
			if this.DEV
				CommonsUtil.log('Loading time series file... ');
			end
			
			% tries to read as .xls* file first,  if it fails, tries as
			% .csv. If it fails again, the error of the second try is thrown
			try
				num = FilesUtil.readExcel(filePath);
			catch
				num = FilesUtil.readCsv(filePath);
			end
			
			if this.DEV
				CommonsUtil.log('Loaded.\n');
				CommonsUtil.log('Validating input... ');
			end
			
			% separates the matrix in two arrays
			timeArray   = num(:, 1);
			demandArray = num(:, 2);
			
			% allows headers
			if ~isempty(timeArray) && isnan(timeArray(1))
				timeArray(1) = [];
			end
			if ~isempty(demandArray) && isnan(demandArray(1))
				demandArray(1) = [];
			end
			
			% verifies if time array is numeric and increasing
			try
				validateattributes(timeArray, {'numeric'}, {'positive', 'increasing', 'nonempty'});
			catch
				error('Time column expected to be positive (do not start on 0) and increasing.');
			end
			
			% verifies if demand array is numeric
			try
				validateattributes(demandArray, {'numeric'}, {'finite', 'nonempty'});
			catch
				error('Demand column expected to be numeric.');
			end
			
			% store everything base demand
			this.setOriginalProfile(demandArray);
			this.setProcessedProfile(demandArray);
			
			% store time array
			this.setTimeArray(timeArray); % MGElement's definition
			this.setOriginalTimeArray(timeArray); % private definition
			
			if this.DEV
				CommonsUtil.log('Ok!\n');
			end
			
			status = true;
		end
		% ^^ FUNCTIONALITY
	end
	
	methods(Access = protected)
		
		% VV IMPLEMENTATION OF SUPER CLASS' ABSTRACT METHODS
		function flushVariables(this)
		% API developers' use only
		% 
		% See also: <a href="matlab:doc('microgrid_model.MGElement/flushVariables')">MGElement.flushVariables()</a>
			this.timeAddParameter('baseDemand', this.getDemandProfile());
		end
		% ^^ IMPLEMENTATION OF SUPER CLASS' ABSTRACT METHODS
		
		% VV PROTECTED GETTERS AND SETTERS
		function setOriginalTimeArray(this, timeArray)
		% Saves the originally loaded time stamps
		%
		% Before executing the optimization model, all the time series of
		% the simulation need to be transformed in order to be in sync with
		% the rest of the simulation. This method saves the original
		% time stamp series, before any transformation was applied.
		%
		% See also: getDemandProfile, getOriginalProfile, setOriginalProfile, getProcessedProfile, setProcessedProfile, getOriginalTimeArray, getTimeArray, setTimeArray, updateTimeInfo
			this.originalTimeArray = timeArray;
		end
		
		function setOriginalProfile(this, originalProfile)
		% Saves the originally loaded demand profile
		%
		% Before executing the optimization model, all the time series of
		% the simulation need to be transformed in order to be in sync with
		% the rest of the simulation. This method saves the original
		% demand time series, before any transformation was applied.
		%
		% See also: getDemandProfile, getOriginalProfile, getProcessedProfile, setProcessedProfile, getOriginalTimeArray, setOriginalTimeArray, getTimeArray, setTimeArray, updateTimeInfo
			this.originalProfile = originalProfile;
		end
		
		function demandProfile = getProcessedProfile(this)
		% Returns the transformed loaded demand profile
		%
		% Before executing the optimization model, all the time series of
		% the simulation need to be transformed in order to be in sync with
		% the rest of the simulation. This method returns the transformed
		% demand time series, after all transformations were applied.
		%
		% See also: getDemandProfile, getOriginalProfile, setOriginalProfile, getProcessedProfile, setProcessedProfile, getOriginalTimeArray, setOriginalTimeArray, getTimeArray, setTimeArray, updateTimeInfo
			demandProfile = this.processedProfile;
		end
		function setProcessedProfile(this, processedProfile)
		% Saves the transformed demand profile
		%
		% Before executing the optimization model, all the time series of
		% the simulation need to be transformed in order to be in sync with
		% the rest of the simulation. This method saves the transformed
		% demand time series, after all transformations were applied.
		%
		% See also: getDemandProfile, getOriginalProfile, getProcessedProfile, setProcessedProfile, getOriginalTimeArray, setOriginalTimeArray, getTimeArray, setTimeArray, updateTimeInfo
			this.processedProfile = processedProfile;
		end
		% ^^ PROTECTED GETTERS AND SETTERS
		
		function updateTimeInfo(this, newTimeArray)
		% API developers' use only
		%
		% Synchronizes the demand curve with <a href="matlab:doc('microgrid_model.CentralController')">CentralController's</a> clock
		%
		% See also: <a href="matlab:doc('microgrid_model.CentralController/run')">CentralController.run()</a>
			import util.TimeSeriesUtil
			import util.CommonsUtil
			
			if this.DEV
				CommonsUtil.log('Updating time info...\n');
			end
			
			% buffers original data
			oldTime    = this.getOriginalTimeArray();
			oldSamples = this.getOriginalProfile();
			
			if isempty(oldTime) || isempty(oldSamples)
				error('No power curve for %s (#%d).', this.getClassName(), this.getId());
			end
			
			if this.DEV
				CommonsUtil.log('Transposing original demand... Original: %d samples, %0.4g minutes\n', length(oldTime), oldTime(end));
			end
			
			% makes sure both demand curves start and end at the same time (repeats the load profile pattern multiple times if necessary)
			gap = newTimeArray(1) + mod(1440-rem(oldTime(end), 1440), 1440);
			options = {
				'start-time', newTimeArray(1);
				'end-time', newTimeArray(end);
				'gap', gap;
				'left-border', 'enlarge';
				'right-border', 'enlarge';
			};
			[baseTime, spannedProfile] = TimeSeriesUtil.respan(oldTime, oldSamples, options);
			
			if this.DEV
				CommonsUtil.log('Demand transposed. Original: %d samples. New: %d samples\n', length(oldSamples), length(spannedProfile));
				CommonsUtil.log('Resampling demand profile...\n');
			end
			
% 			figure(1)
% 			hold on;
% 			stairs(baseTime, spannedProfile, '.-');
% 			hold off
			
			% this will resample the demand to meet the global timeArray
			[newBaseDemand, newTimeArray] = TimeSeriesUtil.resample(baseTime, spannedProfile, newTimeArray, 'forward1', 'repeat-border');
			
			if this.DEV
				CommonsUtil.log('Demand resampled. Original: %d samples. New: %d samples\n', length(spannedProfile), length(newBaseDemand));
			end

% 			hold on
% 			stairs(newTimeArray, newBaseDemand);
% 			hold off;
			
			% saves the result
			this.setProcessedProfile(newBaseDemand);
			this.setTimeArray(newTimeArray);
			
			if this.DEV
				CommonsUtil.log('Time info updated. New sample count: %d, new duration: %0.4g minutes.\n', length(newTimeArray), newTimeArray(end));
			end
		end
		
		function checkIsReadyForExecution(this)
		% API developers' use only.
		%
		% See also: <a href="matlab:doc('microgrid_model.MGElement/checkIsReadyForExecution')">MGElement.checkIsReadyForExecution()</a>
			if isempty(this.getOriginalProfile()) || isempty(this.getProcessedProfile())
				error('Demand curve empty.');
			elseif isempty(this.getOriginalTimeArray) || isempty(this.getTimeArray())
				error('Time array empty.');
			end
		end
		
		
	end
end

