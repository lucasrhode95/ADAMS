classdef TimeSeriesUtil
	% Collection of commonly needed methods for handling time series
	
	methods(Access = public, Static)
		
		function [newSamples, newTime, actualStart, actualEnd] = respan(oldTime, oldSamples, startTime, endTime, truncation, leftBorder, rightBorder)
			% VV INPUT SANITIZING
			if nargin >= 5
				util.TypesUtil.mustBeTxt(truncation);
			else
				truncation = 'default';
			end
			if nargin >= 6
				util.TypesUtil.mustBeTxt(leftBorder);
				if ~strcmp(leftBorder, 'outside') && ~strcmp(leftBorder, 'inside')
					error('Invalid argument value. Valid ones are inside|outside');
				end
			else
				leftBorder = 'outside';
			end
			if nargin >= 7
				util.TypesUtil.mustBeTxt(rightBorder);
				if ~strcmp(rightBorder, 'outside') && ~strcmp(rightBorder, 'inside')
					error('Invalid argument value. Valid ones are inside|outside');
				end
			else
				rightBorder = 'outside';
			end
			validateattributes(startTime, {'numeric'}, {'finite'});
			validateattributes(endTime, {'numeric'}, {'finite', '>', startTime});
			validateattributes(oldTime, {'numeric'}, {'finite', 'increasing'});
			validateattributes(oldSamples, {'numeric'}, {'finite'});
			if length(oldTime) ~= length(oldSamples)
				error('oldTime and oldSamples must have the same length');
			end
			if ~isrow(oldTime) && ~iscolumn(oldTime)
				error('Time array must be one-dimensional.');
			end
			if ~isrow(oldSamples) && ~iscolumn(oldSamples)
				error('Samples array must be one-dimensional.');
			end

			useRow = isrow(oldTime);

			if useRow
				if iscolumn(oldSamples)
					oldSamples = oldSamples';
				end
			else
				if isrow(oldSamples)
					oldSamples = oldSamples';
				end
			end
			% ^^ INPUT SANITIZING

			% VV GENERATE SAMPLES BEFORE THE ACTUAL SIGNAL
			timeStep = diff(oldTime);

			if useRow
				timeStep = [timeStep, timeStep(end)];
			else
				timeStep = [timeStep; timeStep(end)];
			end

			% variable initialization
			prependTime = [];
			prependSamples = [];

			% where to stop
			outsideBorder = strcmp(leftBorder, 'outside');
			
			% where to start
			now = oldTime(end);
			if ~outsideBorder
				now = now - timeStep(end);
			end
			
			% where to start
			now = oldTime(1);
			
			iterator = length(timeStep);
			while startTime < now
				if endTime < now
					continue;
				end
				
				if outsideBorder
					% prepares the iteration, either goes back further into the old
					% array or restarts at the end of it
					now = now - timeStep(iterator);
					if iterator == 1
						iterator = length(timeStep);
					else
						iterator = iterator - 1;
					end
				end
				
				if useRow
					prependTime    = [now, prependTime];
					prependSamples = [oldSamples(iterator), prependSamples];
				else
					prependTime    = [now; prependTime];
					prependSamples = [oldSamples(iterator); prependSamples];
				end
				
				if ~outsideBorder
					% prepares the iteration, either goes back further into the old
					% array or restarts at the end of it
					now = now - timeStep(iterator);
					if iterator == 1
						iterator = length(timeStep);
					else
						iterator = iterator - 1;
					end
				end
			end
			% ^^ GENERATE SAMPLES BEFORE THE ACTUAL SIGNAL

			% VV BASE WINDOW
			baseFilter  = startTime <= oldTime & oldTime <= endTime;
			baseTime    = oldTime(baseFilter);
			baseSamples = oldSamples(baseFilter);
			% ^^ BASE WINDOW

			% VV GENERATE SAMPLES AFTER THE ACTUAL SIGNAL
			timeStep = diff(oldTime);

			if useRow
				timeStep = [timeStep(end), timeStep];
			else
				timeStep = [timeStep(end); timeStep];
			end

			appendTime = [];
			appendSamples = [];
			
			% where to stop
			outsideBorder = strcmp(rightBorder, 'outside');
			
			% where to start
			now = oldTime(end);
			if ~outsideBorder
				now = now + timeStep(1);
			end
			
			iterator = 1;
			while now < endTime
				
				if outsideBorder
					% prepares the iteration, either goes back further into the old
					% array or restarts at the end of it
					now = now + timeStep(iterator);
					if iterator == length(timeStep)
						iterator = 1;
					else
						iterator = iterator + 1;
					end
				end
				
				if now < startTime
					continue;
				end
				
				if useRow
					appendTime    = [appendTime, now];
					appendSamples = [appendSamples, oldSamples(iterator)];
				else
					appendTime    = [appendTime; now];
					appendSamples = [appendSamples; oldSamples(iterator)];
				end
				
				if ~outsideBorder
					% prepares the iteration, either goes back further into the old
					% array or restarts at the end of it
					now = now + timeStep(iterator);
					if iterator == length(timeStep)
						iterator = 1;
					else
						iterator = iterator + 1;
					end
				end
			end
			% ^^ GENERATE SAMPLES AFTER THE ACTUAL SIGNAL

			% VV RESULT TREATMENT
			newTime    = [prependTime; baseTime; appendTime];
			newSamples = [prependSamples; baseSamples; appendSamples];

			actualStart = newTime(1);
			actualEnd   = newTime(end);

			if strcmp(truncation, 'default')
				% do nothing
			elseif strcmp(truncation, 'truncate')
				newTime(1)   = startTime;
				newTime(end) = endTime;
			elseif strcmp(truncation, 'snap-left')
				timeStep = diff(newTime);
				if useRow
					newTime = cumsum([startTime, timeStep]);
				else
					newTime = cumsum([startTime; timeStep]);
				end
			elseif strcmp(truncation, 'snap-right')
				timeStep = diff(newTime(end:-1:1));
				if useRow
					newTime = cumsum([endTime, timeStep]);
				else
					newTime = cumsum([endTime; timeStep]);
				end

				newTime = newTime(end:-1:1);
			else
				error('Invalid value for argument handleBorders. Valid values: truncate|snap-left|snap-right');
			end
			% ^^ RESULT TREATMENT
			
			% VV DEBUG
% 			stairs(prependTime, prependSamples, '*');
% 			hold on;
% 			stairs(newTime, newSamples);
% 			stairs(baseTime, baseSamples, '*');
% 			stairs(appendTime, appendSamples, '*');
% 			hold off;
			% ^^ DEBUG
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
			util.TypesUtil.mustBeNotEmpty(oldArray);
			validateattributes(newLength, {'numeric'}, {'integer', 'positive'});
		
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
			
			% validates arguments
			validateattributes(oldSamples, {'numeric'}, {'vector'});
			validateattributes(oldTime, {'numeric'}, {'vector', 'increasing'});
			validateattributes(newTime, {'numeric'}, {'vector', 'increasing'});
			if length(oldTime) ~= length(oldSamples)
				error('oldSamples and oldTimeArray must have the same length');
			end
			
			% if input is empty, outout is empty as well
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
				util.TypesUtil.mustBeTxt(processingMode);
			else
				processingMode = 'forward1';
			end
			
			if nargin >= 5
				util.TypesUtil.mustBeTxt(outsideRangeHandling);
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
					newSamples = util.TimeSeriesUtil.resampleForward1(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling);
				case 'forward2'
					newSamples = util.TimeSeriesUtil.resampleForward2(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling);
				case 'backward'
					newSamples = util.TimeSeriesUtil.resampleBackward1(newSamples, oldTime, oldSamples, newTime, useRow, outsideRangeHandling);
				otherwise
					error('Input "%s" not recognized. Valid arguments are %s', processingMode, 'forward|forward1|forward2|backward');
			end
			
% 			old techinique for error highlighting
% 			for i = 1:length(newSamples)
% 				if isnan(newSamples(i))
% 					newSamples(i) = 1000;
% 				end
% 			end
		end
	end
	
	methods(Static, Access = private)
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