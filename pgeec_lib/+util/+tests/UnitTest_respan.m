import util.TimeSeriesUtil
import util.FilesUtil
clear;
clc;
clf;
testCount = 0;

testSwitch = true(1, 6);
% testSwitch(6) = true;
%% Test 1
% Tests if the method respects the options 'start-time'=oldTime(1) and
% 'end-time'=oldTime(end)
for i = 1:(4*testSwitch(1))
	testCount = testCount+1;
	input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), sprintf('load%d.xlsx', i)));
	oldTime = input(:, 1);
	oldSamples = input(:, 2);

	startTime = oldTime(1);
	endTime = oldTime(end);
	options = {
		'start-time', startTime;
		'end-time', endTime;
	};
	[newTime, newSamples] = TimeSeriesUtil.respan(oldTime, oldSamples, options);

	testplot(testCount, oldTime, oldSamples, newTime, newSamples);
	
	assert(newTime(1)==startTime);
	assert(newTime(end)==endTime);
	assert(length(newTime)==length(oldTime))
	assert(length(newTime)==length(newSamples));
end




%% Test 2
% Tests if the 'enlarge' border option is working correctly
for i = 1:(5*testSwitch(2))
	testCount = testCount+1;
	if i==5
		oldTime = 2*[0 100 300 600 1000 1500];
		oldSamples = oldTime;
	else
		input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), sprintf('load%d.xlsx', i)));
		oldTime = input(:, 1);
		oldSamples = input(:, 2);
	end

	N = 1;
	dur = 2*oldTime(end)-oldTime(1)-oldTime(end-1);
	startTime = oldTime(1) - N*dur;
	endTime = oldTime(1) + N*dur;
	options = {
		'start-time', startTime;
		'end-time', endTime;
		'left-border', 'enlarge';
		'right-border', 'enlarge';
	};
	
	[newTime, newSamples] = TimeSeriesUtil.respan(oldTime, oldSamples, options);
	
	testplot(testCount, oldTime, oldSamples, newTime, newSamples);

	assert(length(newTime)==length(newSamples));
	assert(endTime<=newTime(end));
	assert(newTime(1)<=startTime);
end




%% Test 3
% Tests if the 'reduce' border option is working correctly
for i = 1:(4*testSwitch(3))
	testCount = testCount+1;
	input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), sprintf('load%d.xlsx', i)));
	oldTime = input(:, 1);
	oldSamples = input(:, 2);

	startTime = oldTime(1)-1;
	endTime = oldTime(end)+1;
	options = {
		'start-time', startTime;
		'end-time', endTime;
		'left-border', 'reduce';
		'right-border', 'reduce'
	};
	[newTime, newSamples] = TimeSeriesUtil.respan(oldTime, oldSamples, options);
	
	testplot(testCount, oldTime, oldSamples, newTime, newSamples);

	assert(length(newTime)==length(newSamples));
	assert(endTime>=newTime(end));
	assert(newTime(1)>=startTime);
end




%% Test 4
% Tests if the 'fixed' border option is working correctly
for i = 1:(4*testSwitch(4))
	testCount = testCount+1;
	input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), sprintf('load%d.xlsx', i)));
	oldTime = input(:, 1);
	oldSamples = input(:, 2);

	startTime = oldTime(2)-2.5;
	endTime = oldTime(end-1)+2.5;
	options = {
		'start-time', startTime;
		'end-time', endTime;
		'left-border', 'fixed';
		'right-border', 'fixed'
	};

	[newTime, newSamples] = TimeSeriesUtil.respan(oldTime, oldSamples, options);
	
	testplot(testCount, oldTime, oldSamples, newTime, newSamples);

	assert(length(newTime)==length(newSamples));
	assert(endTime==newTime(end));
	assert(newTime(1)==startTime);
end




%% Test 5
% Tests if the 'gap' option is working correctly
for i = 1:(5*testSwitch(5))
	testCount = testCount+1;
	if i==5
		oldTime = 0:15;
		oldSamples = oldTime;
	else
		input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), sprintf('load%d.xlsx', i)));
		oldTime = input(:, 1);
		oldSamples = input(:, 2);
	end
	
	gap = pi;
	options = {
		'end-time', 2*oldTime(end)+gap-oldTime(1);
		'gap', gap
	};
	[newTime, newSamples] = TimeSeriesUtil.respan(oldTime, oldSamples, options);

	testplot(testCount, oldTime, oldSamples, newTime, newSamples);

	goal = [oldTime(:); gap+(oldTime(end)-oldTime(1))+oldTime(:)];
% 	disp('       GOAL        ACHIEVED    ')
% 	disp([goal(:), newTime(:)]);
	
	assert(all(newTime(:)==goal));
	assert(length(newTime)==length(newSamples));
end




%% Test 6
% Tests weird values on the options (visual assertion)
for i = 1:(5*testSwitch(6))
	testCount = testCount+1;
	if i==5
		oldTime = [0 0.1 pi 4 17 21 33.3 100/3 479];
		oldSamples = oldTime;
	else
		input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), sprintf('load%d.xlsx', i)));
		oldTime = input(:, 1);
		oldSamples = input(:, 2);
	end
	
	gap = rand()*357;
	options = {
		'start-time', 33.32;
		'end-time', log(pi)*1000;
		'gap', gap;
		'left-border', 'enlarge';
		'right-border', 'fixed';
		'use-row', true;
	};
	[newTime, newSamples] = TimeSeriesUtil.respan(oldTime, oldSamples, options);

	testplot(testCount, oldTime, oldSamples, newTime, newSamples);
	
	assert(length(newTime)==length(newSamples));
end



%% auxiliary functions
function testplot(test, oldTime, oldSamples, newTime, newSamples)
	figure(test);
	stairs(oldTime, oldSamples, '-*', 'LineWidth', 2);
	hold on;
	stairs(newTime, newSamples, '-*');
	hold off;
	legend({'original', 'respanned'})
end