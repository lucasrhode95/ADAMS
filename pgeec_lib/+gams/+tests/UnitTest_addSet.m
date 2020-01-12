%% SETUP
clear; clc;

import gams.*

debugMode = true;
keepFiles = false;
modelFile = '+gams/+tests/model_addSet.gms';

% the total cost should be 2.256551342812934e+02, this is tested after
% every call to .run()












%% TEST 1
fprintf('TEST MULTI-DIMENSIONAL SET, OPT 1\n\n');
% Since we're using a cell-char-array, we can mix double and char data (the
% GAMSmodel class will convert it to char anyway).
%
% Keep in mind that the first column shoul point to values of set 't' and
% second column should point to values of Set 'thora'.
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

map_th = { 1,   'foraponta';
		   2,   'foraponta';
		   3,   'foraponta';
		  '4',  'foraponta';
		  '5',  'foraponta';
		  '6',  'foraponta';
		  '7',  'foraponta';
		  '8',  'foraponta';
		  '9',  'foraponta';
		  '10'  'foraponta';
		  '11', 'foraponta';
		  '12', 'foraponta';
		  '13', 'foraponta';
		  '14', 'foraponta';
		  '15', 'foraponta';
		  '16', 'foraponta';
		  '17', 'foraponta';
		  '18', 'foraponta';
		  '19', 'foraponta';
		  '20', 'foraponta';
		  '21', 'foraponta';
		  '22', 'foraponta';
		  '23', 'foraponta';
		  '24', 'foraponta';
		  '25', 'ponta';
		  '26', 'ponta';
		  '27', 'ponta';
		  '28', 'foraponta';
		  '29', 'foraponta';
		  '30', 'foraponta'};

model.addSet('t', 1:30);
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana'; 'fimsemana'}); % Either column or row works
model.addSet('map_th', map_th, 't', 'thora'); % Domain Sets must be passed in order
model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

timeInHours = cumsum(model.read('dt'));
fprintf('total microgrid operation cost in %4.2f h: %4.4f\n', timeInHours(end), model.read('z'));
% my_line_plot(timeInHours, model.read('soc', 't'));














%% TEST 2
fprintf('\n\nTEST MULTI-DIMENSIONAL SET, OPT 2\n\n');
% Since Set 't' is numeric, we can exploit that to shorten our definition
% using a 2D double-array Set.
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

% First, buffer all the depencies
model.addSet('t', 1:30);
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana', 'fimsemana'});

% Now we can exploit MATLAB's array-initialization shorthands
map_th = [ (1:24)', ones(24, 1)*model.getBufferedLabelNumber('thora', 'foraponta'); %off-peak demand hours
		  (25:27)',	ones(3, 1)*model.getBufferedLabelNumber('thora', 'ponta');      %peak demand hours
		  (28:30)', ones(3, 1)*model.getBufferedLabelNumber('thora', 'foraponta')]; %off-peak

model.addSet('map_th', map_th, 't', 'thora');
model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

% timeInHours = cumsum(model.read('dt'));
% fprintf('total microgrid operation cost in %4.2f h: %4.4f\n', timeInHours(end), model.read('z'));
% my_line_plot(timeInHours, model.read('soc'));














%% TEST 3
fprintf('\n\nTEST MULTI-DIMENSIONAL SET, OPT 3\n\n');
% GAMSmodel supports the m*n notation
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

% First, buffer all the depencies
model.addSet('t', 1:30);
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana', 'fimsemana'});

% Now use the even shorter notation:
map_th = {'1*24', 'foraponta';
		  '25*27', 'ponta';
		  '28*30', 'foraponta'};

model.addSet('map_th', map_th, 't', 'thora');
model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

% timeInHours = cumsum(model.read('dt'));
% fprintf('total microgrid operation cost in %4.2f h: %4.4f\n', timeInHours(end), model.read('z'));
% my_line_plot(timeInHours, model.read('soc'));













%% TEST 4
fprintf('\n\nTEST MULTI-DIMENSIONAL SET, OPT 4\n\n');
% GAMSmodel supports the m*n notation
model = GAMSModel(modelFile, debugMode);
model.KEEP_FILES = keepFiles;

% First, buffer all the depencies
model.addSet('t', {'1*30'});
model.addSet('thora', {'ponta', 'foraponta'});
model.addSet('tdia', {'semana', 'fimsemana'});

% Now use the even shorter notation:
map_th = {'1*24', 'foraponta';
		  '25*27', 'ponta';
		  '28*30', 'foraponta'};

model.addSet('map_th', map_th, 't', 'thora');
model.run();
assert(model.read('z')-2.256551342812934e+02 <= 1e-6);

% timeInHours = cumsum(model.read('dt'));
% fprintf('total microgrid operation cost in %4.2f h: %4.4f\n', timeInHours(end), model.read('z'));
% my_line_plot(timeInHours, model.read('soc'));







%% TEST 5
fprintf('\n\nTEST MULTI-DIMENSIONAL SET, OPT 4\n\n');
% GAMSmodel supports the m*n notation
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

% timeInHours = cumsum(model.read('dt'));
% fprintf('total microgrid operation cost in %4.2f h: %4.4f\n', timeInHours(end), model.read('z'));
% my_line_plot(timeInHours, model.read('soc'));