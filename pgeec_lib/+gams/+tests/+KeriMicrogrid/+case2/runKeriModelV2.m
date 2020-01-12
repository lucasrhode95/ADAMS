t        = 1:(t(end)*daysToSimulate);
net_load = repmat(net_load, 1, daysToSimulate);
dt       = repmat(dt, 1, daysToSimulate);
% map_th   = repmat(map_th, daysToSimulate, 1);

k        = (1:socCount);
L        = (1:dodCount);
m        = (1:(socCount+dodCount-1));
if rem(dodCount, 2) == 0
	warning('Your DOD discretization data doesn''t include a DOD=0 level. This could be troublesome in some cases. Select an odd dodCount to fix that.')
end
socData  = linspace(soc_min, soc_max, socCount);
dodData  = linspace(soc_min-soc_max, soc_max-soc_min, dodCount);

modelV2 = GAMSmodel('../model_battery_wearV2.gms', false);
modelV2.KEEP_FILES = false;
modelV2.WARNINGS = false;

modelV2.addSet('t', t);
modelV2.addSet('k1', k);
modelV2.addSet('L1', L);
modelV2.addSet('m1', m);
modelV2.addSet('thora', thora);
modelV2.addSet('map_th', map_th, 't', 'thora');

modelV2.addParameter('dt', dt, 't');
modelV2.addParameter('net_load', net_load, 't');
modelV2.addParameter('socData1', socData, 'k1');
modelV2.addParameter('dodData1', dodData, 'L1');
modelV2.addParameter('demandas_contratadas', demandas_contratadas, 'thora');

modelV2.addScalar('batSize1', batSize);
modelV2.addScalar('batPrice1', batPrice);
modelV2.addScalar('soc_max1', soc_max);
modelV2.addScalar('soc_min1', soc_min);
modelV2.addScalar('soc_ini1', soc_ini);
modelV2.addScalar('soc_fin1', soc_fin);
modelV2.addScalar('psmax1', psmax);
modelV2.addScalar('psmin1', psmin);
modelV2.addScalar('nf1', nf);
modelV2.addScalar('a01', a0);
modelV2.addScalar('a11', a1);
modelV2.addScalar('disEffic1', disEffic);
modelV2.addScalar('chaEffic1', chaEffic);

modelV2.addScalar('DG_startup_cost', DG_startup_cost);
modelV2.addScalar('diesel_cost', diesel_cost);
modelV2.addScalar('Pi_nominal', Pi_nominal);
modelV2.addScalar('a', a);
modelV2.addScalar('b', b);
modelV2.addScalar('c', c);

modelV2.clearBuffer('thora');
fprintf('Elapsed time: %4.2f seconds.\n', modelV2.run());