/*
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 1: Data Cleaning, Variable Transformation, and Global Factor Integration
Author: tjdqls0716
Date: 2026-04-23

Description:
This script imports quarterly macroeconomic data, integrates global financial
factors from FRED, sets the panel structure, and generates stationary variables
for SVAR analysis.

Countries:
1 = Korea
2 = China
3 = Japan
4 = Hong Kong
5 = Taiwan

Notes:
- The global FRED dataset used here is already quarterly.
- VIX and Fed Funds Rate are included as global exogenous controls.
- Seasonal dummies are included because the macro series are non-seasonally adjusted.
*/

clear all
set more off

// --------------------------------------------------------------------------
// 1. Import and Prepare Global Exogenous Variables (FRED Data)
//---------------------------------------------------------------------------

import excel "global_data_raw.xlsx", sheet("Sheet1") firstrow clear
drop if missing(observation_date) & missing(FEDFUNDS) & missing(VIXCLS)

* Convert FRED observation date to Stata quarterly date
gen qtr = yq(year(observation_date), quarter(observation_date))
format qtr %tq
sort qtr

rename FEDFUNDS fedfunds
rename VIXCLS vix

* Keep only necessary variables
keep qtr fedfunds vix

* Check that the global dataset is uniquely identified by quarter
isid qtr

save "global_temp.dta", replace

// --------------------------------------------------------------------------
// 2. Import Main Macro Data and Merge with Global Factors
//---------------------------------------------------------------------------

import excel "PPE Macrodata.xlsx", sheet("Sheet1") firstrow clear

rename quarter quarter_str
gen qtr = quarterly(quarter_str, "YQ")
format qtr %tq

sort country_id qtr
isid country_id qtr

merge m:1 qtr using "global_temp.dta"
tab _merge
keep if _merge == 3
drop _merge

xtset country_id qtr

// --------------------------------------------------------------------------
// 3. Variable Transformation
// --------------------------------------------------------------------------

gen l_gdp  = ln(real_gdp)
gen l_cpi  = ln(cpi)
gen l_reer = ln(reer)
gen ln_vix = ln(vix)

gen dl_gdp  = d.l_gdp
gen dl_cpi  = d.l_cpi
gen dl_reer = d.l_reer

* Seasonal dummies: Q4 is the omitted base category
gen q = quarter(dofq(qtr))
tab q, gen(season)
drop season4
rename season1 s1
rename season2 s2
rename season3 s3

// --------------------------------------------------------------------------
// 4. Panel Unit Root Tests
// --------------------------------------------------------------------------

xtunitroot fisher l_gdp,  dfuller lags(1)
xtunitroot fisher l_cpi,  dfuller lags(1)
xtunitroot fisher l_reer, dfuller lags(1)

xtunitroot fisher dl_gdp,  dfuller lags(1)
xtunitroot fisher dl_cpi,  dfuller lags(1)
xtunitroot fisher dl_reer, dfuller lags(1)

// --------------------------------------------------------------------------
// 5. Lag Selection and Diagnostic Checks
// --------------------------------------------------------------------------

foreach c of numlist 1/5 {
    varsoc dl_gdp dl_cpi dl_reer if country_id == `c', maxlag(8)
}

* Four lags are used consistently to capture one year of quarterly dynamics and maintain comparability across country-specific VAR models.
foreach c of numlist 1/5 {
    var dl_gdp dl_cpi dl_reer if country_id == `c', ///
        lags(1/4) exog(fedfunds ln_vix s1 s2 s3)

    varlmar, mlag(8)
    varstable
}

// --------------------------------------------------------------------------
// 6. Labels and Save Final Dataset
// --------------------------------------------------------------------------

label var fedfunds "US Fed Funds Rate (%)"
label var vix      "VIX Index"
label var ln_vix   "Global Financial Risk (ln VIX)"

label var l_gdp    "Log Real GDP"
label var l_cpi    "Log CPI"
label var l_reer   "Log REER"

label var dl_gdp   "Real GDP Growth (d.ln, QoQ)"
label var dl_cpi   "Inflation Rate (d.ln, QoQ)"
label var dl_reer  "REER Change (d.ln, QoQ)"

compress
save "final_panel_v2.dta", replace
