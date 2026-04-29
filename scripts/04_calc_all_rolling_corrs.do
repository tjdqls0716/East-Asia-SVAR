/* =============================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 14: Calculating 20-Quarter Rolling Correlations for Supply Shocks
Description: This script calculates bilateral rolling correlations for all 10 country pairs to be used as the dependent variables (Y) in the final panel regression.
Author: tjdqls0716
Date: 2026-04-29
============================================================================= */

// 0. Environment Setup
clear all
set more off

// 1. Load the dataset containing structural shocks (from SVAR step)
// Note: This file should contain shock_gdp_*, shock_cpi_*, shock_reer_* for 5 nations.
use "Structural_Shocks_Base.dta", clear

// 2. Set Time Series Variable
tsset qtr

// =============================================================================
// Section 1: Calculate Rolling Correlations (10 Pairs x 3 Shock Types)// =============================================================================
/* A 20-quarter (5-year) window is used to ensure statistical stability.*/

local countries "chn hkg jpn kor twn"
local types "gdp cpi reer"
local n 1

foreach c1 of local countries {
    local m 1
    foreach c2 of local countries {
        if `m' > `n' {
            foreach v of local types {
                local varname "roll_`v'_`c1'_`c2'"
                cap drop `varname'
                gen `varname' = .

                qui summarize qtr if !missing(shock_`v'_`c1', shock_`v'_`c2')
                local start_q = r(min) + 19
                local end_q = r(max)

                forvalues t = `start_q' / `end_q' {
                    qui count if qtr <= `t' & qtr > `t' - 20 ///
                        & !missing(shock_`v'_`c1', shock_`v'_`c2')

                    if r(N) == 20 {
                        qui corr shock_`v'_`c1' shock_`v'_`c2' ///
                            if qtr <= `t' & qtr > `t' - 20
                        qui replace `varname' = r(rho) if qtr == `t'
                    }
                }
            }
            display "Processing Pair: `c1'-`c2' (GDP, CPI, REER) - Complete"
        }
        local m = `m' + 1
    }
    local n = `n' + 1
}

// =============================================================================
// Section 2: Reshape Data to Long Format for Panel Regression// =============================================================================
/* 'xtreg' requires data where each row is a [Pair + Time] observation. */

// Keep only time and the newly generated rolling variables
keep qtr roll_*

// Reshape from Wide to Long
// This separates the shock type (gdp/cpi/reer) and the country pair identifier
reshape long roll_gdp_ roll_cpi_ roll_reer_, i(qtr) j(pair) string

// Rename variables for intuitive merging and regression
rename roll_gdp_  corr_output
rename roll_cpi_  corr_inflation
rename roll_reer_ corr_er
rename qtr date

// Label variables for the final dataset documentation
label var corr_output    "20-Qtr Rolling Correlation: GDP (Supply) Shocks"
label var corr_inflation "20-Qtr Rolling Correlation: CPI (Inflation) Shocks"
label var corr_er        "20-Qtr Rolling Correlation: REER Shocks"
label var pair           "Bilateral Pair Identifier"
label var date           "Quarterly Date"

// =============================================================================
// Section 3: Export and Save// =============================================================================

// Save as Stata dataset for the next step (Merge & Regression)
save "rolling_corrs_final_long.dta", replace
