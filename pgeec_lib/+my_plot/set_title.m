function my_figure = set_title(my_figure, my_title)
%SET_TITLE Summary of this function goes here
%   Detailed explanation goes here
	import my_plot.*
	
	LOAD_GLOBALS;
	
	get_figure(my_figure);
	
	figure(my_figure.Number); %seleciona figura para poder editar
	title(my_title, 'fontsize', TITLE_FONT_SIZE, 'fontname', FONT_TYPE, 'fontweight', TITLE_FONT_WEIGHT);
end

