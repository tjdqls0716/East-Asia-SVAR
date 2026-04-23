/*
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 1: Data Cleaning and Variable Transformation
Author: tjdqls0716
Date: 2026-04-23

Description: 
This script imports the raw Excel data, sets the panel time-series 
structure, and generates log-transformed and first-differenced variables 
for Real GDP, CPI, and REER.
*/

clear all
import excel "PPE Macrodata.xlsx", sheet("Sheet1") firstrow clear

**Data Cleaning**
*1. Set Time series
gen qtr = quarterly(quarter, "YQ")
format qtr %tq
xtset country_id qtr

*2. Log Transformation
gen l_gdp = ln(real_gdp)
gen l_cpi = ln(cpi)
gen l_reer = ln(reer)

*3. Difference
gen dl_gdp = d.l_gdp
gen dl_cpi = d.l_cpi
gen dl_reer = d.l_reer


// -----------------------------------------------------------------------------
// Part 2: Unit Root Test (Panel Data)
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
// Part 3: Optimal Lag Selection
// -----------------------------------------------------------------------------
// Checking VAR Lag Order Selection Criteria for each economy.
// Criteria used: AIC, HQIC, SBIC.

varsoc dl_gdp dl_cpi dl_reer if country_id==1, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==3, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==2, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==4, maxlag(8)
varsoc dl_gdp dl_cpi dl_reer if country_id==5, maxlag(8)

// Conclusion: Lag 4 is chosen for all economies to maintain consistency 
// and capture quarterly seasonality.

// -----------------------------------------------------------------------------
// Part 4: Seasonal Adjustment (Generating Seasonal Dummies)
// -----------------------------------------------------------------------------
// Since the data is non-seasonally adjusted (NSA), seasonal dummies are included as exogenous variables to control for quarterly seasonal effects.
gen mtr = month(dofq(qtr))
gen s1 = (mtr == 1)
gen s2 = (mtr == 4)
gen s3 = (mtr == 7)

// Note: 4th Quarter (mtr == 10) is used as the base reference group.
