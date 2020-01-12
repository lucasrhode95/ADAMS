% this serves as a simple validator of the GAMS API as well as a measure stick for case 1.

clear;
clc;
addpath('../../Framework/gamsTool');

model = GAMSmodel('../model_case0.gms', false);
model.run();

fprintf('Total MG operational cost: R$ %4.4f\n', model.read('z'));