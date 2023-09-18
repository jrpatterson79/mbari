clear; close all; clc
P = 31536000;
c = 1;
amp = 5;
gamma = 0.3;
omega = (2*pi) / P;
arg = (2*c) / omega;
z = [0:100:50000]';
phasor = (gamma*amp) + ((1-gamma).* amp .* exp(-z .* sqrt(1/arg))) .* exp(-1j .* z .* sqrt(1/arg));

dim_dep = z .* sqrt(1/arg);

figure
clf
ax = gca;
plot(abs(phasor)./amp, dim_dep)
grid on
xlim([0 1])
ylim([0 9])
ax.YDir = 'reverse';

figure
clf 
ax = gca;
plot(angle(phasor), dim_dep)
grid on
xlim([-pi pi])
ax.YDir = 'reverse';
set(gcf, 'Position', [100 100 1000/2.5 1000])