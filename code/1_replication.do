cap log close
set more off
clear all

set scheme cleanplots

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

drop if year < 1998 | year > 2012
sort year

* Figure 4
preserve 

collapse (mean) coalpriceindex ppi, by(year)

// Normalize to 1998 = 1
gen coalpriceindex1998	= coalpriceindex[1]
gen ppi1998				= ppi[1]

gen coalpriceindex_fig	= coalpriceindex / coalpriceindex1998
gen ppi_fig				= ppi / ppi1998

twoway (line coalpriceindex_fig year, lc(blue) lw(medthick)) ///
       (line ppi_fig year, lc(red) lw(medthick)), ///
       xlabel(1998(2)2012) xtitle("Year") ytitle("Index (1998 = 1)") legend(label(1 "Coal price") label(2 "Industrial producer prices") position(6))
graph export "${cdir}output/replication_fig4.png", replace
	   
restore

gen t 						= year - 1998
gen lncoalconsumption 		= ln(coalconsumption)
gen realcoalpriceindex		= 100*coalpriceindex/ppi
gen lnrealcoalpriceindex	= ln(realcoalpriceindex)
gen realgdp					= 100*gdpnominal/gdpdeflator_china
gen lnrealgdp				= ln(realgdp)
encode province, gen(province_encoded)

summ lncoalconsumption
summ lnrealcoalpriceindex
summ t
summ lnrealgdp

sort province year
by province: gen lnrealcoalpriceindex_tminus1 = lnrealcoalpriceindex[_n-1]
by province: gen lnrealcoalpriceindex_tminus2 = lnrealcoalpriceindex[_n-2]

* Table 2: Main results 
// (1)
reg lncoalconsumption lnrealcoalpriceindex lnrealgdp t i.province_encoded, vce(cluster province_encoded)
preserve
	keep if year >= 1998 & year <= 2007
	// (2)
	reg lncoalconsumption lnrealcoalpriceindex lnrealgdp t i.province_encoded, vce(cluster province_encoded) 
restore
preserve
	keep if year >= 2008 & year <= 2012
	// (3)
	reg lncoalconsumption lnrealcoalpriceindex lnrealgdp t i.province_encoded, vce(cluster province_encoded) 
restore
// (4)
reg lncoalconsumption c.lnrealcoalpriceindex##c.t lnrealgdp i.province_encoded, vce(cluster province_encoded)

// (5)
reg lncoalconsumption lnrealcoalpriceindex lnrealcoalpriceindex_tminus1 lnrealcoalpriceindex_tminus2 lnrealgdp t i.province_encoded, vce(cluster province_encoded)
// (6)
reg lncoalconsumption lnrealcoalpriceindex lnrealcoalpriceindex_tminus2 lnrealgdp t i.province_encoded, vce(cluster province_encoded)
preserve
	keep if year >= 1998 & year <= 2007
	// (7)
	reg lncoalconsumption lnrealcoalpriceindex lnrealcoalpriceindex_tminus2 lnrealgdp t i.province_encoded, vce(cluster province_encoded)
restore
preserve
	keep if year >= 2008 & year <= 2012
	// (8)
	reg lncoalconsumption lnrealcoalpriceindex lnrealcoalpriceindex_tminus2 lnrealgdp t i.province_encoded, vce(cluster province_encoded) 
restore
// (9)
reg lncoalconsumption lnrealcoalpriceindex c.lnrealcoalpriceindex#c.t lnrealcoalpriceindex_tminus2 c.lnrealcoalpriceindex_tminus2#c.t lnrealgdp t i.province_encoded, vce(cluster province_encoded)

log close
