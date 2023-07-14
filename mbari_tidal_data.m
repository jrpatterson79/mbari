% Clean environment
clear; close all; clc

%Specify directories
addpath(genpath('/Users/jpatt/My Drive/projects/func_lib/'))

% Barometric pressure data
baro_file = 'mbari_baro.csv';
mbar_to_Pa = 1e2;
buoy_data = readtable(baro_file);
baro_Pa = buoy_data.baro * mbar_to_Pa;

%Tidal Data
tidal_file = 'mbari_tidal.csv';
buoy_depth = 1693;
rho_water = 1035.16;
g = 9.81;
tidal_data = readtable(tidal_file);
water_depth = tidal_data.water_level + buoy_depth;
water_press = water_depth * rho_water * g;

% Resample data for FFT
dt = 3600;
tidal_time = (datenum(tidal_data.time) - datenum(tidal_data.time(1))) * 86400;
tidal_time_resamp = [datenum(tidal_time(1)) : dt : tidal_time(end)]';
water_press_resamp = interp1(tidal_time, water_press, tidal_time_resamp);

baro_time = (datenum(buoy_data.utc_time) - datenum(buoy_data.utc_time(1))) * 86400;
baro_time_resamp = [baro_time(1): dt: baro_time(end)]';
baro_Pa_resamp = interp1(baro_time, baro_Pa, baro_time_resamp);

tot_press = water_press_resamp + baro_Pa_resamp;
mean_press = mean(tot_press);

[fft_coeffs, tot_press_fft] = fft_fxn(tidal_time_resamp, tot_press);
tot_press_fft = tot_press_fft + mean_press;

figure
clf
% plot(tidal_time_resamp, tot_press, 'b-')
% hold on
plot(tidal_time_resamp, tot_press_fft, 'r-');

% figure
% clf
% ax = gca;
% plot(test_time, obs_detrend(:,1), 'k-', 'LineWidth',3)% 'MarkerSize', 10)
% hold on
% plot(test_time,  obs_recon, 'r-', 'LineWidth', 3)
% axis([0 test_time(end) -6e-2 6e-2])
% xlabel('Time (s)')
% ylabel('Head Change (m)')
% ax.FontSize = 20;
% leg = legend('Observed Signal', 'Reconstructed Signal');
% leg.FontSize = 18;
% set(gcf, 'Position', [100 100 1900 600])
% %     print([agu_dir 'obs_sig'], '-dpng', '-r300')

% figure
% clf
% subplot(2, 3, [1 2])
% ax = gca;
% plot(test_time, time_series_detrend, 'r.')
% hold on
% plot(test_time, time_series_recon, 'k.')
% legend('Measured', 'Reconstructed')
% xlabel('Time (s)')
% ylabel('Head (m)')
% ax.FontSize = 18;
% 
% subplot(2, 3, [4 5])
% ax = gca;
% plot(P, fft_power, '.')
% hold on
% plot(locs_pks_good, pkspow_good, 'k^', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'LineWidth', 2)
% axis([0 90 -Inf Inf])
% xlabel('Period (s)')
% ylabel('Power')
% ax.FontSize = 18;
% 
% subplot(2, 3, [3 6])
% ax =gca;
% plot(time_series_detrend, time_series_recon, '.', 'MarkerSize', 12)
% hold on
% plot([min(time_series_detrend) max(time_series_detrend)], [min(time_series_detrend) max(time_series_detrend)], 'k-', 'LineWidth', 2)
% xlabel('Detrended Head (m)')
% ylabel('FFT Reconstructed Head (m)')
% axis([min(time_series_detrend) max(time_series_detrend) min(time_series_detrend) max(time_series_detrend)])
% ax.FontSize = 18;
% 
% set(gcf, 'Position', [0 0 1920 1080])
% fig_filename = ['Test_' num2str(i) '_'];
% fig_file = [print_dir fig_filename];
% print(fig_file, '-dpng')