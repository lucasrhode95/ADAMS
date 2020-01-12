function [my_figure, my_plot] = my_surf_plot(x, y, z, my_figure)
%MY_SURF_PLOT função de plotagem personalizada
%   Cria figuras formatadas para impressão em trabalho acadêmico.
	import my_plot.*
	LOAD_GLOBALS
	
	if exist('my_figure', 'var')
		my_figure = get_figure(my_figure);
	else
		my_figure = get_figure();
	end
	
	if (VECTOR_MODE)
		my_figure.Renderer = 'Painters';
	end
	
	hold on;
	my_plot = surf(x, y, z);
	format_surf_plot(my_figure, my_plot);
	hold off;
end
