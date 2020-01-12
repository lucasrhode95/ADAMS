classdef CommonsUtil
	% Collection of commonly needed utility methods.
	
	methods(Access = public, Static)
		
		function strTimestamp = getTimestamp(fileFormat)
		% Returns a string containing the current system date-time.
		%
		% COMMONSUTIL.GETTIMESTAMP() Returns a string containing the
		% current system date-time on the format 'yyyy-MM-dd HH:mm:ss.SSS'
		%
		% COMMONSUTIL.GETTIMESTAMP(true) Returns a string containing the
		% current system date-time on the format 'yyyy_MM_dd_HH_mm_ss_SSS'
		% this format is useful to be used on file names.
		
			if nargin < 1
				fileFormat = false;
			else
				util.TypesUtil.mustBeLogical(fileFormat);
			end
			
			if fileFormat
				dateSep = '_';
				dateTimeSep = '_';
				timeSep = '_';
				msSep = '_';
			else
				dateSep = '-';
				dateTimeSep = ' ';
				timeSep = ':';
				msSep = '.';
			end
			
			time = clock();
			
			% year
			strTimestamp = num2str(time(1));
			% iterates through the date-time array, starting at position 2
			% (month) until position 6 (seconds.milliseconds)
			for i = 2:length(time)
				
				if floor(time(i)) < 10
					element = ['0' num2str(floor(time(i)))];
				else
					element = num2str(floor(time(i)));
				end
				
				if floor(time(i)) ~= time(i)
					remainder = floor((time(i) - floor(time(i)))*1000);
					element = [element msSep num2str(remainder)];
				end
				
				if i < 4
					strTimestamp = [strTimestamp dateSep element];
				elseif i==4
					strTimestamp = [strTimestamp dateTimeSep element];
				else
					strTimestamp = [strTimestamp timeSep element];
				end
			end
		end
		
		function log(message, varargin)
		% Logs a message to the command line in a default format.
			% vanilla mode:
% 			if nargin < 2
% 				fprintf(message);
% 			elseif iscell(args)
% 				fprintf(message, args{:});
% 			else
% 				fprintf(message, args);
% 			end
% 			return;
			import lib.cprintf.*
			
			% variable that tells if the last log had a new line character at the end.
			persistent lastLogNewLine;
			if isempty(lastLogNewLine)
				lastLogNewLine = true;
			end
		
			% color of the log (0.5 0.5 0.5 = gray
			style = [0.5, 0.5, 0.5];
			
			% collects the stack
			st = dbstack();
			
			% stack >= 2: call from another file/class
			% stack == 1: call from the command line
			% stack == 0: never happened on my tests
			if length(st) >= 2
				st = st(2);
			elseif length(st) == 1
				st = st(1);
			else
				st.name = '';
				st.line = 0;
			end
			
			% strips the package name from the class name
			st.name = util.StringsUtil.split(st.name, '.');
			if length(st.name) >= 2
				st.name = [st.name{end-1}, '.', st.name{end}];
			else
				st.name = st.name{end};
			end
			
			% if the last printed message had a line break at the end,
			% prepends '>' in front of it and fixes the length to 40
			% characters.
			if lastLogNewLine
				formatStr = '> %s | %s';
				logInfo = [st.name, ':', num2str(st.line)];
				
				logInfo = [logInfo repmat(' ',1, max(0, 40-length(logInfo)))];
				
				message = sprintf(formatStr, logInfo, message);
			end
			
			% checks if this message ends with \n.
			lastLogNewLine = util.StringsUtil.endsWith(message, '\n');
			
			% prints the message
			cprintf(style, message, varargin{:});
		end

	end
end