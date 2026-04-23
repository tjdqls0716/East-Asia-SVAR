/*
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 1: Data Cleaning, Variable Transformation, and Global Factor Integration
Author: tjdqls0716
Date: 2026-04-23 (Updated)

Description: 
This script imports raw macro data, integrates global financial factors 
(US Fed Funds Rate and VIX Index) from FRED, sets the panel structure, 
and generates stationary variables for SVAR analysis.
*/

clear all

// -----------------------------------------------------------------------------
// Part 1: Import and Prepare Global Exogenous Variables (FRED Data)
// -----------------------------------------------------------------------------
// Import US Fed Funds Rate and VIX Index data
import excel "global_data_raw.xlsx", sheet("Sheet1") firstrow clear

* Convert FRED date format to Stata quarterly format
gen qtr = yq(year(observation_date), quarter(observation_date))
format qtr %tq
sort qtr

rename FEDFUNDS fedfunds
rename VIXCLS vix

* Keep only necessary variables and save as a temporary dataset
keep qtr fedfunds vix
save "global_temp.dta", replace

// -----------------------------------------------------------------------------
// Part 2: Import Main Macrodata and Merge with Global Factors
// -----------------------------------------------------------------------------
import excel "PPE Macrodata.xlsx", sheet("Sheet1") firstrow clear

* Set initial quarterly time variable
gen qtr = quarterly(quarter, "YQ")
format qtr %tq
sort qtr

* Merge with global factors (Many-to-One merge)
merge m:1 qtr using "global_temp.dta"
keep if _merge == 3
drop _merge

** Data Cleaning and Transformation **
* 1. Set Panel Data Structure
xtset country_id qtr

* 2. Log Transformation (Internal & External Variables)
gen l_gdp = ln(real_gdp)
gen l_cpi = ln(cpi)
gen l_reer = ln(reer)
gen ln_vix = ln(vix) // Log transformation for VIX to stabilize variance

* 3. First-Differencing for Stationarity
gen dl_gdp = d.l_gdp
gen dl_cpi = d.l_cpi
gen dl_reer = d.l_reer

// -----------------------------------------------------------------------------
// Part 3: Unit Root Test (Panel Data)
// -----------------------------------------------------------------------------
// Testing for stationarity using Fisher-type Augmented Dickey-Fuller (ADF) tests.
// Null Hypothesis (H0): All panels contain unit roots (Non-stationary).

* [A] Level Variables (Log-transformed)
// Result: High p-values (p > 0.05) indicate the presence of unit roots.
xtunitroot fisher l_gdp, dfuller lags(1)
xtunitroot fisher l_cpi, dfuller lags(1)
xtunitroot fisher l_reer, dfuller lags(1)

* [B] First-Differenced Variables (Growth/Volatility)
// Result: Low p-values (p < 0.01) reject H0; variables are stationary at 1% level.
xtunitroot fisher dl_gdp, dfuller lags(1)
xtunitroot fisher dl_cpi, dfuller lags(1)
xtunitroot fisher dl_reer, dfuller lags(1)

// -----------------------------------------------------------------------------
// Part 4: Optimal Lag Selection
// -----------------------------------------------------------------------------
// Checking VAR Lag Order Selection Criteria (AIC, HQIC, SBIC) for each economy.
varsoc dl_gdp dl_cpi dl_reer if country_id==1, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==2, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==3, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==4, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==5, maxlag(8)

// -----------------------------------------------------------------------------
// Part 5: Seasonal Adjustment and Global Control Setup
// -----------------------------------------------------------------------------
// Generate seasonal dummies to control for quarterly effects
gen mtr = month(dofq(qtr))
gen s1 = (mtr == 1)
gen s2 = (mtr == 4)
gen s3 = (mtr == 7)
// Note: 4th Quarter (mtr == 10) is used as the base reference group.

* Labeling variables for clarity in analysis
label var ln_vix "Global Financial Risk (ln VIX)"
label var fedfunds "US Fed Funds Rate (%)"
label var dl_gdp "Real GDP Growth (d.ln)"
label var dl_cpi "Inflation Rate (d.ln)"
label var dl_reer "REER Volatility (d.ln)"

* Save the finalized panel dataset for SVAR estimation
save "final_panel_v2.dta", replace
