cap log close
set more off
clear all

*set project directory
global cdir "/Users/gelkouh/Library/CloudStorage/OneDrive-Personal/Documents/School/UChicago/Year 4/ECON 21110/FINAL PROJECT/econ-21110-winter-2023/"
global ddir "/Users/gelkouh/Google Drive (UChicago)/Classes/ECON 21110/data/"

*output file
log using "${cdir}code/extension_regression_analysis.log", replace

********************************************************************************************************
* Extension regression analysis             
********************************************************************************************************

********************************************************************************************************
* IV
********************************************************************************************************

import delimited "${ddir}cleaned/capiq_cleaned.csv", clear
replace seam_height_in = "" if seam_height_in == "NA"
encode seam_height_in, gen(seam_height_in2)
drop seam_height_in
rename seam_height_in2 seam_height_in

egen plant_mine_cluster=group(power_plant key_mine_id)
egen fuel_contract_type_group=group(fuel_contract_type)
reg ln_price_per_ton seam_height_in
ivregress 2sls ln_qty_coal_purch i.fuel_contract_type_group i.dlvy_yr (ln_price_per_ton = seam_height_in)
ivregress 2sls ln_qty_coal_purch i.fuel_contract_type_group i.dlvy_yr (ln_price_per_ton = seam_height_in), robust first
ivregress 2sls ln_qty_coal_purch i.fuel_contract_type_group (ln_price_per_ton = seam_height_in), cluster(plant_mine_cluster) first

reg ln_price_per_ton seam_height_in
local firststageFstat = e(F)
local nobs = e(N)

*twoway (lpolyci ln_price_per_ton seam_height_in)
*twoway (lpolyci ln_price_per_ton seam_height_in) (scatter ln_price_per_ton seam_height_in) (lfit ln_price_per_ton seam_height_in)

local nbins = 44
binscatter ln_price_per_ton seam_height_in, nq(`nbins') ///
        ytitle("Price per ton (log)", size(large)) xtitle("Coal seam height (inches)", size(large))  ///
        note("Binscatter: `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(large))

preserve
* Trimming top and bottom 1 percent of observations
summarize ln_price_per_ton, detail
drop if ln_price_per_ton<r(p1) | ln_price_per_ton>r(p99)
summarize seam_height_in, detail
drop if seam_height_in<r(p1) | seam_height_in>r(p99)

reg ln_price_per_ton seam_height_in
local firststageFstat = e(F)
local nobs = e(N)
local nbins = 44
binscatter ln_price_per_ton seam_height_in, nq(`nbins') ///
	ytitle("Price per ton (log)", size(large)) xtitle("Coal seam height (inches)", size(large))  ///
	note("Binscatter: `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(large))
graph export "${cdir}output/seam_height_firststage.png", replace
restore

forvalues i = 2003(5)2019 {
	
	local lower_year = `i' - 2
	local upper_year = `i' + 2
	
	preserve
	
	keep if dlvy_yr >= `lower_year' & dlvy_yr <= `upper_year'
	
	summarize ln_price_per_ton, detail
	drop if ln_price_per_ton<r(p1) | ln_price_per_ton>r(p99)
	summarize seam_height_in, detail
	drop if seam_height_in<r(p1) | seam_height_in>r(p99)

	reg ln_price_per_ton seam_height_in
	local firststageFstat = e(F)
	local nobs = e(N)
	local nbins = 44
	binscatter ln_price_per_ton seam_height_in, nq(`nbins') ///
		ytitle("Price per ton (log)", size(large)) xtitle("Coal seam height (inches)", size(large))  ///
		note("Binscatter, `lower_year'-`upper_year': `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(large))
	graph export "${cdir}output/seam_height_firststage_`lower_year'_`upper_year'.png", replace
	
	restore
	
}

forvalues i = 2002(1)2021 {
	
	preserve
	
	keep if dlvy_yr == `i'
	
	ivregress 2sls ln_qty_coal_purch i.fuel_contract_type_group (ln_price_per_ton = seam_height_in), robust first
	
	summarize ln_price_per_ton, detail
	drop if ln_price_per_ton<r(p1) | ln_price_per_ton>r(p99)
	summarize seam_height_in, detail
	drop if seam_height_in<r(p1) | seam_height_in>r(p99)

	reg ln_price_per_ton seam_height_in
	local firststageFstat = e(F)
	local nobs = e(N)
	local nbins = 44
	binscatter ln_price_per_ton seam_height_in, nq(`nbins') ///
		ytitle("Price per ton (log)", size(large)) xtitle("Coal seam height (inches)", size(large))  ///
		note("Binscatter, `i': `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(large))
	graph export "${cdir}output/seam_height_firststage_`i'.png", replace
	
	restore
	
}

	
	preserve
	
	keep if dlvy_yr >= 2000 & dlvy_yr <= 2010
	
	ivregress 2sls ln_qty_coal_purch i.fuel_contract_type_group (ln_price_per_ton = seam_height_in), robust first
	
	summarize ln_price_per_ton, detail
	drop if ln_price_per_ton<r(p1) | ln_price_per_ton>r(p99)
	summarize seam_height_in, detail
	drop if seam_height_in<r(p1) | seam_height_in>r(p99)

	reg ln_price_per_ton seam_height_in
	local firststageFstat = e(F)
	local nobs = e(N)
	local nbins = 44
	binscatter ln_price_per_ton seam_height_in, nq(`nbins') ///
		ytitle("Price per ton (log)", size(large)) xtitle("Coal seam height (inches)", size(large))  ///
		note("Binscatter, 2002-2010: `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(large))
	graph export "${cdir}output/seam_height_firststage_2002_2010.png", replace
	
	restore
	preserve
	
	keep if dlvy_yr > 2010
	
	ivregress 2sls ln_qty_coal_purch i.fuel_contract_type_group (ln_price_per_ton = seam_height_in), robust first
	
	summarize ln_price_per_ton, detail
	drop if ln_price_per_ton<r(p1) | ln_price_per_ton>r(p99)
	summarize seam_height_in, detail
	drop if seam_height_in<r(p1) | seam_height_in>r(p99)

	reg ln_price_per_ton seam_height_in
	local firststageFstat = e(F)
	local nobs = e(N)
	local nbins = 44
	binscatter ln_price_per_ton seam_height_in, nq(`nbins') ///
		ytitle("Price per ton (log)", size(large)) xtitle("Coal seam height (inches)", size(large))  ///
		note("Binscatter, 2011-2021: `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(large))
	graph export "${cdir}output/seam_height_firststage_2011_2021.png", replace
	
	restore
	


log close
