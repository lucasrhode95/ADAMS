function my_figure = set_dxy(my_figure, dxy, axis)
%SET_DXY Summary of this function goes here
%   Detailed explanation goes here
	import util.TypesUtil
	import my_plot.*
	LOAD_GLOBALS;
	
	figure = get_figure(my_figure);

	if isa(figure, 'matlab.ui.control.UIAxes') || isa(figure, 'matlab.graphics.axis.Axes')
		target = figure;
	else
		target = figure.Children;
		for i = length(target):-1:1
			if ~isa(target(i), 'matlab.ui.control.UIAxes') && ~isa(target(i), 'matlab.graphics.axis.Axes')
				target(i) = [];
			end
		end
	end
	
	try
		Xlim = get(target, 'Xlim');
		Ylim = get(target, 'Ylim');
		
		try
			XData = get(target, 'XData');
			YData = get(target, 'YData');
		catch
			try
				XData = get(target.Children, 'XData');
				YData = get(target.Children, 'YData');
			catch
				XData = get(target.Children, 'Xlim');
				YData = get(target.Children, 'Ylim');
			end
		end
		
		if ~iscell(XData)
			XData = {XData};
		end
		if ~iscell(YData)
			YData = {YData};
		end
		
		minX = 0;
		maxX = 0;
		for i = 1:length(XData)
			for j = 1:length(XData{i})
				if ~isinf(XData{i}(j))
					if i == 1 && j == 1
						minX = XData{i}(j);
						maxX = XData{i}(j);
					else
						minX = min(minX, XData{i}(j));
						maxX = max(maxX, XData{i}(j));
					end
				end
			end
		end
		
		minY = 0;
		maxY = 0;
		for i = 1:length(YData)
			for j = 1:length(YData{i})
				if ~isinf(YData{i}(j))
					if i == 1 && j == 1
						minY = YData{i}(j);
						maxY = YData{i}(j);
					else
						minY = min(minY, YData{i}(j));
						maxY = max(maxY, YData{i}(j));
					end
				end
			end
		end
		
		if isinf(Xlim(1))
			Xlim(1) = minX;
		end
		if isinf(Xlim(2))
			Xlim(2) = maxX;
		end
		if isinf(Ylim(1))
			Ylim(1) = minY;
		end
		if isinf(Ylim(2))
			Ylim(2) = maxY;
		end
	catch e
		disp(getReport(e));
		
		XData = get(target, 'XData');
		YData = get(target, 'YData');
		Xlim = [XData(1), XData(end)];
		Ylim = [YData(1), YData(end)];
	end
	
	if ~exist('axis','var')
		axis = 'xy';
	else
		TypesUtil.mustBeTxt(axis);
	end
	
	if ~strcmp(axis, 'reload')
		if ~exist('dxy','var')
			dy = diff(my_figure.Children.YLim);
			dx = diff(my_figure.Children.XLim);

			yTick = Ylim(1):dy/TICKS_DEFAULT:Ylim(end);
			xTick = Xlim(1):dx/TICKS_DEFAULT:Xlim(end);
		else
			yTick = Ylim(1):dxy:Ylim(end);
			xTick = Xlim(1):dxy:Xlim(end);
		end
	else
		yTick = Ylim(1):my_figure.Children.YTick(2)-my_figure.Children.YTick(1):Ylim(end);
		xTick = Xlim(1):my_figure.Children.XTick(2)-my_figure.Children.XTick(1):Xlim(end);
	end
	
% 	xTickStr = point2comma(xTick);
% 	yTickStr = point2comma(yTick);

	switch axis
		case 'x'
			set(target, 'XTick', xTick)
% 			set(gca, 'XTick', xTick)
% 			set(gca, 'XTickLabel', xTickStr)
		case 'y'
			set(target, 'YTick', yTick);
% 			set(gca, 'YTick', yTick)
% 			set(gca, 'YTickLabel', yTickStr)
		case {'xy', 'yx'}
			set(target, 'XTick', xTick);
			set(target, 'YTick', yTick);
			
% 			set(gca, 'YTick', yTick)
% 			set(gca, 'YTickLabel', yTickStr)
% 			set(gca, 'XTick', xTick)
% 			set(gca, 'XTickLabel', xTickStr)
		case 'reload'
			set(target, 'XTick', xTick);
			set(target, 'YTick', yTick);
			
% 			set(gca, 'YTick', yTick)
% 			set(gca, 'YTickLabel', yTickStr)
% 			set(gca, 'XTick', xTick)
% 			set(gca, 'XTickLabel', xTickStr)
		otherwise
			error('Valor do argumento #3 (%s) não foi reconhecido', axis);
	end
	
	if (AUTO_SET_COMMA_SEP)
		set_decimal_sep(my_figure, 'comma');
	end
end

