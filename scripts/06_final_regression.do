/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 6: Final Panel Regression and Robustness Checks
Author: tjdqls0716
Date: 2026-04-29

Description:
This script estimates the final panel regressions linking bilateral shock
synchronisation to trade integration, financial integration, and industrial
structural difference.

Main dependent variables:
    1. corr_output
    2. corr_inflation
    3. corr_er

Main explanatory variables:
    1. z_trade
    2. z_fin
    3. z_structure

Preferred specification:
    Pair fixed effects + time fixed effects, with Driscoll-Kraay standard errors.

Robustness checks:
    1. Specification without time fixed effects
    2. 12-quarter rolling/moving window
    3. Nominal interest rate convergence as alternative financial integration
    4. Excluding the COVID period
    5. Four-quarter lagged regressors
    6. Excluding Hong Kong pairs
========================================================================= */

// --------------------------------------------------------------------------
// 0. Environment Setup
// --------------------------------------------------------------------------

clear all
set more off

use "Final_Analysis_Data.dta", clear

* Panel setup: pair-quarter panel
xtset pair_id date

// --------------------------------------------------------------------------
// 1. Descriptive Statistics
// --------------------------------------------------------------------------

estpost summarize corr_output corr_inflation corr_er ///
                  trade fin_real fin_nom structure 

esttab using "table_descriptive.rtf", ///
    cells("mean sd min max") ///
    title("Descriptive Statistics") ///
    replace

// --------------------------------------------------------------------------
// 2. Hausman Tests: FE versus RE
// --------------------------------------------------------------------------

/*
The Hausman tests are reported as diagnostic checks. The preferred model uses
country-pair fixed effects because bilateral country-pair relationships are
likely to contain time-invariant unobserved heterogeneity.
*/

* Output synchronisation
xtreg corr_output z_trade z_fin_real z_structure i.date, fe
estimates store fe_output

xtreg corr_output z_trade z_fin_real z_structure i.date, re
estimates store re_output

hausman fe_output re_output, sigmamore

* Inflation synchronisation
xtreg corr_inflation z_trade z_fin_real z_structure i.date, fe
estimates store fe_inflation

xtreg corr_inflation z_trade z_fin_real z_structure i.date, re
estimates store re_inflation

hausman fe_inflation re_inflation, sigmamore


* REER synchronisation
xtreg corr_er z_trade z_fin_real z_structure i.date, fe
estimates store fe_er

xtreg corr_er z_trade z_fin_real z_structure i.date, re
estimates store re_er

hausman fe_er re_er, sigmamore

// --------------------------------------------------------------------------
// 3. Main Specification: Pair FE + Time FE
// --------------------------------------------------------------------------

/*
Preferred specification:

    corr_{ij,t} = beta1 * Trade_{ij,t}
                + beta2 * Finance_{ij,t}
                + beta3 * Structure_{ij,t}
                + pair fixed effects
                + time fixed effects
                + error_{ij,t}

Driscoll-Kraay standard errors are used to account for heteroskedasticity,
serial correlation, and cross-sectional dependence.
*/

xtscc corr_output z_trade z_fin_real z_structure i.date, fe lag(4)
estimates store main_output

xtscc corr_inflation z_trade z_fin_real z_structure i.date, fe lag(4)
estimates store main_inflation

xtscc corr_er z_trade z_fin_real z_structure i.date, fe lag(4)
estimates store main_er

esttab main_output main_inflation main_er using "table_main_xtscc_timefe.rtf", ///
    replace ///
	b(4) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Main Results: Pair FE and Time FE, Driscoll-Kraay SEs") ///
    mtitles("Output" "Inflation" "REER") ///
    keep(z_trade z_fin_real z_structure) ///
    order(z_trade z_fin_real z_structure) ///
    stats(N, labels("Observations"))

// --------------------------------------------------------------------------
// 4. Robustness Check 1: Without Time Fixed Effects
// --------------------------------------------------------------------------

/*
This specification is used to assess whether the baseline results are driven by common time-series components. Removing time fixed effects leaves common global and regional shocks in the model.
*/

xtscc corr_output z_trade z_fin_real z_structure, fe lag(4)
estimates store notime_output

xtscc corr_inflation z_trade z_fin_real z_structure, fe lag(4)
estimates store notime_inflation

xtscc corr_er z_trade z_fin_real z_structure, fe lag(4)
estimates store notime_er

esttab notime_output notime_inflation notime_er using "table_robust_no_timefe.rtf", ///
    replace ///
	b(4) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness 1: Pair FE without Time FE") ///
    mtitles("Output" "Inflation" "REER") ///
    keep(z_trade z_fin_real z_structure) ///
    order(z_trade z_fin_real z_structure) ///
    stats(N, labels("Observations"))
	
// --------------------------------------------------------------------------
// 5. Robustness Check 2: 12-Quarter Rolling/Moving Window
// --------------------------------------------------------------------------

/*
This robustness check uses the 12-quarter robustness dataset.

In this dataset:
    Dependent variables = 12-quarter rolling shock correlations
    Explanatory variables = 12-quarter moving averages

This file is generated by:
    04b_calc_all_rolling_corrs_12q.do
    05b_integration_indicators_12q.do
*/

capture confirm file "Final_Analysis_Data_12q.dta"

if !_rc {
	 preserve

    use "Final_Analysis_Data_12q.dta", clear
    xtset pair_id date
	
	xtscc corr_output z_trade z_fin_real z_structure i.date, fe lag(4)
    estimates store q12_output

    xtscc corr_inflation z_trade z_fin_real z_structure i.date, fe lag(4)
    estimates store q12_inflation

    xtscc corr_er z_trade z_fin_real z_structure i.date, fe lag(4)
    estimates store q12_er
	
	 esttab q12_output q12_inflation q12_er using"table_robust_12q_window.rtf", ///
        replace ///
		b(4) se(3) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        title("Robustness 2: 12-Quarter Rolling/Moving Window") ///
        mtitles("Output" "Inflation" "REER") ///
        keep(z_trade z_fin_real z_structure) ///
        order(z_trade z_fin_real z_structure) ///
        stats(N, labels("Observations"))

    restore
}

// --------------------------------------------------------------------------
// 6. Robustness Check 3: Nominal Interest Rate Convergence
// --------------------------------------------------------------------------

/*
This robustness check replaces the real interest rate convergence measure with
nominal interest rate convergence.
*/

xtscc corr_output z_trade z_fin_nom z_structure i.date, fe lag(4)
estimates store nom_output

xtscc corr_inflation z_trade z_fin_nom z_structure i.date, fe lag(4)
estimates store nom_inflation

xtscc corr_er z_trade z_fin_nom z_structure i.date, fe lag(4)
estimates store nom_er

esttab nom_output nom_inflation nom_er using "table_robust_nominal_ir.rtf", ///
    replace ///
	b(4) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness 3: Nominal Interest Rate Convergence") ///
    mtitles("Output" "Inflation" "REER") ///
    keep(z_trade z_fin_nom z_structure) ///
    order(z_trade z_fin_nom z_structure) ///
    stats(N, labels("Observations"))
	
// --------------------------------------------------------------------------
// 7. Robustness Check 4: Excluding COVID Period
// --------------------------------------------------------------------------

/*
The COVID period is excluded to check whether the results are driven by the
extraordinary shock between 2020Q1 and 2021Q4.
*/

capture drop is_covid
gen is_covid = (date >= yq(2020,1) & date <= yq(2021,4))

xtscc corr_output z_trade z_fin_real z_structure i.date if is_covid == 0, fe lag(4)
estimates store nocovid_output

xtscc corr_inflation z_trade z_fin_real z_structure i.date if is_covid == 0, fe lag(4)
estimates store nocovid_inflation

xtscc corr_er z_trade z_fin_real z_structure i.date if is_covid == 0, fe lag(4)
estimates store nocovid_er

esttab nocovid_output nocovid_inflation nocovid_er using "table_robust_no_covid.rtf", ///
    replace ///
	b(4) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness 4: Excluding COVID Period") ///
    mtitles("Output" "Inflation" "REER") ///
    keep(z_trade z_fin_real z_structure) ///
    order(z_trade z_fin_real z_structure) ///
    stats(N, labels("Observations"))
	
// --------------------------------------------------------------------------
// 8. Robustness Check 5: Four-Quarter Lagged Regressors
// --------------------------------------------------------------------------

/*
This robustness check uses four-quarter lagged regressors to reduce concerns
about contemporaneous reverse causality.
*/

xtscc corr_output L4.z_trade L4.z_fin_real L4.z_structure i.date, fe lag(4)
estimates store lag_output

xtscc corr_inflation L4.z_trade L4.z_fin_real L4.z_structure i.date, fe lag(4)
estimates store lag_inflation

xtscc corr_er L4.z_trade L4.z_fin_real L4.z_structure i.date, fe lag(4)
estimates store lag_er

esttab lag_output lag_inflation lag_er using "table_robust_lagged_regressors.rtf", ///
    replace ///
	b(4) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness 5: Four-Quarter Lagged Regressors") ///
    mtitles("Output" "Inflation" "REER") ///
    keep(L4.z_trade L4.z_fin_real L4.z_structure) ///
    order(L4.z_trade L4.z_fin_real L4.z_structure) ///
    stats(N, labels("Observations"))
	
// --------------------------------------------------------------------------
// 9. Robustness Check 6: Excluding Hong Kong Pairs
// --------------------------------------------------------------------------

/*
Hong Kong is excluded because its exchange-rate arrangement and financial
structure are distinct from the other economies in the sample.
*/

capture drop is_hkg
gen is_hkg = strpos(pair, "hkg") > 0

xtscc corr_output z_trade z_fin_real z_structure i.date if is_hkg == 0, fe lag(4)
estimates store nohkg_output

xtscc corr_inflation z_trade z_fin_real z_structure i.date if is_hkg == 0, fe lag(4)
estimates store nohkg_inflation

xtscc corr_er z_trade z_fin_real z_structure i.date if is_hkg == 0, fe lag(4)
estimates store nohkg_er

esttab nohkg_output nohkg_inflation nohkg_er using "table_robust_no_hkg.rtf", ///
    replace ///
	b(4) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness 6: Excluding Hong Kong Pairs") ///
    mtitles("Output" "Inflation" "REER") ///
    keep(z_trade z_fin_real z_structure) ///
    order(z_trade z_fin_real z_structure) ///
    stats(N, labels("Observations"))