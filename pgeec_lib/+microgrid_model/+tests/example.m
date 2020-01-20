%% init
import microgrid_model.*

clear;
clc;

%% config
debugMode = true;
keepFiles = false;
warningsOn = true;

batteryActive = true;
dieselGenActive = true;
loadActive = true;
solarPanelActive = false;
islandMode = false;

tolerance = 0;
t0 = 0;
horizon = 60*72;

%% program config
microgrid_model.MGElement.warningsOn(warningsOn);
microgrid_model.MGElement.developmentMode(debugMode);

%% MGCC
mgcc = CentralController();
mgcc.getMicrogrid().isIsland = islandMode;
mgcc.intendedHorizon = horizon;
mgcc.t0 = t0;
mgcc.relativeErrorTolerance = tolerance;

%% battery
battery = BatteryLinear();
battery.quantity = 2;
battery.socFinLo = 0.42;
% battery1.linearizationPointsDod = 15;
% battery1.linearizationPointsSoc = 15;
battery.setActive(batteryActive);

mgcc.addMGElement(battery);

%% diesel gen
dieselGen = DieselGeneratorQuadratic();
dieselGen.setActive(dieselGenActive);
dieselGen.linearizationPoints = 12;

mgcc.addMGElement(dieselGen);
%% solar panel
pv = SolarPanelConstant();
pv.importGenerationProfile('C:\Users\Lucas Rhode\Desktop\Simu TCC\load profiles\load3.xlsx');
pv.setActive(solarPanelActive);

mgcc.addMGElement(pv);
%% load
load = LoadSheddable();
load.importDemandProfile('C:\Users\Lucas Rhode\Desktop\Simu TCC\load profiles\load6.xlsx');
load.setActive(loadActive);

mgcc.addMGElement(load);

%% run
mgcc.run();

%% result printing
t = mgcc.getTime();

stairs(t, battery.getStateOfCharge);