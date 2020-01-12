% clear;
clc;

import my_plot.*
import gams.tests.KeriMicrogrid.*

%% TIME DISCRETIZATION
t  = 1:30;
dt = [5/60*ones(6, 1); 0.5; ones(23, 1)];
%% GENERAL OPTIONS
daysToSimulate = 1; % time horizon of the simulation
t0      = 0;        % hour of the day to start the simulation (can be decimal)
peakIni = 18;       % start of the peak demand pricing
peakEnd = 21;       % end   of the peak demand pricing

%% BATTERY
%PHYSICAL SETUP
batCount = 2;     % battery quantity 
batSize  = 16;    % capacity (per battery) [kWh]
batPrice = 33660; % battery total cost (per battery) [R$]
soc_max  = 0.80;  % maximum state of charge [0-100%]
soc_min  = 0.42;  % minimum state of charge [0-100%]
soc_ini  = 0.80;  % initial state of charge [0-100%]
soc_fin  = 0.80;  % ending  state of charge [0-100%]
psmax    = 20.6;  % maximum rate of discharge [kWh]
psmin    = 19.0;  % maximum rate of charge [kWh]
nf       = 0.002; % rate of self discharge [% per hour]

%WEAR MODEL
a0	     = 694;   % curve fit coefficient [ACC(dod) = a0*dod^-a1]
a1	     = 0.795; % curve fit coefficient [ACC(dod) = a0*dod^-a1]
socCount = 15;    % number of points used on the SOC discretization
dodCount = socCount; % number of points used on the DOD discretization. IT'S VERY VERY ADVISABLE TO USED AN ODD NUMBER

%EFFICIENCY
disEffic = 0.9;   % discharge efficiency [0-100%]
chaEffic = 0.9;   % charge efficiency [0-100%]

%% DIESEL GENERATOR CONFIGURATION
%PHYSICAL SETUP
DG_startup_cost = 6.8; % diesel generator startup cost
diesel_cost		= 2.9; % diesel cost (R$ per litre)
Pi_nominal		= 0;  % nominal generator power [kWh], zero to turn off

%CONSUMPTION MODEL
a = 0.004446; % fuel consumption modeling parameter [c = a×Pi² + b×Pi + c]
b = 0.121035; % fuel consumption modeling parameter [c = a×Pi² + b×Pi + c]
c = 1.653882; % fuel consumption modeling parameter [c = a×Pi² + b×Pi + c]

%% DEMAND (net_load = demand - solar generation)
%FIXME: load this values from spreadsheet
net_load = [
	6.56
	6.56
	6.27
	6.27
	6.44
	6.44
	6.57
	6.31
	9.81
	15.24
	19.94
	20.94
	21.60
	23.74
	26.08
	25.68
	26.16
	28.70
	28.13
	28.73
	19.83
	19.77
	19.97
	17.17
	17.44
	24.17
	22.92
	21.24
	12.42
	8.66 
	]';

thora = {'ponta', 'foraponta'};
map_th = {'1*24', 'foraponta';
		  '25*27', 'ponta';
		  '28*30', 'foraponta'};
	  
demandas_contratadas = {'ponta', 20; 'foraponta', 24.7577};

runKeriModel();

fprintf('Total MG operational cost: R$ %4.4f\n', model.read('z'));

dayHour = cumsum(model.read('dt'));
[demandas, ~] = model.lookup('map_th', 'demandas_contratadas');

venda  = model.read('prv', 't');
compra = model.read('prc', 't');
compraLiq = compra - venda;
soc = model.read('soc', 't');


% [my_figure, my_plot ]= my_line_plot(dayHour, soc, 'SOC');
% my_figure = my_stairs_plot(dayHour, demandas, my_figure);
% set_limits(my_figure, [0 30], 'y');