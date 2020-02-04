clear;
close all;
clc;
import util.FilesUtil
import util.TimeSeriesUtil
% 
% input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), 'load1.xlsx'));
% oldTime = input(:, 1);
% oldSamples = input(:, 2);
% 
% % all this work just to get a time array
% newTime = cumsum([
% 		   (1:10)'
% 		   5*ones(6, 1);
%            30;
%            60*ones(10, 1);
% 		   30; 30; 15; (1:10)'; 5; 5; 5;  5; 5; 5; 5; 5; 5; 5; 5; 5; 5; 5;
% 		   60*ones(9, 1)]);
% 
% %% case 1.1 - standard forward resampling, more robust and has good precision for up and downsampling
% % newTime = -300:6:1700;
% 
% figure();
% subplot(2, 1, 1);
% stairs(oldTime, oldSamples);
% hold on;
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime);
% stairs(newTime, newDemand);
% hold off;
% title('Case 1.1: wacky varying sampling (forward1)')
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime).*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% %% case 1.2 - backward mode is useful if you want to obtain statistics at the end each interval
% % newTime = -300:6:1700;
% 
% subplot(2, 1, 2);
% stairs(oldTime, oldSamples);
% hold on;
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'backward');
% stairs(newTime, newDemand);
% hold off;
% title('Case 1.2: same as 1.1 but w/ backward mode')
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime).*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% %% case 2.1 - forward (alias for forward1) is good for general resampling as already said
% newTime = [-150:25:0 5 10 15 20 25 30 60:60:1660]';
% 	   
% figure();
% subplot(2, 1, 1);
% stairs(oldTime, oldSamples);
% hold on;
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward1');
% stairs(newTime, newDemand);
% hold off;
% 
% % ideally, they should equal
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime).*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% title('Case 2.1: equal sampling at the start and downsampling after (forward1)')
% 
% %% case 2.2 - same as case 2.1 but with backward mode
% 	   
% % figure();
% subplot(2, 1, 2);
% stairs(oldTime, oldSamples);
% hold on;
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'backward');
% stairs(newTime, newDemand);
% hold off;
% 
% % ideally, they should equal
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime).*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% title('Case 2.1: equal sampling first and downsampling after (backward)')
% 
% %% case 3.1 - forward 2 can have problems when the new sampling rate is not a multiple of the original
% newTime = (0:6:1700)'; % original timestep = 5, this' = 6, you're gonna notice some sharp peaks
% 
% figure();
% subplot(3, 1, 1);
% stairs(oldTime, oldSamples);
% hold on;
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward2');
% stairs(newTime, newDemand);
% hold off;
% title('Case 3.1: new sampling rate (6) not multiple of the original''s (5) (forward2)')
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime).*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% %% case 3.2 - same as 5 but with forward 1
% 
% % figure();
% subplot(3, 1, 2);
% stairs(oldTime, oldSamples);
% hold on;
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward1');
% stairs(newTime, newDemand);
% hold off;
% title('Case 3.2: new sampling rate (6) not multiple of the original''s (5) (forward1)')
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime).*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% %% case 3.3 - same as 5 but with backward
% 
% % figure();
% subplot(3, 1, 3);
% stairs(oldTime, oldSamples);
% hold on;
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'backward');
% stairs(newTime, newDemand);
% hold off;
% title('Case 3.3: new sampling rate (6) not multiple of the original''s (5) (backward)')
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime).*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% %% Case 4.1 supersampling forward1 - when supersampling there's no difference between forward1 or 2
% 
% newTime = 167:5:1237;
% % all this work just to get a time array
% oldTime = [5 10 15 20 25 30 60:60:1440]';
% 
% oldSamples = [6.56; 6.56; 6.27; 6.27; 6.44; 6.44; 6.57; 6.31; 9.81; 15.24; 19.94; 20.94; 21.6; 23.74; 26.08; 25.68; 26.16; 28.7; 28.13; 28.73; 19.83; 19.77; 19.97 ;17.17; 17.44;  24.17; 22.92; 21.24;12.42; 8.66];
% 
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward1');
% 
% figure();
% subplot(3, 1, 1);
% stairs(oldTime, oldSamples, '*');
% hold on;
% stairs(newTime, newDemand);
% hold off;
% 
% title('Case 4.1 supersampling  (forward1)');
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime').*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% %% Case 4.2 supersampling forward2 - when supersampling there's no difference between forward1 or 2
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward2');
% 
% subplot(3, 1, 2);
% stairs(oldTime, oldSamples, '*');
% hold on;
% stairs(newTime, newDemand);
% hold off;
% 
% title('Case 4.2 supersampling  (forward2)');
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime').*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% 
% %% Case 4.3 supersampling backward - when supersampling and using backward, samples are going to be delayed
% newDemand = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'backward');
% 
% subplot(3, 1, 3);
% stairs(oldTime, oldSamples, '*');
% hold on;
% stairs(newTime, newDemand);
% hold off;
% 
% title('Case 4.3 supersampling  (backward)');
% 
% disp('----');
% a1 = sum(diff(oldTime).*(oldSamples(1:end-1)));
% a2 = sum(diff(newTime').*(newDemand(1:end-1)));
% fprintf('Original area = %0.4f\nNew area = %0.4f\n', a1, a2);
% fprintf('Difference = %0.4f\n', a1-a2);
% 
% 
% %% Case 5.1 transform forth and back to original supersampling (backward)
% 
% oldTime = cumsum([5*ones(6, 1); 30; 60*ones(23, 1)]);
% oldSamples = [6.56; 6.56; 6.27; 6.27; 6.44; 6.44; 6.57; 6.31; 9.81; 15.24; 19.94; 20.94; 21.6; 23.74; 26.08; 25.68; 26.16; 28.7; 28.13; 28.73; 19.83; 19.77; 19.97 ;17.17; 17.44;  24.17; 22.92; 21.24;12.42; 8.66];
% 
% newTime = (5:5:1440)';
% newSamples = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'backward');
% 
% figure();
% 
% subplot(2, 1, 1);
% stairs(oldTime, oldSamples, '*');
% hold on;
% stairs(newTime, newSamples);
% 
% title('Case 5.1 - reversability: supersampling and downsampling back to original');
% 
% oldTime = newTime;
% oldSamples = newSamples;
% 
% newTime = cumsum([5*ones(6, 1); 30; 60*ones(23, 1)]);
% newSamples = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward');
% 
% stairs(newTime, newSamples, 'o');
% hold off;
% 
% legend('Original', 'Supersampled (backward)', 'Back to original (forward1)');
% 
% %% Case 5.2 transform forth and back to original supersampling (forward1)
% 
% oldTime = cumsum([5*ones(6, 1); 30; 60*ones(23, 1)]);
% oldSamples = [6.56; 6.56; 6.27; 6.27; 6.44; 6.44; 6.57; 6.31; 9.81; 15.24; 19.94; 20.94; 21.6; 23.74; 26.08; 25.68; 26.16; 28.7; 28.13; 28.73; 19.83; 19.77; 19.97 ;17.17; 17.44;  24.17; 22.92; 21.24;12.42; 8.66];
% 
% newTime = (5:5:1440)';
% newSamples = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime);
% 
% subplot(2, 1, 2);
% stairs(oldTime, oldSamples, '*');
% hold on;
% stairs(newTime, newSamples);
% 
% title('Case 5.2 - reversability: supersampling and downsampling back to original');
% 
% oldTime = newTime;
% oldSamples = newSamples;
% 
% newTime = cumsum([5*ones(6, 1); 30; 60*ones(22, 1)]);
% newSamples = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime);
% 
% stairs(newTime, newSamples, 'o');
% hold off;
% 
% legend('Original', 'Supersampled (forward1)', 'Back to original (forward1)');
% 
% %% Case 6.1 irrational upsampling
% load1 = microgrid_model.LoadConstant();
% load1.importDemandProfile([util.FilesUtil.getParentDir() '\load1.xlsx']);
% oldSamples = load1.getDemandProfile();
% oldTime = (5:5:1440)';
% 
% % input = util.FilesUtil.readExcel([util.FilesUtil.getParentDir() '\load1.xlsx']);
% 
% % oldTime = input(:, 1);
% % oldSamples = input(:, 2);
% 
% newTime = cumsum([5*ones(6, 1); 30; 1240/21*ones(21, 1)]);
% newSamples = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward1');
% 
% figure();
% subplot(3, 1, 1);
% stairs(oldTime, oldSamples);
% hold on;
% stairs(newTime, newSamples);
% title('Case 6.1 - irrational sampling');
% legend('Original', 'Resampled (forward1)');
% 
% %% Case 6.2 irrational upsampling
% % load1 = microgrid_model.LoadConstant();
% % load1.importDemandProfile('C:\Users\Lucas Rhode\Desktop\load profiles\load1.xlsx');
% % oldSamples = load1.getDemandProfile();
% % oldTime = (5:5:1440)';
% 
% % input = util.FilesUtil.readExcel([util.FilesUtil.getParentDir() '\load1.xlsx']);
% 
% % oldTime = input(:, 1);
% % oldSamples = input(:, 2);
% 
% % newTime = cumsum([5*ones(6, 1); 30; 1240/21*ones(21, 1)]);
% newSamples = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward2');
% 
% % figure();
% subplot(3, 1, 2);
% stairs(oldTime, oldSamples);
% hold on;
% stairs(newTime, newSamples);
% title('Case 6.2 - irrational sampling');
% legend('Original', 'Resampled (forward)');
% 
% %% Case 6.3 irrational upsampling
% % load1 = microgrid_model.LoadConstant();
% % load1.importDemandProfile('C:\Users\Lucas Rhode\Desktop\load profiles\load1.xlsx');
% % oldSamples = load1.getDemandProfile();
% % oldTime = (5:5:1440)';
% 
% % input = util.FilesUtil.readExcel([util.FilesUtil.getParentDir() '\load1.xlsx']);
% 
% % oldTime = input(:, 1);
% % oldSamples = input(:, 2);
% 
% % newTime = cumsum([5*ones(6, 1); 30; 1240/21*ones(21, 1)]);
% newSamples = util.TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'backward');
% 
% % figure();
% subplot(3, 1, 3);
% stairs(oldTime, oldSamples);
% hold on;
% stairs(newTime, newSamples);
% title('Case 6.3 - irrational sampling');
% legend('Original', 'Resampled (backward)');

%% Case 7.1 supersampling
input = FilesUtil.readExcel(fullfile(FilesUtil.getParentDir(), 'load4.xlsx'));
oldTime = input(:, 1);
oldSamples = input(:, 2);
stairs(oldTime, oldSamples);

newTime = cumsum([5*ones(6, 1); 30; 60*ones(23, 1)]);
newSamples = TimeSeriesUtil.resample(oldTime, oldSamples, newTime, 'forward1');

hold on;
stairs(newTime, newSamples, '*');
hold off;