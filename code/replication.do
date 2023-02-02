cap log close
set more off
clear all

*set project directory
global ddir "/Users/gelkouh/Library/CloudStorage/OneDrive-Personal/Documents/School/UChicago/Year 4/ECON 21110/FINAL PROJECT/"

*output file
log using "${ddir}econ-21110-winter-2023/code/regression_analysis.log", replace

********************************************************************************************************
* Replication of Burke and Liao (2015)           
********************************************************************************************************

use "${ddir}data/ChinaCoalElasticity.dta", clear
desc


log close
