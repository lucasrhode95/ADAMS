function my_plot = format_surf_plot(my_figure, my_plot)
%FORMAT_PLOT formata plot de superfície.
	import my_plot.*
	LOAD_GLOBALS;

	my_figure.Color = [1 1 1];
	colormap(COLOUR_MAP);
	
	% Add a colobar
	if ADD_COLOUR_BAR
		colorbar();
	end
	
	if REMOVE_EDGES
		my_plot.EdgeColor = 'none';
	end
end