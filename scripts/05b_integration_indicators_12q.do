/* ========*================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 5b: Construction of Final Dataset with 12-Quarter Window
Author: tjdqls0716
Date: 2026-04-29

Description:
This script constructs the final regression dataset for the 12-quarter rolling
window robustness check. The dependent variables are 12-quarter rolling
correlations of structural shocks generated in 04b_calc_all_rolling_corrs_12q.do.

Input:
    Regression Indicators.xlsx
    rolling_corrs_final_long_12q.dta

Output:
    Final_Analysis_Data_12q.dta
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

* Standardise pair identifier for merging.
replace pair = lower(pair)

* Check that pair-date uniquely identifies observations.
isid pair date

* Create numeric pair ID for panel/time-series operations.
egen pair_id = group(pair), label

xtset pair_id date

// --------------------------------------------------------------------------
// 2. Trade Integration: 12-Quarter Moving Average
// --------------------------------------------------------------------------

rangestat (mean) trade_ma12 = trade_raw ///
          (count) n_trade12 = trade_raw, ///
          interval(date -11 0) by(pair_id)

replace trade_ma12 = . if n_trade12 < 12

label var trade_raw  "Bilateral trade integration, raw"
label var trade_ma12 "Bilateral trade integration, 12-quarter moving average"

// --------------------------------------------------------------------------
// 3. Financial Integration: Real and Nominal Interest Rate Convergence
// --------------------------------------------------------------------------

* YoY inflation.
gen inf_i = ((cpi_i - L4.cpi_i) / L4.cpi_i) * 100
gen inf_j = ((cpi_j - L4.cpi_j) / L4.cpi_j) * 100

* Real interest rates.
gen real_rate_i = nom_rate_i - inf_i
gen real_rate_j = nom_rate_j - inf_j

* Main financial integration measure: real interest rate convergence.
gen real_ir_diff = -abs(real_rate_i - real_rate_j)

rangestat (mean) fi_real_ir_ma12 = real_ir_diff ///
          (count) n_fi12 = real_ir_diff, ///
          interval(date -11 0) by(pair_id)

replace fi_real_ir_ma12 = . if n_fi12 < 12

label var inf_i "Inflation rate of country i, YoY (%)"
label var inf_j "Inflation rate of country j, YoY (%)"
label var real_rate_i "Real interest rate of country i (%)"
label var real_rate_j "Real interest rate of country j (%)"

label var real_ir_diff "Real interest rate convergence: -abs(real_i - real_j)"
label var fi_real_ir_ma12 "Financial integration, real IR convergence, 12-quarter MA"

// --------------------------------------------------------------------------
// 4. Industrial Structural Difference: Krugman Specialisation Index
// --------------------------------------------------------------------------

rangestat (mean) KSI_ma12 = KSI ///
          (count) n_ksi12 = KSI, ///
          interval(date -11 0) by(pair_id)

replace KSI_ma12 = . if n_ksi12 < 12

label var KSI "Krugman Specialisation Index, raw"
label var KSI_ma12 "Krugman Specialisation Index, 12-quarter moving average"

// --------------------------------------------------------------------------
// 5. Merge 12-Quarter Dependent Variables
// --------------------------------------------------------------------------

merge 1:1 pair date using "rolling_corrs_final_long_12q.dta"

tab _merge

keep if _merge == 3
drop _merge

// --------------------------------------------------------------------------
// 6. Keep and Rename Variables for Final Regressions
// --------------------------------------------------------------------------

keep pair pair_id date year qtr ///
     corr_output corr_inflation corr_er ///
     trade_ma12 fi_real_ir_ma12 KSI_ma12

rename trade_ma12        trade
rename fi_real_ir_ma12   fin_real
rename KSI_ma12          structure

// --------------------------------------------------------------------------
// 7. Final Sample Restriction
// --------------------------------------------------------------------------

keep if !missing(corr_output, corr_inflation, corr_er, ///
                 trade, fin_real, structure)
				 
// --------------------------------------------------------------------------
// 8. Standardise Explanatory Variables
// --------------------------------------------------------------------------

foreach x in trade fin_real structure {
    egen z_`x' = std(`x')
}

// --------------------------------------------------------------------------
// 9. Variable Labels
// --------------------------------------------------------------------------

label var pair "Country pair"
label var pair_id "Country-pair ID"
label var date "Quarter"

label var corr_output ///
    "Output shock synchronisation (12-quarter rolling correlation)"

label var corr_inflation ///
    "Inflation shock synchronisation (12-quarter rolling correlation)"

label var corr_er ///
    "REER shock synchronisation (12-quarter rolling correlation)"

label var trade ///
    "Trade integration (12-quarter moving average)"

label var fin_real ///
    "Financial integration: real interest rate convergence (12-quarter MA)"

label var structure ///
    "Industrial structural difference (Krugman Specialisation Index, 12-quarter MA)"

label var z_trade ///
    "Trade integration, standardised"
	
label var z_fin_real ///
    "Financial integration, real IR convergence, standardised"

label var z_structure ///
    "Structural difference, standardised"
	
// --------------------------------------------------------------------------
// 10. Save Final 12-Quarter Robustness Dataset
// --------------------------------------------------------------------------

xtset pair_id date

compress

save "Final_Analysis_Data_12q.dta", replace

