function my_figure = format_figure(my_figure)
	import my_plot.*

	LOAD_GLOBALS;

	figure(my_figure.Number); %seleciona figura para poder editar
	
	set(my_figure, 'Position', [100, 100, FIGURE_WIDTH, FIGURE_HEIGHT]);	
% 	set(my_figure, 'Position', [-1200, 0, 800, 800]);
	
	grid off;
	if GRID_ON_BY_DEFAULT || GRID_MINOR_BY_DEFAULT
		grid on;
		if GRID_MINOR_BY_DEFAULT
			grid minor;
		end
	end
	
	set(gca, 'FontSize', AXIS_FONT_SIZE);
	set(gca, 'FontName', FONT_TYPE);
end