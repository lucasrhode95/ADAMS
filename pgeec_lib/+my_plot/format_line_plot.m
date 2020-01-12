function my_plot = format_line_plot(my_figure, my_plot)
%FORMAT_PLOT formata plot de linha.	
	import my_plot.*
	LOAD_GLOBALS;
	
	my_figure.Color = [1 1 1];
	set(my_plot, 'LineWidth', LINE_WIDTH);
	
	if AUTO_DXY
		set_dxy(my_figure);
	end
end
