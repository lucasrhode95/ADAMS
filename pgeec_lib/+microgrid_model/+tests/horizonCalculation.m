clear;
clc;

mg = microgrid_model.Microgrid();
cc = microgrid_model.CentralController(mg, false);
cc.relativeErrorTolerance = 0.5/100;
cc.developmentMode(true);
cc.warningsOn(true);

battery1 = microgrid_model.BatteryHan();
battery1.quantity = 3;
% battery1.linearizationPointsDod = 15;
% battery1.linearizationPointsSoc = 15;
% battery1.socIni = 0.3;
battery1.setActive(true);

load1 = microgrid_model.LoadConstant();
load2 = microgrid_model.LoadConstant();

load1.importDemandProfile('C:\Users\Lucas Rhode\Desktop\load profiles\load1.xlsx');
load2.importDemandProfile('C:\Users\Lucas Rhode\Desktop\load profiles\load3.xlsx');

load2.setActive(true);

mg.addMGElement(load1);
mg.addMGElement(load2);
mg.addMGElement(battery1);

% % load2.test([5 10 15 20 25 30 60:60:2880])
% load2.test([5 10 15 20 25 30 60:60:2880]);
% figure(2);
% plot([5 60:60:1440], load2.getBaseDemand0(), '*')
% hold on;
% plot([5 10 15 20 25 30 60:60:2880], load2.getBaseDemand1())
% hold off;
cc.t0 = 5*60;
cc.intendedHorizon = 36*60;

cc.run()

mg.getOperationalCost()

t = cc.getTime();

figure(1);
plot(t, battery1.getStateOfCharge());

figure(2);
plot(t, -load1.getPowerOutput());
hold on;
plot(t, -load2.getPowerOutput());
hold off;