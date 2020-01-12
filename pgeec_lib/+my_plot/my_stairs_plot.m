function [my_figure, my_plot] = my_stairs_plot(x, y, my_figure)
%MY_LINE_PLOT fun��o de plotagem personalizada
%   Cria figuras formatadas para impress�o em trabalho acad�mico.
	import my_plot.*

	if exist('my_figure', 'var')
		my_figure = get_figure(my_figure);
	else
		my_figure = get_figure();
	end
	
	hold on;
	my_plot = stairs(x, y);
	format_line_plot(my_figure, my_plot);
	hold off;
end

