clear;
clc;

step1stHalfHour = 30/7;
step2ndHalfHour = 30;
stepDefault = 60;
intendedHorizon = 1300;
WARNINGS = true;

% remaining time, aside from the first hour that is fixed.
remainingTime = max(0, intendedHorizon - 60);

% number of points for the first half hour
count1stHH = floor(30/step1stHalfHour);

% number of points for the second half hour
count2ndHH = floor(30/step2ndHalfHour);

% number of points for the rest of the simulation
countRest  = floor(remainingTime/stepDefault);

if ((30/count1stHH) ~= step1stHalfHour) && WARNINGS
	warning('Rounding the first half hour step from %d to %d', step1stHalfHour, 30/count1stHH);
end
if ((30/count2ndHH) ~= step2ndHalfHour) && WARNINGS
	warning('Rounding the second half hour step from %d to %d', step2ndHalfHour, 30/count2ndHH);
end
if ((remainingTime/countRest) ~= stepDefault) && WARNINGS
	warning('Rounding the default time step from %d to %d', stepDefault, remainingTime/countRest);
end

% this rounds the steps to valid values.
step1stHalfHour = 30/count1stHH
step2ndHalfHour = 30/count2ndHH
stepDefault = remainingTime/countRest

% saves the result
dtArray = [(step1stHalfHour)*ones(count1stHH, 1);
				(step2ndHalfHour)*ones(count2ndHH, 1);
				(stepDefault)    *ones(countRest, 1)];

cumsum(dtArray)