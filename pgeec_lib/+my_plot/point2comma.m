function axisStrTicksCell = point2comma(axisTicks)
%POINT2COMMA converts decimal arrays to comma-separated cell array of strings
	import my_plot.*

	if ~(iscell(axisTicks) || ischar(axisTicks{1}))
		error(['type ' class(axisTicks) ' not supported']);
	end
	
	axisStrTicksCell  = cell(size(axisTicks))';
	
	for i=1:length(axisTicks)
		axisStrTicksCell{i} = strrep(axisTicks{i}, '.', ',');
	end
	
% 	axisTicks
% 	dbstack
% 	axisStrTicksCell = axisStrTicksCell';
% 	assignin('base', 'TESTE', axisStrTicksCell);
end

