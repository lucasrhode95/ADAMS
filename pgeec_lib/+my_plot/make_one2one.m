function my_figure = make_one2one(my_figure)
%MAKE_SQUARE Summary of this function goes here
%   Detailed explanation goes here
	import my_plot.*

	get_figure(my_figure);
	
	dy = diff(get(gca, 'YLim'));
	dx = diff(get(gca, 'XLim'));
	
	pbaspect([dx dy 1])
end

