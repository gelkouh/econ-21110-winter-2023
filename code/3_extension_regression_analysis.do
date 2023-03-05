cap log close
set more off
clear all

set scheme cleanplots

*set project directory
global cdir "/Users/gelkouh/Library/CloudStorage/OneDrive-Personal/Documents/School/UChicago/Year 4/ECON 21110/FINAL PROJECT/econ-21110-winter-2023/"
global ddir "/Users/gelkouh/Google Drive (UChicago)/Classes/ECON 21110/data/"

*output file
log using "${cdir}code/extension_regression_analysis.log", replace

********************************************************************************************************
* Extension figures and summary statistics             
********************************************************************************************************

import delimited "${ddir}cleaned/contracts_cleaned.csv", clear
desc

drop if year < 2002 | year > 2021
keep if contract_type == "Contract"
sort year

* Figure 4 analog 
preserve 

collapse (mean) price_per_ton ppi_coalmining, by(year)

// Normalize to 2002 = 1
gen price_per_ton_2002	= price_per_ton[1]
gen ppi_coalmining_2002	= ppi_coalmining[1]

gen coalpriceindex_fig	= price_per_ton / price_per_ton_2002
gen ppi_fig				= ppi_coalmining / ppi_coalmining_2002

twoway (line coalpriceindex_fig year, lc(blue) lw(medthick)) ///
       (line ppi_fig year, lc(red) lw(medthick)), ///
       xlabel(2002(2)2022) xtitle("Year") ytitle("Index (2002 = 1)") legend(label(1 "Coal price per ton") label(2 "Industrial producer prices (coal mining)") position(6))
graph export "${cdir}output/extension_fig4.png", replace
	   
restore

gen t 					= year - 2002
gen lncoalqty 			= ln(qty_coal_purch)
gen realcoalprice		= 100*price_per_ton/ppi_coalmining
gen lnrealcoalprice		= ln(realcoalprice)
gen realgdp				= rgdp
gen lnrealgdp			= ln(realgdp)
gen t_x_lnrealcoalprice	= t*lnrealcoalprice
encode power_plant, gen(power_plant_encoded)
encode state, gen(state_encoded)
replace seam_height_in = "" if seam_height_in == "NA"
destring seam_height_in, replace 
 
lab var lncoalqty "Ln Coal contract quantity (tons)"
lab var lnrealcoalprice "Ln Real contract coal price per ton"
lab var t "Time trend"
lab var lnrealgdp "Ln GDP"
lab var seam_height_in "Coal seam height (in.)"

* Summary statistics 
eststo: quietly estpost summarize ///
    lncoalqty lnrealcoalprice t lnrealgdp seam_height_in

esttab using "${cdir}output/extension_summary_stats.tex", replace ///
cells("mean() sd() min() max() count()") ///
label nonumbers
eststo clear

********************************************************************************************************
* Extension regression analysis             
********************************************************************************************************

lab var lncoalqty "Ln Coal qty (tons)"
lab var lnrealcoalprice "Ln Real coal price per ton"
lab var t "Time trend"
lab var lnrealgdp "Ln GDP"

********************************************************************************************************
* OLS and IV (linear time trend)
********************************************************************************************************

// (1)
eststo: reg lncoalqty lnrealcoalprice lnrealgdp t i.power_plant_encoded, vce(cluster power_plant_encoded)
// (2)
eststo: ivregress 2sls lncoalqty lnrealgdp t i.power_plant_encoded (lnrealcoalprice = seam_height_in), robust first 
estat endogenous
preserve
	keep if year >= 2002 & year <= 2010
	// (3)
	eststo: reg lncoalqty lnrealcoalprice lnrealgdp t i.power_plant_encoded, vce(cluster power_plant_encoded)
	// (4)
	eststo: ivregress 2sls lncoalqty lnrealgdp t i.power_plant_encoded (lnrealcoalprice = seam_height_in), robust first 
	estat endogenous
restore
preserve
	keep if year >= 2011 & year <= 2021
	// (5)
	eststo: reg lncoalqty lnrealcoalprice lnrealgdp t i.power_plant_encoded, vce(cluster power_plant_encoded) 
	// (6)
	eststo: ivregress 2sls lncoalqty lnrealgdp t i.power_plant_encoded (lnrealcoalprice = seam_height_in), robust first 
	estat endogenous
restore
// (7)
eststo: reg lncoalqty c.lnrealcoalprice##c.t lnrealgdp i.power_plant_encoded, vce(cluster power_plant_encoded)
// (8)
eststo: ivregress 2sls lncoalqty lnrealgdp t i.power_plant_encoded (lnrealcoalprice c.lnrealcoalprice#c.t = seam_height_in c.seam_height_in#c.t), robust first
estat endogenous

*Save regression output to LaTeX table
esttab using "${cdir}output/extension_lineartime.tex", se(%10.4f) r2 ar2 star(* 0.10 ** 0.05 *** 0.01) replace booktabs ///
mtitles("\shortstack{(1)\\OLS, Full}" "\shortstack{(2)\\IV, Full}" "\shortstack{(3)\\OLS, Early}" "\shortstack{(4)\\IV, Early}" "\shortstack{(5)\\OLS, Late}" "\shortstack{(6)\\IV, Late}" "\shortstack{(7)\\OLS, Full}" "\shortstack{(8)\\IV, Full}") label nonumbers indicate("Power plant fixed effects=*.power_plant_encoded")
eststo clear

* First stage regressions
reg lnrealcoalprice c.t##c.seam_height_in lnrealgdp, robust
	local firststageFstat = e(F)
	local nobs = e(N)
	local nbins = 44
	binscatter lnrealcoalprice seam_height_in, controls(c.t#c.seam_height_in t lnrealgdp) nq(`nbins') ///
		ytitle("Ln Real contract coal price per ton", size(small)) xtitle("Coal seam height (in.)", size(small))  ///
		note("Binscatter, 2002-2021: `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(small)) 
	graph export "${cdir}output/seam_height_firststage_1.png", replace

reg t_x_lnrealcoalprice c.t##c.seam_height_in lnrealgdp, robust
	local firststageFstat = e(F)
	local nobs = e(N)
	local nbins = 44
	binscatter t_x_lnrealcoalprice seam_height_in, controls(c.t#c.seam_height_in t lnrealgdp) nq(`nbins') ///
		ytitle("t x Ln Real contract coal price per ton", size(small)) xtitle("Coal seam height (in.)", size(small))  ///
		note("Binscatter, 2002-2021: `nobs' contracts in `nbins' bins" "First-stage F-statistic: `firststageFstat'", size(small)) 
	graph export "${cdir}output/seam_height_firststage_2.png", replace
	********************************************************************************************************
* OLS and IV (yearly time dummies)
********************************************************************************************************

// (1)
eststo: reg lncoalqty lnrealcoalprice lnrealgdp i.t i.power_plant_encoded, vce(cluster power_plant_encoded)
// (2)
eststo: ivregress 2sls lncoalqty lnrealgdp i.t i.power_plant_encoded (lnrealcoalprice = seam_height_in), robust first 
estat endogenous
// (3)
eststo: reg lncoalqty c.lnrealcoalprice##i.t lnrealgdp i.power_plant_encoded, vce(cluster power_plant_encoded)
// (4)
eststo: ivregress 2sls lncoalqty lnrealgdp i.t i.power_plant_encoded (lnrealcoalprice i.t#c.lnrealcoalprice = seam_height_in i.t#c.seam_height_in), robust first
estat endogenous

*Save regression output to LaTeX table
esttab using "${cdir}output/extension_yearlytimedummies.tex", se(%10.4f) r2 ar2 star(* 0.10 ** 0.05 *** 0.01) replace booktabs ///
mtitles("\shortstack{(1)\\OLS}" "\shortstack{(2)\\IV}" "\shortstack{(3)\\OLS}" "\shortstack{(4)\\IV}") label nonumbers indicate("Power plant fixed effects=*.power_plant_encoded" "Year fixed effects=*.t")
eststo clear

********************************************************************************************************
* OLS and IV (5-year time dummies)
********************************************************************************************************

preserve 

replace t = 0 if year <= 2006
replace t = 1 if year >= 2007 & year <= 2011
replace t = 2 if year >= 2012 & year <= 2016
replace t = 3 if year >= 2017 & year <= 2021

// (1)
eststo: reg lncoalqty lnrealcoalprice lnrealgdp i.t i.power_plant_encoded, vce(cluster power_plant_encoded)
// (2)
eststo: ivregress 2sls lncoalqty lnrealgdp i.t i.power_plant_encoded (lnrealcoalprice = seam_height_in), robust first 
estat endogenous
// (3)
eststo: reg lncoalqty c.lnrealcoalprice##i.t lnrealgdp i.power_plant_encoded, vce(cluster power_plant_encoded)
// (4)
eststo: ivregress 2sls lncoalqty lnrealgdp i.t i.power_plant_encoded (lnrealcoalprice i.t#c.lnrealcoalprice = seam_height_in i.t#c.seam_height_in), robust first
estat endogenous

*Save regression output to LaTeX table
esttab using "${cdir}output/extension_5yeartimedummies.tex", se(%10.4f) r2 ar2 star(* 0.10 ** 0.05 *** 0.01) replace booktabs ///
mtitles("\shortstack{(1)\\OLS}" "\shortstack{(2)\\IV}" "\shortstack{(3)\\OLS}" "\shortstack{(4)\\IV}") label nonumbers indicate("Power plant fixed effects=*.power_plant_encoded" "Year fixed effects=*.t")
eststo clear

restore

log close
