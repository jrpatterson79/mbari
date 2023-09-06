clear; close all; clc

addpath(genpath('/Users/jpatt/My Drive/projects/func_lib/'))

%% MOOSE Results
file_dir = '/Users/jpatt/moose_projects/mbari/out_files/';
file_prefix = 'mbari_depth_pp_';
num_files = 482;

% Vector postprocessor results to generate porepressure matrix (num_z x
% num_t)
porepressure = zeros(300,num_files-1);
for i = 2:num_files
    if i <= 10
        file_name = [file_prefix '000' num2str(i-1) '.csv'];
        data = readtable([file_dir file_name]);
        porepressure(:,i-1) = data.pp; 
    elseif i > 100
        file_name = [file_prefix '0' num2str(i-1) '.csv'];
        data = readtable([file_dir file_name]);
        porepressure(:,i-1) = data.pp;
    else
        file_name = [file_prefix '00' num2str(i-1) '.csv'];
        data = readtable([file_dir file_name]);
        porepressure(:,i-1) = data.pp; 
    end
end

res = readtable([file_dir 'mbari.csv']); 
time = res.time(2:end);
trim = find(time >= 0); % Finding steady-periodic portion of signal
% z = abs(data.x);
% z = abs(data.y); % Depth vector
z = abs(data.z);

%% Wang Uniaxial Periodic Load on Half-Space (MBARI Parameters)
% Fluid Properties
mu = 1.26e-3;
Kf = 2e9;

% Seafloor Sediment Elastic Properties
Kd = 4.4e8;
G = 6.5e8;
biot = 0.6;
eta = 0.5;

% Derived Elastic Properties
M_inv = (eta/Kf) + (((1-biot)*(biot-eta))/Kd);
M = 1/M_inv;
Ku = Kd + (biot^2 * M);
nu = ((3*Kd)-(2*G))/(2*((3*Kd)+G));
nu_u = ((3*Ku)-(2*G))/(2*((3*Ku)+G));
B = (3*(nu_u-nu)) / (biot * (1-(2*nu)) * (1+nu_u));
gamma = (B*(1+nu_u))/(3*(1-nu_u));

% Rock Hydraulic Properties
k = 1.8e-10;
c = k/(mu*M_inv);

% Periodic Forcings
P1 = 44739.2;
om_1 = (2*pi)/P1;
real_1 = 3.6010e3;
imag_1 = -462.1223;
amp_1 = sqrt(real_1^2 + imag_1^2);
arg_1 = (2*c)/om_1;
dis_dep_1 = sqrt(arg_1);

P2 = 91048.6;
om_2 = (2*pi)/P2;
real_2 = -1.3816e3;
imag_2 = -3.2686e3;
amp_2 = sqrt(real_2^2 + imag_2^2);
arg_2 = (2*c) / om_2;
dis_dep_2 = sqrt(arg_2);

for j = 1 : numel(z)
    [~, moose_phasor(j,:)] = periodic_LS_fit(time(trim), porepressure(j,trim)'-mean(porepressure(j,trim)), P1);
end

dim_depth = sqrt(1/arg_2).*z; % Dimensionless depth
phasor_1 = (gamma*amp_1) + ((1-gamma).*amp_1.*exp(-z.*sqrt(1/arg_1)).*exp(-1j.*z.*sqrt(1/arg_1)));
phasor_2 = (gamma*amp_2) + ((1-gamma).*amp_2.*exp(-z.*sqrt(1/arg_2)).*exp(-1j.*z.*sqrt(1/arg_2)));

figure
clf
subplot(1,2,1)
ax = gca;
plot(abs(moose_phasor)./amp_1, z, '.', 'Color', [0.7592 0 0],...
    'MarkerSize', 12)
hold on
plot(abs(phasor_1)./amp_1, z, 'LineWidth', 2, 'Color', [0 0.4470 0.7410])
% ax.XTick = [0:0.2:1];
% xlim([0 1])
ax.YDir = 'reverse';
xlabel('Normalized Amplitude')
ylabel('Depth (m)')
ax.FontSize = 30;

subplot(1,2,2)
ax = gca;
plot(angle(moose_phasor), z, '.', 'Color', [0.7592 0 0],...
    'MarkerSize', 12)
hold on
plot(angle(phasor_1), z, 'LineWidth', 2, 'Color', [0 0.4470 0.7410])
ax.XTick = [-pi:pi/2:pi];
ax.XTickLabel = {'-\pi', '-\pi/2', 0, '\pi/2', '\pi'};
ax.YDir = 'reverse';
xlim([-pi pi])
xlabel('Phase Angle')
ylabel('Dimensionless Depth')
ax.FontSize = 30;
legend('MOOSE', 'Wang')
set(gcf, 'Position', [100 100 1440/1.1 1440])



%% Wang Periodic Uniaxial Load (MOOSE Atmoshperic Model)
% % Fluid Properties
% mu = 1e-3; % Fluid viscosity
% Kf = 2e9; % Fluid bulk modulus
% 
% %% Prescribed Poroelastic Constants
% Kd = 10e9; % Drained bulk modulus
% nu = 0.25; % Drained Poisson ratio
% biot = 0.6; % Biot coefficent
% eta = 0.1; % Porosity
% 
% %% Derived Poroelastic Constants
% G = (3*Kd) * ((1-(2*nu))/(2+(2*nu))); % Shear Modulus
% M_inv = (eta/Kf) + (((1-biot)*(biot-eta))/Kd); 
% M = 1/M_inv; % Biot Modulus
% Ku = Kd + (biot^2 * M); % Undrained bulk modulus
% nu_u = ((3*Ku)-(2*G))/(2*((3*Ku)+G)); % Undrained Poisson ratio
% B = (3*(nu_u-nu)) / (biot * (1-(2*nu)) * (1+nu_u)); % Skempton coefficent
% gamma = (B*(1+nu_u))/(3*(1-nu_u)); % Loading (barometric) efficiency
% 
% %% Rock Hydraulic Properties
% k = 1e-14; % Rock permeability 
% c = k / (mu*M_inv); % Hydraulic diffusivity
% 
% %% MOOSE Results
% file_dir = '/Users/jpatt/moose_projects/mbari/out_files/';
% file_prefix = 'mbari_depth_pp_';
% num_files = 242;
% 
% porepressure = zeros(300,num_files-1);
% for i = 2:num_files
%     if i <= 10
%         file_name = [file_prefix '000' num2str(i-1) '.csv'];
%         data = readtable([file_dir file_name]);
%         porepressure(:,i-1) = data.pp; 
%     elseif i > 100
%         file_name = [file_prefix '0' num2str(i-1) '.csv'];
%         data = readtable([file_dir file_name]);
%         porepressure(:,i-1) = data.pp;
%     else
%         file_name = [file_prefix '00' num2str(i-1) '.csv'];
%         data = readtable([file_dir file_name]);
%         porepressure(:,i-1) = data.pp; 
%     end
% end
% time = [0:3600:864000]';

%% Calculate Amplitudes
P = 86400; % Atmospheric forcing period
omega = (2*pi) / P;
arg_1 = (2*c) / omega;

atm_tide = 5000 * sin(2*pi*(time./3600./24)); % Atmospheric forcing signal

[~, atm_tide_phasor] = periodic_LS_fit(time, atm_tide, P); % Atmospheric tide amplitude
amp_1 = abs(atm_tide_phasor);
atm_tide = real(atm_tide_phasor .* exp(1j * omega .* time));

% % z = abs(data.x);
% z = abs(data.y);
% % z = abs(data.z);
% dim_depth = sqrt(1/arg_1).*z;
% trim = find(time >= 0);
% for j = 1 : numel(z)
%     [~, moose_phasor(j,:)] = periodic_LS_fit(time(trim), porepressure(j,trim)'-mean(porepressure(j,trim)), P);
% end
% 
% phasor_1 = (gamma*amp_1) + ((1-gamma).*amp_1.*exp(-z.*sqrt(1/arg_1)).*exp(-1j.*z.*sqrt(1/arg_1)));
% % phasor_2 = (gamma*amp_2) + ((1-gamma)*amp_2*exp(-z*sqrt(1/arg_2))*exp(-1j*z*sqrt(1/arg_2)));
% atm_tide_mod = real(phasor_1(end) .* exp(1j.*omega.*time));
% 
% figure
% clf
% subplot(1,2,1)
% ax = gca;
% plot(abs(moose_phasor)./(1000*10), z, '.', 'Color', [0.7592 0 0],...
%     'MarkerSize', 12)
% hold on
% plot(abs(phasor_1)./(1000*10), z, 'LineWidth', 2, 'Color', [0 0.4470 0.7410])
% % ax.XTick = [0:0.2:1];
% % xlim([0 1])
% ax.YDir = 'reverse';
% xlabel('Normalized Amplitude')
% ylabel('Dimensionless Depth')
% ax.FontSize = 30;
% legend('Wang', 'MOOSE')
% 
% subplot(1,2,2)
% ax = gca;
% plot(angle(moose_phasor), z, '.', 'Color', [0.7592 0 0],...
%     'MarkerSize', 12)
% hold on
% plot(angle(phasor_1), z, 'LineWidth', 2, 'Color', [0 0.4470 0.7410])
% ax.XTick = [-pi:pi/2:pi];
% ax.XTickLabel = {'-\pi', '-\pi/2', 0, '\pi/2', '\pi'};
% ax.YDir = 'reverse';
% xlim([-pi pi])
% xlabel('Phase Angle')
% ylabel('Dimensionless Depth')
% ax.FontSize = 30;
% set(gcf, 'Position', [100 100 1440/1.1 1440])

