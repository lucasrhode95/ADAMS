%% SETUP
clear; clc;
import gams.GAMSModel
import util.FilesUtil
gams.tests.startup

debugMode = true;
keepFiles = false;
modelFile = '+gams/+tests/model_addSet.gms';





%% PROLOGUE
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


%% TEST 1
dir = tempdir(); % comment this out to be prompted with a folder selection window

if ~exist('dir', 'var')
	dir = util.FilesUtil.uiGetDir('Select folder to export the project');
end

if isempty(dir)
	disp('TEST #1 CANCELLED.');
else
	model.exportModelData(dir)
	disp('TEST PASSED.');
end