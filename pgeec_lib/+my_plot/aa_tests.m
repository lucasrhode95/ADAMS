clear;
clc;


x1 = 5/60:0.5:30;
y1 = sin(x1);
x2 = 5/60:0.5:30;
y2 = cos(x1);

%% default plot, two lines
[fig, ax] = my_plot.my_line_plot(x1, y1);
my_plot.my_stairs_plot(x2, y2, fig);

%% set dxy
my_plot.set_dxy(fig, 1, 'x');

%% set limits
my_plot.set_limits(fig, [-10, Inf], 'x');