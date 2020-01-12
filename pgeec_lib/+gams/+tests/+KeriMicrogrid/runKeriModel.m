import gams.GAMSModel

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

model = GAMSModel('+gams/+tests/+KeriMicrogrid/model_battery_wear.gms', false);
model.KEEP_FILES = true;
model.WARNINGS = true;

model.addSet('t', t);
model.addSet('k', k);
model.addSet('L', L);
model.addSet('m', m);
model.addSet('thora', thora);
model.addSet('map_th', map_th, 't', 'thora');

model.addParameter('dt', dt, 't');
model.addParameter('net_load', net_load, 't');
model.addParameter('socData', socData, 'k');
model.addParameter('dodData', dodData, 'L');
model.addParameter('demandas_contratadas', demandas_contratadas, 'thora');

model.addScalar('batCount', batCount);
model.addScalar('batSize', batSize);
model.addScalar('batPrice', batPrice);
model.addScalar('soc_max', soc_max);
model.addScalar('soc_min', soc_min);
model.addScalar('soc_ini', soc_ini);
model.addScalar('soc_fin', soc_fin);
model.addScalar('psmax', psmax);
model.addScalar('psmin', psmin);
model.addScalar('nf', nf);
model.addScalar('a0', a0);
model.addScalar('a1', a1);
model.addScalar('disEffic', disEffic);
model.addScalar('chaEffic', chaEffic);

model.addScalar('DG_startup_cost', DG_startup_cost);
model.addScalar('diesel_cost', diesel_cost);
model.addScalar('Pi_nominal', Pi_nominal);
model.addScalar('a', a);
model.addScalar('b', b);
model.addScalar('c', c);

model.clearBuffer('thora');
fprintf('Elapsed time: %4.2f seconds.\n', model.run());