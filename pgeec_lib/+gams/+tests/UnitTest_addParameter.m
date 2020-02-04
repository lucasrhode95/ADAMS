%% SETUP
clear; clc;
import gams.GAMSModel
gams.tests.startup

debugMode = true;
keepFiles = false;
modelFile = '+gams/+tests/model_addParameter.gms';

% the total cost should be 2.256551342812934e+02, this is tested after
% every call to .run()



%% TEST 1
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

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
	];

tarifas = ...
{'semana',    'ponta',     28.85
 'semana',    'foraponta',  8.82
 'fimsemana', 'ponta',      8.82
 'fimsemana', 'foraponta',  8.82};

model.addSet('t', 1:30);
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana'; 'fimsemana'});

model.addParameter('DL', net_load, 't');
model.addParameter('tarifas_demandas', tarifas, 'tdia', 'thora');
model.addScalar('a', 0.004446);
% model.addParameter('a', 0.004446); % adding a scalar as a parameter also works

model.clearBuffer('thora', 'tdia');

model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

fprintf('Total microgrid operation cost: %4.4f\n', model.read('z'));







%% TEST 2
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

tarifas = ...
{'semana',    'ponta',     28.85
 'semana',    'foraponta',  8.82
 'fimsemana', 'ponta',      8.82
 'fimsemana', 'foraponta',  8.82};

model.addSet('t', '1*30');
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana'; 'fimsemana'});

model.addParameter('DL', net_load, 't');
model.addParameter('tarifas_demandas', tarifas, 'tdia', 'thora');
% model.addScalar('a', 0.004446);
model.addParameter('a', 0.004446); % adding a scalar as a parameter also works

model.clearBuffer('thora', 'tdia');

model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

fprintf('Total microgrid operation cost: %4.4f\n', model.read('z'));

disp('TEST PASSED.');