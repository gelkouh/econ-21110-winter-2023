cap log close
set more off
clear all

*set project directory
global ddir "/Users/gelkouh/Library/CloudStorage/OneDrive-Personal/Documents/School/UChicago/Year 4/ECON 21110/FINAL PROJECT/"

*output file
log using "${ddir}econ-21110-winter-2023/code/extension_regression_analysis.log", replace

********************************************************************************************************
* Extension regression analysis             
********************************************************************************************************

********************************************************************************************************
* IV
********************************************************************************************************

import delimited "${ddir}data/cleaned/capiq_cleaned.csv", clear
replace seam_height_in = "" if seam_height_in == "NA"
encode seam_height_in, gen(seam_height_in2)
drop seam_height_in
rename seam_height_in2 seam_height_in

egen plant_mine_cluster=group(power_plant key_mine_id)
reg ln_price_per_ton seam_height_in
ivregress 2sls ln_qty_coal_purch (ln_price_per_ton = seam_height_in)
ivregress 2sls ln_qty_coal_purch (ln_price_per_ton = seam_height_in), robust
ivregress 2sls ln_qty_coal_purch (ln_price_per_ton = seam_height_in), cluster(plant_mine_cluster)


log close
