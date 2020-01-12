clear;
clc;
% close all;

%% test 1

input = util.FilesUtil.readExcel([util.FilesUtil.getParentDir() '\load1.xlsx']);
oldTime = input(:, 1);
oldSamples = input(:, 2);

% startTime = -1430;
% endTime   = 2880;

startTime = 500;
endTime   = 3000;

truncation = 'default';
% truncation = 'truncate';
% truncation = 'snap-right';
% truncation = 'snap-left';

% borderHandling = 'outside';
borderHandling = 'outside';

[newSamples, newTime] = util.TimeSeriesUtil.respan(oldTime, oldSamples, startTime, endTime, truncation, borderHandling);

figure(1);
plot(oldTime, oldSamples, '.');
hold on;
plot(newTime, newSamples, 'LineWidth', 1);
legend('original', 'respanned');
hold off;
title('test1');

%% test 2

input = util.FilesUtil.readExcel([util.FilesUtil.getParentDir() '\load2.xlsx']);
oldTime = input(:, 1);
oldSamples = input(:, 2);

% startTime = -1430;
% endTime   = 2880;

startTime = 0;
endTime   = 60*120;

truncation = 'default';
% truncation = 'truncate';
% truncation = 'snap-right';
% truncation = 'snap-left';

% borderHandling = 'outside';
borderHandling = 'outside';

[newSamples, newTime] = util.TimeSeriesUtil.respan(oldTime, oldSamples, startTime, endTime, truncation, borderHandling);

% [newSamples] = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward1', 'zeros');

figure(2);
plot(oldTime, oldSamples, '*');
hold on;
stairs(newTime, newSamples);
legend('original', 'respanned');
hold off;
title('test2');

%% test 3
input = util.FilesUtil.readExcel([util.FilesUtil.getParentDir() '\load3.xlsx']);
oldTime = input(:, 1);
oldSamples = input(:, 2);

% startTime = -1430;
% endTime   = 2880;

startTime = -3;
endTime   = 2880;

truncation = 'default';
% truncation = 'truncate';
% truncation = 'snap-right';
% truncation = 'snap-left';

% borderHandling = 'outside';
borderHandling = 'outside';

[newSamples, newTime] = util.TimeSeriesUtil.respan(oldTime, oldSamples, startTime, endTime, truncation, borderHandling);

figure(3);
stairs(oldTime, oldSamples, '*');
hold on;
stairs(newTime, newSamples);
legend('original', 'respanned');
hold off;
title('test3');

%% test 4
input = util.FilesUtil.readExcel([util.FilesUtil.getParentDir() '\load3.xlsx']);
oldTime = input(:, 1);
oldSamples = input(:, 2);

% startTime = -1430;
% endTime   = 2880;

startTime = 1800;
endTime   = 5000;

truncation = 'default';
% truncation = 'truncate';
% truncation = 'snap-right';
% truncation = 'snap-left';

% borderHandling = 'outside';
borderHandling = 'outside';

[newSamples, newTime] = util.TimeSeriesUtil.respan(oldTime, oldSamples, startTime, endTime, truncation, borderHandling);

figure(4);
stairs(oldTime, oldSamples, '-.');
hold on;
stairs(newTime, newSamples);
legend('original', 'respanned');
hold off;
title('test3');