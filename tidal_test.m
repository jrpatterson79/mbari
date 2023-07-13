% Clean environment
clear; close all; clc

addpath(genpath('/Users/jpatt/My Drive/projects/func_lib/'))

tidal_file = 'mbari_tidal.csv';
baro_file = '2018-03.csv';

% Barometric pressure data
mbar_to_Pa = 1e2;
buoy_data = readtable(baro_file);
baro_Pa = buoy_data.baro * mbar_to_Pa;

%Tidal Data
buoy_depth = 1693;
rho_water = 1035.16;
g = 9.81;
tidal_data = readtable(tidal_file);
water_depth = tidal_data.water_level + buoy_depth;
water_press = water_depth * rho_water * g;

tot_press = water_press + baro_Pa(1:numel(water_press));

figure
clf
ax = gca;
plot(datetime(tidal_data.time, 'Format', 'MM-dd-yyyy HH:mm:ss'), tot_press, 'b.')

figure
clf
ax = gca;
plot(test_time, obs_detrend(:,1), 'k-', 'LineWidth',3)% 'MarkerSize', 10)
hold on
plot(test_time,  obs_recon, 'r-', 'LineWidth', 3)
axis([0 test_time(end) -6e-2 6e-2])
xlabel('Time (s)')
ylabel('Head Change (m)')
ax.FontSize = 20;
leg = legend('Observed Signal', 'Reconstructed Signal');
leg.FontSize = 18;
set(gcf, 'Position', [100 100 1900 600])
%     print([agu_dir 'obs_sig'], '-dpng', '-r300')

coeffs = {Q_coeffs_keep fft_coeffs_keep obs_coeffs_keep};
signal = {Q time_series_detrend obs_detrend};

figure
clf
subplot(2, 3, [1 2])
ax = gca;
plot(test_time, time_series_detrend, 'r.')
hold on
plot(test_time, time_series_recon, 'k.')
legend('Measured', 'Reconstructed')
xlabel('Time (s)')
ylabel('Head (m)')
ax.FontSize = 18;

subplot(2, 3, [4 5])
ax = gca;
plot(P, fft_power, '.')
hold on
plot(locs_pks_good, pkspow_good, 'k^', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'LineWidth', 2)
axis([0 90 -Inf Inf])
xlabel('Period (s)')
ylabel('Power')
ax.FontSize = 18;

subplot(2, 3, [3 6])
ax =gca;
plot(time_series_detrend, time_series_recon, '.', 'MarkerSize', 12)
hold on
plot([min(time_series_detrend) max(time_series_detrend)], [min(time_series_detrend) max(time_series_detrend)], 'k-', 'LineWidth', 2)
xlabel('Detrended Head (m)')
ylabel('FFT Reconstructed Head (m)')
axis([min(time_series_detrend) max(time_series_detrend) min(time_series_detrend) max(time_series_detrend)])
ax.FontSize = 18;

set(gcf, 'Position', [0 0 1920 1080])
fig_filename = ['Test_' num2str(i) '_'];
fig_file = [print_dir fig_filename];
print(fig_file, '-dpng')