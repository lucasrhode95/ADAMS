function figure_handle = new_figure_by_name(figure_name)
	import my_plot.*
	
	figure_handle = findobj('type', 'figure', 'name', figure_name);
	if isempty(figure_handle)
		disp('Criando nova figura...');
		figure_handle = figure();
		figure_handle.Name = figure_name;
	end
end