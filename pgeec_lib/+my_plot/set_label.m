function my_figure = set_label(my_figure, label, axis)
%SET_LABEL Summary of this function goes here
%   Detailed explanation goes here
	import my_plot.*
	
	LOAD_GLOBALS;
	
	target = get_figure(my_figure);
	
	if ~exist('axis','var')
		axis = 'xy';
	end
	
% 	figure(target.Number); %seleciona figura para poder editar
	
	target = target.Children(end);
	switch axis
		case 'x'
			xlabel(target, label);
		case 'y'
			ylabel(target, label);
		case {'xy', 'yx'}
			xlabel(target, label);
			ylabel(target, label);
		case 'z'
			zlabel(target, label);
		case 'colorbar'
			colorTitleHandle = colorbar;
			set(get(colorTitleHandle,'Title'), 'String', label);
		otherwise
			error('Valor do argumento #3 não foi reconhecido');
	end
end

