/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 5: Construction of Integration and Structural Indicators
Author: tjdqls0716
Date: 2026-04-25

Description:
This script constructs pair-level regressors for the final panel regression.
It calculates 20-quarter moving averages of trade integration, financial
integration, and industrial structural difference, then merges these indicators with 20-quarter rolling structural shock correlations generated in the previous step.

Main regressors:
    1. Trade integration
    2. Financial integration based on real interest rate convergence
    3. Industrial structural difference based on the Krugman Specialisation Index

Input:
    Regression Indicators.xlsx
    rolling_corrs_final_long.dta

Output:
    Final_Analysis_Data.dta
========================================================================= */

// --------------------------------------------------------------------------
// 0. Environment Setup
// --------------------------------------------------------------------------

clear all
set more off

// --------------------------------------------------------------------------
// 1. Load Regressor Dataset and Set Pair-Time Structure
// --------------------------------------------------------------------------

import excel "Regression Indicators.xlsx", ///
    sheet("Sheet1") firstrow clear

* Construct Stata quarterly date.
gen date = yq(year, qtr)
format date %tq

* Standardise pair identifier if needed.
replace pair = lower(pair)

* Check that pair-date uniquely identifies observations.
isid pair date

* Create numeric pair ID for panel/time-series operations.
egen pair_id = group(pair), label

xtset pair_id date

// --------------------------------------------------------------------------
// 2. Trade Integration: 20-Quarter Moving Average
// --------------------------------------------------------------------------

/*
Trade integration is measured as:

    TI_ij = (Exports_ij + Exports_ji) / (GDP_i + GDP_j)

The raw series is smoothed using a strict 20-quarter moving average. A value is kept only when all 20 observations in the rolling window are available.
*/

rangestat (mean) trade_ma20 = trade_raw ///
          (count) n_trade20 = trade_raw, ///
          interval(date -19 0) by(pair_id)

replace trade_ma20 = . if n_trade20 < 20

label var trade_raw  "Bilateral trade integration, raw"
label var trade_ma20 "Bilateral trade integration, 20-quarter moving average"

// --------------------------------------------------------------------------
// 3. Financial Integration: Real Interest Rate Convergence
// --------------------------------------------------------------------------

/*
Financial integration is proxied by real interest rate convergence.

Inflation is calculated as year-on-year CPI inflation.
Real interest rate = nominal interest rate - YoY inflation.
The bilateral measure is defined as:

    -abs(real_rate_i - real_rate_j)

A higher value indicates a smaller real interest rate gap and hence stronger
financial convergence.
*/

gen inf_i = ((cpi_i - L4.cpi_i) / L4.cpi_i) * 100
gen inf_j = ((cpi_j - L4.cpi_j) / L4.cpi_j) * 100

gen real_rate_i = nom_rate_i - inf_i
gen real_rate_j = nom_rate_j - inf_j

gen real_ir_diff = -abs(real_rate_i - real_rate_j)

rangestat (mean) fi_real_ir_ma20 = real_ir_diff ///
          (count) n_fi20 = real_ir_diff, ///
          interval(date -19 0) by(pair_id)

replace fi_real_ir_ma20 = . if n_fi20 < 20

* Robustness financial integration measure: nominal interest rate convergence
gen nom_ir_diff = -abs(nom_rate_i - nom_rate_j)

rangestat (mean) fi_nom_ir_ma20 = nom_ir_diff ///
          (count) n_fi_nom20 = nom_ir_diff, ///
          interval(date -19 0) by(pair_id)

replace fi_nom_ir_ma20 = . if n_fi_nom20 < 20

label var inf_i "Inflation rate of country i, YoY (%)"
label var inf_j "Inflation rate of country j, YoY (%)"
label var real_rate_i "Real interest rate of country i (%)"
label var real_rate_j "Real interest rate of country j (%)"
label var real_ir_diff "Real interest rate convergence: -abs(real_i - real_j)"
label var fi_real_ir_ma20 "Financial integration, real IR convergence, 20-quarter MA"
label var nom_ir_diff "Nominal interest rate convergence: -abs(nom_i - nom_j)"
label var fi_nom_ir_ma20 "Financial integration, nominal IR convergence, 20-quarter MA"

// --------------------------------------------------------------------------
// 4. Industrial Structural Difference: Krugman Specialisation Index
// --------------------------------------------------------------------------

/*
The Krugman Specialisation Index captures differences in industrial structures.
A higher value indicates greater structural difference between the two economies.
The raw series is smoothed using a strict 20-quarter moving average.
*/

rangestat (mean) KSI_ma20 = KSI ///
          (count) n_ksi20 = KSI, ///
          interval(date -19 0) by(pair_id)

replace KSI_ma20 = . if n_ksi20 < 20

label var KSI "Krugman Specialisation Index, raw"
label var KSI_ma20 "Krugman Specialisation Index, 20-quarter moving average"

// --------------------------------------------------------------------------
// 5. Merge Dependent Variables: Rolling Shock Correlations
// --------------------------------------------------------------------------

/*
The dependent variables are the 20-quarter rolling correlations of structural
shocks generated in 04_calc_all_rolling_corrs.do.

Merge key:
    pair date
*/

merge 1:1 pair date using "rolling_corrs_final_long.dta"

tab _merge

keep if _merge == 3
drop _merge

// --------------------------------------------------------------------------
// 6. Keep and Rename Variables for Final Regressions
// --------------------------------------------------------------------------

keep pair pair_id date year qtr ///
     corr_output corr_inflation corr_er ///
     trade_ma20 fi_real_ir_ma20 fi_nom_ir_ma20 KSI_ma20 

rename trade_ma20        trade
rename fi_real_ir_ma20   fin_real
rename fi_nom_ir_ma20    fin_nom
rename KSI_ma20          structure

// --------------------------------------------------------------------------
// 7. Standardise Explanatory Variables
// --------------------------------------------------------------------------

/*
Standardised versions of the explanatory variables are constructed for
comparability across coefficients. These variables have mean zero and standard deviation one in the final merged dataset before the common-sample restriction.
*/

foreach x in trade fin_real fin_nom structure {
    egen z_`x' = std(`x')
    label var z_`x' "Standardised `x'"
}

// --------------------------------------------------------------------------
// 8. Variable Labels
// --------------------------------------------------------------------------

label var pair "Country pair"
label var pair_id "Country-pair ID"
label var date "Quarter"

label var corr_output ///
    "Output shock synchronisation (20-quarter rolling correlation)"

label var corr_inflation ///
    "Inflation shock synchronisation (20-quarter rolling correlation)"

label var corr_er ///
    "REER shock synchronisation (20-quarter rolling correlation)"

label var trade ///
    "Trade integration (20-quarter moving average)"

label var fin_real ///
    "Financial integration: real interest rate convergence (20-quarter MA)"

label var fin_nom ///
    "Financial integration: nominal interest rate convergence (20-quarter MA)"

label var structure ///
    "Industrial structural difference (Krugman Specialisation Index, 20-quarter MA)"

// --------------------------------------------------------------------------
// 8. Final Sample Restrictions and Save
// --------------------------------------------------------------------------

/*
The final estimation sample is restricted to observations with non-missing
dependent variables and regressors. This creates a common balanced sample across
the three final regression specifications.
*/

keep if !missing(corr_output, corr_inflation, corr_er, ///
                 trade, fin_real, fin_nom, structure)

xtset pair_id date

compress

save "Final_Analysis_Data.dta", replace
