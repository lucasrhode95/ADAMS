classdef TimeSeriesUtil
	% Collection of commonly needed methods for handling time series
	%
	% Notice: due to platform limitations, this class have a maximum time
	% precision of 1e-12 time units. If you need more precision than this,
	% you should use submultiples of second (e.g. nano and picoseconds).
	
	methods(Access = public, Static)
		function [newTime, newSamples] = respan(oldTime, oldSamples, options)
		% Replicates a waveform beyond its original duration
		%
		% TODO: insert documentation here
			import util.TypesUtil
			import util.TimeSeriesUtil
			
			if nargin >= 3
				% processes user input
				[options, oldTime, oldSamples] ...
					= TimeSeriesUtil.respanOptions(oldTime, oldSamples, options);
			else
				% use default options
				[options, oldTime, oldSamples] ...
					= TimeSeriesUtil.respanOptions(oldTime, oldSamples);
			end
			% sample count
			sampleCount = length(oldTime);
			% timestep for each sample (last one is adjustable)
			dt = [diff(oldTime); options('gap')];
			% original duration
			T = oldTime(end)+options('gap') - oldTime(1);
			
			% hard-to-understand calculations that were hidden
			[i0, t0] = TimeSeriesUtil.getStartingPoint(oldTime(1), T, dt, options);
			
			% changes order of the array elements
			newSamples = TimeSeriesUtil.swap(oldSamples, i0);
			dt         = TimeSeriesUtil.swap(dt, i0);
			
			% integer time-replication
			N       = fix(round((options('end-time')-t0+options('gap'))/T, 12));
			newTime = t0+cumsum([0;...
				TimeSeriesUtil.resizeArray(dt, max(0, sampleCount*N-1))]);
			
			% fractional time-replication
			if length(newTime)>1
				dt = TimeSeriesUtil.swap(dt, length(dt));
			end
			remainder = options('end-time')-newTime(end);
			i1        = find(cumsum(dt) >= remainder, 1)*(remainder>0); % if the remainder is 0, i1 should be 0 as well
			newTime   = [newTime; newTime(end)+cumsum(dt(1:i1))];
			
			% samples replication
			newSamples = TimeSeriesUtil.resizeArray(newSamples, length(newTime));
			
			% post-processing
			if options('use-row')
				% make sure the output is in the same format as the input
				newTime = newTime';
				newSamples = newSamples';
			end
			
			% cut borders
			[newTime, newSamples] = TimeSeriesUtil.truncateBorders(newTime, newSamples, options);
		end
		
		function array = swap(array, i)
		% Swaps the last half with the first half of an array.
			array = [array(i:end); array(1:i-1)];
		end
		
		function newArray = resizeArray(oldArray, newLength)
		% Resizes an array to any desired size, similar to MATLAB's repmat but allows non-integer repeating and also trimming.
		% 
		% Syntax
		% newArray = TIMESERIESUTIL.RESIZEARRAY(oldArray, newSize) if newSize
		% is longer than the original's, it appends copies of the array.
		%
		% If newSize is shorter than the oldArray size, RESIZEARRAY will
		% trim it to the newLength
		%
		% Parameters:
		% oldArray: row or column vector
		% newLength: nonnegative, integer
			import util.TypesUtil
		
			TypesUtil.mustBeNotEmpty(oldArray);
			validateattributes(newLength, {'numeric'}, {'integer', 'nonnegative'});
		
			oldLength = length(oldArray);
		
			% finds out how many times the entire array will be repeated
			repeatCount = floor(newLength/oldLength);
			
			% finds out how much needs to be filled to achieve the desired
			% remaining length
			remainingElements = newLength - oldLength*repeatCount;
			
			% concatenates everything
			if iscolumn(oldArray)
				newArray = [repmat(oldArray, repeatCount, 1); oldArray(1:remainingElements)];
			elseif isrow(oldArray)
				newArray = [repmat(oldArray, 1,repeatCount), oldArray(1:remainingElements)];
			else
				error('Only 1D arrays supported.');
			end
		end
		
		function [newSamples, newTime] = resample(oldTime, oldSamples, newTime, processingMode, outsideRangeHandling)
		% Resamples a sample array to fit in a new time array in a less fancy but more deterministic way than interpolation.
		% Method:
		% -if we're oversampled: average the values
		% -if we're undersampled: repeat the values
		%
		% TODO: write documentation for this method
			import util.TimeSeriesUtil
			import util.TypesUtil
			
			% validates arguments
			validateattributes(oldSamples, {'numeric'}, {'vector'});
			validateattributes(oldTime, {'numeric'}, {'vector', 'increasing'});
			validateattributes(newTime, {'numeric'}, {'vector', 'increasing'});
			if length(oldTime) ~= length(oldSamples)
				error('oldSamples and oldTimeArray must have the same length');
			end
			
			% if input is empty, output is empty as well
			if isempty(newTime)
				newSamples = newTime; % the same empty type as the input, to be concise with the user entry.
				return
			elseif length(newTime) == 1
				newSamples = mean(oldSamples); % simply takes the mean of everything and calls it a day
				return;
			end
			
			% makes sure everything is either row or column vector
			if isrow(oldTime)
				useRow = true;
				if iscolumn(oldSamples)
					oldSamples = oldSamples';
				end
				if iscolumn(newTime)
					newTime = newTime';
				end
			else
				useRow = false;
				if isrow(oldSamples)
					oldSamples = oldSamples';
				end
				if isrow(newTime)
					newTime = newTime';
				end
			end
			
			if nargin >= 4
				TypesUtil.mustBeTxt(processingMode);
			else
				processingMode = 'forward1';
			end
			
			if nargin >= 5
				TypesUtil.mustBeTxt(outsideRangeHandling);
			else
				outsideRangeHandling = 'zeros';
% 				outsideRangeHandling = 'nan';
% 				outsideRangeHandling = 'repeat-border';
			end
			
			% initializes the new sample array with one sample value for each desired time instant
			%
			% necessary to implicitly handle values outside of the original
			% samples range
			if strcmp(outsideRangeHandling, 'zeros') || strcmp(outsideRangeHandling, 'repeat-border')
				newSamples = zeros(size(newTime));
			elseif strcmp(outsideRangeHandling, 'nan')
				newSamples = nan(size(newTime));
			else
				error('outside range handling option "%s" not recognized. Values allowed: zeros|repeat-border|nan', outsideRangeHandling);
			end
			
			% redirects to the correct function
			switch processingMode
				case {'forward', 'forward1'}
					newSamples = TimeSeriesUtil.resampleForward1(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling);
				case 'forward2'
					newSamples = TimeSeriesUtil.resampleForward2(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling);
				case 'backward'
					newSamples = TimeSeriesUtil.resampleBackward1(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling);
				otherwise
					error('Input "%s" not recognized. Valid arguments are %s', processingMode, 'forward|forward1|forward2|backward');
			end
			
% 			old technique for error highlighting
% 			for i = 1:length(newSamples)
% 				if isnan(newSamples(i))
% 					newSamples(i) = 1000;
% 				end
% 			end
		end
	end
	
	methods(Static, Access = private)
		function [i0, t0] = getStartingPoint(oldT0, T, dt, options)
		% Positions the starting point to an actual valid point
		% Since we need the sample count to be integer, not all
		% starting/ending points are viable.
		%
		% Also, since we support non-uniform sampling, things can get a
		% little complicated
			import util.TimeSeriesUtil
			
			% distance between starting points.
			% e>0: new start time is LEFT of the original start time
			% e<0: new start time is RIGHT of the original start time
			e = oldT0 - options('start-time');
			
			% how many periods fit in it
			n = round(e/T, 12);
			% how many integer durations fit in it
			N = fix(n);
			
			% nothing to do.
			if e==0  || n==N
				i0=1;
				t0=options('start-time');
				return;
			end
			
			% displaces the time array in time
			tTemp = [0; cumsum(dt)] + oldT0 - N*T;
			
			% correction needed for when new start time is LEFT of the original start time
			if e > 0; tTemp = tTemp - T; end
			
			% what is index immediately BEFORE options('start-time')?
			i0 = find(tTemp > options('start-time'), 1) - 1;
			t0 = tTemp(i0);
		end
		
		function [options, oldTime, oldSamples] = respanOptions(oldTime, oldSamples, input)
		% Processes the varargin options of the respan method
			import util.TypesUtil
			
			% this will be used to make sure the output is in the same
			% format as the input (although the user can override this
			% behavior)
			useRow = isrow(oldTime);
			
			% converts everything to column-vectors
			oldTime = oldTime(:);
			oldSamples = oldSamples(:);
			
			% checks size
			if length(oldTime) ~= length(oldSamples)
				error('time and samples must have the same number of elements.');
			end
			
			% other tests
			validateattributes(oldTime, {'numeric'}, {'finite', 'increasing'});
			validateattributes(oldSamples, {'numeric'}, {'finite'});
			
			% default options
			options = {
				'start-time', oldTime(1); % new signal will be synthesized from here
				'end-time', oldTime(end); % new signal will synthesized until here
				'gap', oldTime(end) - oldTime(end-1); % the duration of last sample
				'use-row', useRow; % format of the output
				'left-border', 'enlarge'; % enlarge|reduce|truncate
				'right-border', 'enlarge'; % enlarge|reduce|truncate
			};
			% we use options as a key-value mapping
			options = containers.Map(options(:, 1), options(:, 2));
			
			% if no manual input is informed, no further processing is
			% needed and the method will use the default options
			% please note that the default settings are not checked, so
			% make sure they are correct
			if nargin < 3; return; end
			
			for i = 1:size(input, 1)
				% input general checking
				key = lower(input{i, 1});
				value = input{i, 2};
				
				% key checking
				if ~isKey(options, key); error('%s is not a valid argument.', key); end
				
				% value checking
				value = lower(value);
				switch key
					case {'start-time', 'end-time'}
						TypesUtil.mustBeScalar(value);
					case 'gap'
						mustBePositive(value);
					case 'use-row'
						TypesUtil.mustBeLogical(value);
					case {'left-border', 'right-border'}
						mustBeMember(value, {'enlarge', 'reduce', 'fixed'});
					otherwise
						error('TimeSeriesUtil:implementationError', '%s argument not implemented.', key);
				end
				
				% storing
				options(key) = value;
			end
			
			% final checking
			validateattributes(options('start-time'), {'numeric'}, {'finite'});
			validateattributes(options('end-time'), {'numeric'}, {'finite', '>', options('start-time')});
		end
		
		function [newTime, newSamples] = truncateBorders(newTime, newSamples, options)
		% Handles the truncation of the left and right borders.
			switch options('left-border')
				case 'enlarge'
					% 'enlarge' is naturally done in the previous steps
				case 'reduce'
					if newTime(1) < options('start-time')
						newTime(1) = [];
						newSamples(1) = [];
					end
				case 'fixed'
					if newTime(1) < options('start-time')
						newTime(1) = options('start-time');
					end
			end
			switch options('right-border')
				case 'enlarge'
					% 'enlarge' is naturally done in the previous steps
				case 'reduce'
					if newTime(end) > options('end-time')
						newTime(end) = [];
						newSamples(end) = [];
					end
				case 'fixed'
					if newTime(end) > options('end-time')
						newTime(end) = options('end-time');
					end
			end
		end
		
		function newSamples = resampleForward1(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling)
			
			% uses the second last interval as the last look-ahead period
			Tf = 2*newTime(end) - newTime(end-1);
			
			% this will make the last sample of the new array be equal to
			% the last sample of the old array
			if useRow
				newTime = [newTime, Tf];
			else
				newTime = [newTime; Tf];
			end
			
			% used to go back in time and fill empty values
			lookBackFill = [];
			
			for i = 1:length(newTime)-1
				% timespan of the current iteration
				intervalStart = newTime(i);
				intervalEnd = newTime(i+1);
				
				if intervalStart >= 1340
					%
				end
				
				% if it's past the end of the original signal, ends the
				% processing or keeps repeating the last sample, depeding
				% on the handler selected
				if oldTime(end) < intervalStart && (strcmp(outsideRangeHandling, 'zeros') || strcmp(outsideRangeHandling, 'nan'))
					break;
				elseif oldTime(end) < intervalStart && strcmp(outsideRangeHandling, 'repeat-border')
					newSamples(i) = newSamples(i-1);
					continue;
				elseif  intervalEnd <= oldTime(1) && strcmp(outsideRangeHandling, 'repeat-border')
					newSamples(i) = oldSamples(1);
				end
				
				% finds everything in between now and the next time index
				curMatch = find(intervalStart <= oldTime & oldTime < intervalEnd);
				
				% saves this to a future iteration to fill
				if isempty(curMatch) % faster than test length == 0
					
					if i == 1 || any(lookBackFill == (i-1))
						lookBackFill = [lookBackFill, i];
					else
						newSamples(i) = newSamples(i-1);
						
						% fills old empty values and clears the lookBack list
						newSamples(lookBackFill) = newSamples(i);
						lookBackFill = [];
					end
					
					continue;
				
				% if this is true there's no reason to use the area calculation.
				elseif length(curMatch) == 1
					newSamples(i) = oldSamples(curMatch);
					
					% fills old empty values and clears the lookBack list
					newSamples(lookBackFill) = oldSamples(curMatch);
					lookBackFill = [];
					
					continue;
				end
				
				% if the algorithm reaches this point, that means there's more than one sample between now and the next element in newTime
				
				% creates a temporary time array ranging from now to the last sample before the next value in newTime
				if useRow
					tempTime = [intervalStart, oldTime(curMatch(1:end-1)), intervalEnd];
				else
					tempTime = [intervalStart; oldTime(curMatch(1:end-1)); intervalEnd];
				end
				
				% calculates (by euler integration) the area under the oldSamples.
				area = sum(diff(tempTime).*oldSamples(curMatch));
				
				% the new sample respects the area of the old samples
				newSamples(i) = area/(intervalEnd-intervalStart);
				
				% fills old empty values and clears the lookBack list
				newSamples(lookBackFill) = newSamples(i);
				lookBackFill = [];
			end
		end
		
		function newSamples = resampleForward2(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling)
			
			% uses the last interval as the look-ahead period
			Tf = 2*newTime(end) - newTime(end-1);
			
			% this will make the last sample of the new array be equal to
			% the last sample of the old array
			if useRow
				newTime = [newTime, Tf];
			else
				newTime = [newTime; Tf];
			end
			
			% used to go back in time and fill empty values
			lookBackFill = [];
			
			for i = 1:length(newTime)-1
				% timespan of the current iteration
				intervalStart = newTime(i);
				intervalEnd = newTime(i+1);
				
				% if it's past the end of the original signal, ends the
				% processing or keeps repeating the last sample, depeding
				% on the handler selected
				if oldTime(end) < intervalStart && (strcmp(outsideRangeHandling, 'zeros') || strcmp(outsideRangeHandling, 'nan'))
					break;
				elseif oldTime(end) < intervalStart && strcmp(outsideRangeHandling, 'repeat-border')
					newSamples(i) = newSamples(i-1);
					continue;
				elseif  intervalEnd <= oldTime(1) && strcmp(outsideRangeHandling, 'repeat-border')
					newSamples(i) = oldSamples(1);
				end
				
				% finds the first sample before now
				firstBehind = find(oldTime < intervalStart, 1, 'last');
				if isempty(firstBehind)
					firstBehind = intervalStart;
				else
					firstBehind = oldTime(firstBehind);
				end
				
				% finds everything in between now and the next time index
				curMatch = find(intervalStart <= oldTime & oldTime < intervalEnd);
				
				if isempty(curMatch) % faster than test length == 0
					if i == 1 || any(lookBackFill == (i-1))
						lookBackFill = [lookBackFill, i];
					else
						newSamples(i) = newSamples(i-1);
						
						% fills old empty values and clears the lookBack list
						newSamples(lookBackFill) = newSamples(i);
						lookBackFill = [];
					end
					
					continue;
				
				% if this is true there's no reason to use the area calculation.
				elseif length(curMatch) == 1
					newSamples(i) = oldSamples(curMatch);
					continue;
				end
				
				% if the algorithm reaches this point, that means there's more than one sample between now and the next element in newTime
				
				% creates a temporary time array ranging from the first sample before now and the last sample before the next value in newTime
				if useRow
					tempTime = [firstBehind, oldTime(curMatch)];
				else
					tempTime = [firstBehind; oldTime(curMatch)];
				end
				
				% calculates (by euler integration) the area under the oldSamples.
				area = sum(diff(tempTime).*oldSamples(curMatch));
				
				% the new sample respects the area of the old samples
				newSamples(i) = area/(intervalEnd - intervalStart);
				
				% fills old empty values and clears the lookBack list
				newSamples(lookBackFill) = newSamples(i);
				lookBackFill = [];
			end
		end
		
		function newSamples = resampleBackward1(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling)
			
			% uses the first interval as the first look-behind period.
			t0 = 2*newTime(1) - newTime(2);
			
			% this will make the first sample of the new array be equal to
			% the first sample of the old array
			if useRow
				newSamples = [newSamples(1), newSamples];
				newTime = [t0, newTime];
			else
				newSamples = [newSamples(1); newSamples];
				newTime = [t0; newTime];
			end
			
			% used to go back in time and fill empty values
			lookBackFill = [];
			
			for i = 2:length(newTime)
				% timespan of the current iteration
				intervalStart = newTime(i-1);
				intervalEnd = newTime(i);
				
				% finds everything in between now and the time before
				curMatch = find(intervalStart <= oldTime & oldTime < intervalEnd);
				
				% faster than test length == 0
				if isempty(curMatch)
					% if it's past the end of the original signal, ends the
					% processing or keeps repeating the last sample, depeding
					% on the handler selected
					if oldTime(end) < intervalStart && (strcmp(outsideRangeHandling, 'zeros') || strcmp(outsideRangeHandling, 'nan'))
						break;
					elseif oldTime(end) < intervalStart && strcmp(outsideRangeHandling, 'repeat-border')
						newSamples(i) = newSamples(i-1);
						continue;
					end
					
					if i == 2 || any(lookBackFill == (i-1))
						lookBackFill = [lookBackFill, i];
					else
						newSamples(i) = newSamples(i-1);
						
						% fills old empty values and clears the lookBack list
						newSamples(lookBackFill) = newSamples(i);
						lookBackFill = [];
					end
					
					continue;
				
				% if this is true there's no reason to use the area calculation.
				elseif length(curMatch) == 1
					newSamples(i) = oldSamples(curMatch);
					continue;
				end
				
				% if the algorithm reaches this point, that means there's more than one sample between now and the next element in newTime
				
				% creates a temporary time array ranging from now to the last sample before the next value in newTime
				if useRow
					tempTime = [intervalStart, oldTime(curMatch(1:end-1)), intervalEnd];
				else
					tempTime = [intervalStart; oldTime(curMatch(1:end-1)); intervalEnd];
				end
				
				% calculates (by euler integration) the area under the oldSamples.
				area = sum(diff(tempTime).*oldSamples(curMatch));
				
				% the new sample respects the area of the old samples
				newSamples(i) = area/(intervalEnd-intervalStart);
				
				% fills old empty values and clears the lookBack list
				newSamples(lookBackFill) = newSamples(i);
				lookBackFill = [];
			end
			
			newSamples(1) = [];
		end
	end
end