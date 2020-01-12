%% I used this to unit-test the Load.updateTimeInfo method.
% The method was yielding weird results because the TimeSeriesUtil.respan
% method was being called with wrong arguments.
% The solution was to set the border handling to: left=outside and right=inside.

clear; clc;

microgrid_model.MGElement.developmentMode(true);
microgrid_model.MGElement.warningsOn(true);

myLoad = microgrid_model.LoadConstant();
myLoad.importDemandProfile(fullfile(util.FilesUtil.getParentDir(), 'load1.xlsx'));

figure(2);
stairs(myLoad.getTimeArray(), myLoad.getDemandProfile(), 's');

newTime = [5 10 15 20 25 30 60*(1:120)];

myLoad.publicTest(newTime);


figure(2)
hold on
stairs(newTime, myLoad.getDemandProfile)
hold off