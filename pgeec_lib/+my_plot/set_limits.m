function my_figure = set_limits(my_figure, limits, axis)
%SET_LIMITS Summary of this function goes here
%   Detailed explanation goes here
	import my_plot.*
	
	LOAD_GLOBALS;

	target = get_figure(my_figure);
	
	if ~exist('axis','var')
		axis = 'xy';
	end
	
	target = target.Children;
	for i = 1:length(target)
		switch axis
			case 'x'
				xlim(target, limits);
			case 'y'
				ylim(target, limits);
			case {'xy', 'yx'}
				xlim(target, limits);
				ylim(target, limits);
			otherwise
				error('Valor do argumento #3 não foi reconhecido');
		end
	end
	
	if AUTO_DXY
		set_dxy(my_figure, 'reload');
	end
end

