/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 15: Construction of Indicators
Author: tjdqls0716
Date: 2026-04-25
=========================================================================*/

/* DESCRIPTION:
   This script calculates the bilateral Trade Integration index between 5 economies.
   Formula: TI_ij = (Exports_ij + Exports_ji) / (GDP_i + GDP_j)
   A 20-quarter rolling average is applied to remove seasonality and capture structural trends.
*/

clear all
set more off

* 0. Load Dataset
*---------------------------------------------------------------------------
* Ensure the working directory is set correctly before running
import excel "Regression Indicators (regressors)", sheet("Sheet1") firstrow clear

*============================================================================
* 1. Date and panel setup
*============================================================================

gen date = yq(year, qtr)
format date %tq

egen pair_id = group(pair)
xtset pair_id date

*============================================================================
* 2. Trade Integration: strict 20-quarter moving average
*============================================================================

rangestat (mean) trade_ma20 = trade_raw ///
          (count) n_trade20 = trade_raw, ///
          interval(date -19 0) by(pair_id)

replace trade_ma20 = . if n_trade20 < 20

label var trade_raw  "Bilateral trade integration, raw"
label var trade_ma20 "Bilateral trade integration, 20-quarter MA"

*============================================================================
* 3. Financial Integration: real interest rate differential
*============================================================================

* YoY inflation
gen inf_i = ((cpi_i - L4.cpi_i) / L4.cpi_i) * 100
gen inf_j = ((cpi_j - L4.cpi_j) / L4.cpi_j) * 100

* Real interest rates
gen real_rate_i = nom_rate_i - inf_i
gen real_rate_j = nom_rate_j - inf_j

* Real interest rate differential
* Higher value = more financially integrated, because smaller absolute gap is closer to zero
gen real_ir_diff = -abs(real_rate_i - real_rate_j)

rangestat (mean) fi_real_ir_ma20 = real_ir_diff ///
          (count) n_fi20 = real_ir_diff, ///
          interval(date -19 0) by(pair_id)

replace fi_real_ir_ma20 = . if n_fi20 < 20

label var inf_i "Inflation rate of country i, YoY (%)"
label var inf_j "Inflation rate of country j, YoY (%)"
label var real_rate_i "Real interest rate of country i (%)"
label var real_rate_j "Real interest rate of country j (%)"
label var real_ir_diff "Real interest rate differential: -abs(real_i - real_j)"
label var fi_real_ir_ma20 "Financial integration, real IR differential, 20-quarter MA"

* nominal interest rate differential (for robustness check)

gen nom_ir_diff = -abs(nom_rate_i - nom_rate_j)
local w = 20
rangestat (mean) fi_nom_ir_ma20 = nom_ir_diff ///
          (count) n_nom_fi20 = nom_ir_diff, ///
          interval(date -19 0) by(pair_id)
replace fi_nom_ir_ma20 = . if n_nom_fi20 < `w'

*============================================================================
* 4. Industrial Structure: Krugman Specialisation Index
*============================================================================

* KSI should be higher when industrial structures are more different
rangestat (mean) KSI_ma20 = KSI ///
          (count) n_ksi20 = KSI, ///
          interval(date -19 0) by(pair_id)

replace KSI_ma20 = . if n_ksi20 < 20

label var KSI "Krugman Specialisation Index, raw"
label var KSI_ma20 "Krugman Specialisation Index, 20-quarter MA"

*============================================================================
* 5. Merge dependent variables: rolling shock correlations
*============================================================================

merge 1:1 pair date using "rolling_corrs_final_long.dta"

keep if _merge == 3
drop _merge

*======================================================
* 6. Keep only variables needed for final regressions
*======================================================

keep pair pair_id date year qtr ///
     corr_output corr_inflation corr_er ///
     trade_ma20 fi_real_ir_ma20 fi_nom_ir_ma20 KSI_ma20

*======================================================
* 7. Rename variables
*======================================================

rename trade_ma20        trade_integration
rename fi_real_ir_ma20   fin_integration
rename KSI_ma20          structural_difference

rename fi_nom_ir_ma20    fin_integration_nom

*======================================================
* 8. Variable labels
*======================================================

label var pair "Country pair"
label var pair_id "Country-pair ID"
label var date "Quarter"

label var corr_output ///
"Output shock synchronisation (20-quarter rolling correlation)"

label var corr_inflation ///
"Inflation shock synchronisation (20-quarter rolling correlation)"

label var corr_er ///
"REER shock synchronisation (20-quarter rolling correlation)"

label var trade_integration ///
"Trade integration (20-quarter moving average)"

label var fin_integration ///
"Financial integration: real interest rate convergence (20-quarter MA)"

label var structural_difference ///
"Industrial structural difference (Krugman Specialisation Index, 20-quarter MA)"

* Ensure balanced sample for all models (Academic standard)
keep if !missing(corr_output, corr_inflation, corr_er, ///
                trade_integration, fin_integration, fin_integration_nom,  structural_difference)

egen z_trade = std(trade_integration)
egen z_fin = std(fin_integration)
egen z_structure = std(structural_difference)
egen z_fin_nom = std(fin_integration_nom)

* Save the cleaned final dataset for regression
save "Final_Analysis_Data.dta", replace
