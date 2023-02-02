cap log close
set more off
clear all

*set project directory
global cdir "/Users/gelkouh/Library/CloudStorage/OneDrive-Personal/Documents/School/UChicago/Year 4/ECON 21110/FINAL PROJECT/econ-21110-winter-2023/"
global ddir "/Users/gelkouh/Google Drive (UChicago)/Classes/ECON 21110/data/"

*output file
log using "${cdir}code/replication.log", replace

********************************************************************************************************
* Replication of Burke and Liao (2015)           
********************************************************************************************************

use "${ddir}ChinaCoalElasticity.dta", clear
desc


log close
