%% SETUP
clear; clc;
import gams.GAMSModel
gams.tests.startup

debugMode = true;
keepFiles = false;
modelFile = '+gams/+tests/model_addSet.gms';

% the total cost should be 2.256551342812934e+02, this is tested after
% every call to .run()












%% TEST 1
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

% First, buffer all the depencies
model.addSet('t', '1*30');
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana', 'fimsemana'});

% Now use the even shorter notation:
map_th = {'1*24', 'foraponta';
		  '25*27', 'ponta';
		  '28*30', 'foraponta'};

model.addSet('map_th', map_th, 't', 'thora');
model.run();
assert(abs(model.read('z')-2.256551342812934e+02) <= 1e-6);

model.read('map_th') % original Set
model.read('demandas_contratadas') % lookup set
[value, labeled] = model.lookup('map_th', 'demandas_contratadas') % is pretty darn easy to join these values using the lookup function












%% TEST 2
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

% First, buffer all the depencies
model.addSet('t', '1*30');
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana', 'fimsemana'});

% Now use the even shorter notation:
map_th = {'1*24', 'foraponta';
		  '25*27', 'ponta';
		  '28*30', 'foraponta'};

model.addSet('map_th', map_th, 't', 'thora');
model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

% if you try to merge unrelated variables, it will return empty/NaN results
[value, labeled] = model.lookup('map_th', 't')












%% TEST 3
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

% First, buffer all the depencies
model.addSet('t', '1*30');
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana', 'fimsemana'});

% Now use the even shorter notation:
map_th = {'1*24', 'foraponta';
		  '25*27', 'ponta';
		  '28*30', 'foraponta'};

model.addSet('map_th', map_th, 't', 'thora');
model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

model.read('map_th') % original Set
model.read('demandas_contratadas') % lookup set
[value, labeled] = model.read('soc', 't') % also very easy is to perform a lookup+read




disp('TEST PASSED.');