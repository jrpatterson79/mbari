import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os


# MOOSE Results
results_dir = '/Users/jpatt/moose_projects/mbari/out_files/'
results_file = 'mbari.csv'
moose_results = pd.read_csv(os.path.join(results_dir, results_file))
moose_pp = moose_results.p0[1:]
moose_detrend = moose_pp - np.mean(moose_pp)
moose_lvl = moose_pp / (1026 * 9.81)

# Wang Uniaxial Periodic Load on Half-Space
# Seafloor Sediment Elastic Properties
Kd = 4.4e8
G = 6.5e8
biot = 0.9
eta = 0.5
# Fluid Properties
mu = 1.26e-3
Kf = 2e9
# Derived Elastic Properties
M_inv = (eta/Kf) + (((1-biot)*(biot-eta))/Kd)
M = 1/M_inv
Ku = Kd + (biot**2 * M)
nu = ((3*Kd)-(2*G))/(2*((3*Kd)+G))
nu_u = ((3*Ku)-(2*G))/(2*((3*Ku)+G))
H = Kd / biot
B = (biot/Kf) * (((biot-(eta*(1-biot)))*Kf)+(eta*Kf))
gamma = (B*(1+nu_u))/(3*(1-nu_u))
S = ((1-nu_u)*(1-(2*nu)))/(M*(1-nu)*(1-(2*nu_u)))
k = 1.8e-10
c = k / (mu*S)
# Signal Properties
P1 = 44739.2 
om_1 = (2*np.pi)/P1
real_1 = 3.6010e3 
imag_1 = -462.1223
amp_1 = np.sqrt(real_1**2 + imag_1**2)
arg_1 = (2*c) / om_1
dis_dep_1 = np.sqrt(arg_1)

P2 = 91048.6
om_2 = (2*np.pi)/P2
real_2 = -1.3816e3
imag_2 = -3.2686e3
amp_2 = np.sqrt(real_2**2 + imag_2**2)
arg_2 = (2*c) / om_2
dis_dep_2 = np.sqrt(arg_2)

#Modeled Pressure Signal
z = 100
time = np.transpose(np.arange(0,325800, 1800))

phasor_1 = (gamma*amp_1) + ((1-gamma)*amp_1 * np.exp(-z*np.sqrt(1/arg_1))) * np.exp(-1j*z*np.sqrt(1/arg_1))
phasor_2 = (gamma*amp_2) + ((1-gamma)*amp_2 * np.exp(-z*np.sqrt(1/arg_2))) * np.exp(-1j*z*np.sqrt(1/arg_2))

wang_pp = (np.real(phasor_1) * np.cos(om_1*time)) - (np.imag(phasor_1) * np.sin(om_1*time))# + (np.real(phasor_2) * np.cos(om_2*time)) - (np.imag(phasor_2) * np.sin(om_2*time))#np.mean(moose_pp)
# wang_pp = pp_1 + pp_2 + np.mean(moose_pp)


rmse = np.sqrt(np.mean((wang_pp-moose_detrend)**2))
print('RMSE = %n', rmse)

fig, ax = plt.subplots()
plt.plot(moose_results.time[1:], moose_detrend, linewidth = 2, color = (0.7592, 0, 0), label = 'MOOSE')
plt.plot(time, wang_pp, marker = 'o', label = 'Wang')
# ax.set_ylim([-4000, 4000])
ax.legend()
plt.show()