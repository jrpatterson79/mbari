#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 12 19:42:51 2023

@author: jpatt
"""
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os

pwd = os.getcwd()
tidal_file = 'mbari_tidal.csv'
baro_file = '2018-03.csv'

# Barometric pressure data
mbar_to_Pa = 1e2
buoy_data = pd.read_csv(os.path.join(pwd, baro_file), index_col=0, parse_dates=True)
baro_Pa = buoy_data["baro"] * mbar_to_Pa
baro_Pa.dtypes

# Tidal Data
buoy_depth = 1693
rho_water = 1035.16
g = 9.81
tidal_data = pd.read_csv(os.path.join(pwd, tidal_file), index_col=0, parse_dates=True)
water_depth = tidal_data["water_level"] + buoy_depth
water_press = water_depth * rho_water * g
water_press.dtypes

tot_press = water_press + baro_Pa[0:len(water_press)-1]

tidal_data["water_press"].plot()
plt.show()

buoy_data["baro_Pa"].plot()
plt.show()