
results_dir = '/Users/jpatt/moose_projects/mbari/out_files/';
hyd_file = 'mbari_hydro.csv';
hm_file = 'mbari.csv';

hydro_results = readtable([results_dir hyd_file]);
time = hydro_results.time(2:end);
hyd_pressure = hydro_results.p100(2:end);

hm_results = readtable([results_dir hm_file]);
hm_pressure = hm_results.p100(2:end);

figure 
clf
subplot(1,2,1)
ax = gca;
plot(time./3600, hyd_pressure.*1e-6, 'LineWidth', 2)
xlabel('Time (hrs)')
ylabel('Pressure (MPa)')
title('Hydro Only')
ax.FontSize = 30;

subplot(1,2,2)
ax = gca;
plot(time./3600, hm_pressure.*1e-6, 'LineWidth', 2)
xlabel('Time (hrs)')
ylabel('Pressure (MPa)')
title('Poroelastic')
ax.FontSize = 30;
set(gcf, 'Position', [100 100 2025 2025/2.6667])
