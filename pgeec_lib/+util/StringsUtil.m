classdef StringsUtil
	% Collection of commonly needed string handling methods.
	%
	% Most of them are actually copycats of existing MATLAB function's but
	% in a way that is legacy-compatible.
	
	methods(Static)
		function contains = contains(str, search)
		% Determine if pattern is in strings in a legacy-compatible way (works from R2006 on).
			contains = ~isempty(strfind(str, search));
		end
		
		function startsWith = startsWith(str, search)
		% Determine if strings start with pattern in a legacy-compatible manner (works from R2006 on).
			startsWith = false;
			
			% provides compatibility with "String"
			str = char(str);
			search = char(search);
			
			tmpResult = strfind(str, search);
			if isempty(tmpResult)
				return
			end
			
			startsWith = tmpResult(1) == 1;
		end
		
		function endsWith = endsWith(str, search)
		% Determine if strings end with pattern in a legacy-compatible manner (works from R2006 on).
			endsWith = false;
			
			% provides compatibility with "String"
			str = char(str);
			search = char(search);
			
			tmpResult = strfind(str, search);
			if isempty(tmpResult)
				return
			end
			
			endsWith = tmpResult(end) == length(str)-length(search)+1;
		end
		
		function output = split(str, delimiter, includeBorders)
		% Split string or character vector at specified delimiter.
		%
		% C = StringsUtil.SPLIT(str, delimiter) splits str at the delimiters specified by delimiter.
		% If str has consecutive delimiters, with no other characters
		% between them, then STRSPLIT treats them as two separate
		% delimiters and returns an empty char array. For example,
		% SPLIT('Hello,,,world',',') would return {'Hello', '', '', 'world'}
		% If str has delimiters at the beginning or at the end, then
		% SPLIT also inserts empty chars to the answer UNLESS
		% includeBorders is set to false (third argument).
		%
		% DELIMITER can be a single char, like '/', a word like 'break' or
		% a list of both {'/', '\', ...}.
		
			import util.TypesUtil
		
			% input verification
			TypesUtil.mustBeTxt(str);
			str = char(str);
			
			% argument verification
			if TypesUtil.isTxt(delimiter)
				delimiter = {delimiter};
			else
				if ~iscell(delimiter)
					error('DELIMITERS must be a string scalar, character vetor or a cell array of them.');
				end
			end
			if nargin < 3
				includeBorders = true;
			end
		
			% finds the indexes of all occurrences of all delimiters
			output   = TypesUtil.emptyCellArray;
			findings = TypesUtil.empty;
			for i = 1:length(delimiter)
				findings = [findings, strfind(str, delimiter{i})];
			end
			
			% puts them in order and takes only the unique indices
			% TODO: check if this is really necessary
			findings = unique(sort(findings));
			
			% handles no-matches case
			if isempty(findings)
				output = [{str}];
				return;
			end
			
			% --splitting the string over the given indexes
			
			% handles first index
			if findings(1) == 1 && includeBorders
				output = [output, {''}];
			else
				output = [output, {str(1:findings(1)-1)}];
			end

			% iterates over findings array
			for i = 2:length(findings)
				output = [output, {str(findings(i-1)+1:findings(i)-1)}];
			end

			% handles last index
			if findings(end) == length(str) && includeBorders
				output = [output, {''}];
			else
				output = [output, str(findings(end)+1:end)];
			end
		end
		
		function output = join(strCell, delimiter)
		% Combine strings
		%
		% Examples:
		% output = util.StringsUtil.join({'.*csv', '.*xlsx'}, ';')
		% outputs '.*csv;.*xlsx'
			import util.TypesUtil
		
			% checks if it is string
			TypesUtil.mustBeTxt(delimiter);
			
			% if is a single text, there's nothing to be done.
			if TypesUtil.isTxt(strCell)
				output = strCell;
				return;
			end
			
			% checks if it is string
			TypesUtil.mustBeTxt(delimiter);
			
			output = sprintf(['%s', delimiter], strCell{:});
			output = output(1:end-1);
		end
	end
end

