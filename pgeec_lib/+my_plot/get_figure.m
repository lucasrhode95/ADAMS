function my_figure = get_figure(my_figure)
%GET_FIGURE retorna e seleciona figura que já foi criada ou uma nova.
%   O parâmetro string my_figure é usado como identificado para encontrar a
%   figura por nome. Caso não encontre, cria nova com o nome dado.
%   A nova figura retornada já estará formatada nos padrões do
%   mini-framework.
	import my_plot.*

	if ~exist('my_figure','var')
		my_figure = figure(); %cria nova figura
		format_figure(my_figure);
		disp(['Criando nova figura... (' int2str(my_figure.Number) ')']);
	else
		if isa(my_figure, 'char') || isa(my_figure, 'string')
			my_figure_str = my_figure;
			my_figure = new_figure_by_name(my_figure); %pega figura por nome e a seleciona
			format_figure(my_figure);
			set_title(my_figure, my_figure_str);
		elseif ~isa(my_figure, 'matlab.ui.Figure') && ~isa(my_figure, 'matlab.ui.control.UIAxes') && ~isa(my_figure, 'matlab.graphics.axis.Axes')
			error('Tipo do argumento #3 (%s) não reconhecido!', class(my_figure))
		end
	end
	
	if isa(my_figure, 'matlab.ui.Figure')
		figure(my_figure.Number); %seleciona figura, independente de onde tenha sido criada nas linhas acima
	end
end

