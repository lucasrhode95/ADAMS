function my_figure = set_decimal_sep(my_figure, separator)
%UNTITLED2 Sets the decimal separator to either comma or point
%   Actually, currently I have only implemented the comma separator xD
	import my_plot.*
	
	get_figure(my_figure);
	
	xTick = get(gca, 'XTickLabel');
	yTick = get(gca, 'YTickLabel');
	
	if ~ischar(separator) || ~strcmp(separator, 'comma') % || strcmp(separator, 'point'))
		error('separator not supported.')
	end
	
	
	
	set(gca, 'XTickLabel', point2comma(xTick));
	set(gca, 'YTickLabel', point2comma(yTick));
end

