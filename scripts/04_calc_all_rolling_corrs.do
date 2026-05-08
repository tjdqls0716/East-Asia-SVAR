/* =============================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 4: Calculating 20-Quarter Rolling Correlations for Structural Shocks
Author: tjdqls0716
Date: 2026-04-29

Description:
This script calculates 20-quarter bilateral rolling correlations for all 10
country pairs and three structural shock types: output, inflation, and REER
shocks. The resulting long-format dataset is used as the dependent-variable
dataset in the final panel regression analysis.

Input:
    Dataset_with_Shocks.dta

Output:
    rolling_corrs_final_long.dta
============================================================================= */

// --------------------------------------------------------------------------
// 0. Environment Setup
// --------------------------------------------------------------------------

clear all
set more off

// Load structural shocks extracted from the SVAR step.
use "Dataset_with_Shocks.dta", clear

// Keep only variables required for rolling-correlation construction.
keep qtr shock_gdp_* shock_cpi_* shock_reer_*

format qtr %tq
tsset qtr

// --------------------------------------------------------------------------
// 1. Calculate Rolling Correlations: 10 Pairs x 3 Shock Types
// --------------------------------------------------------------------------

/*
A 20-quarter rolling window is used. For each endpoint t, the window covers
t-19 to t, equivalent to five years of quarterly observations.
*/

local countries "chn hkg jpn kor twn"
local types "gdp cpi reer"
local window = 20

local n = 1

foreach c1 of local countries {
    local m = 1

    foreach c2 of local countries {

        if `m' > `n' {

            foreach v of local types {

                local varname "roll_`v'_`c1'_`c2'"

                cap drop `varname'
                gen `varname' = .

                quietly summarize qtr if !missing(shock_`v'_`c1', shock_`v'_`c2'), meanonly
                local start_q = r(min) + `window' - 1
                local end_q   = r(max)

                forvalues t = `start_q' / `end_q' {

                    quietly count if qtr >= `t' - `window' + 1 & qtr <= `t' ///
                        & !missing(shock_`v'_`c1', shock_`v'_`c2')

                    if r(N) == `window' {
                        quietly corr shock_`v'_`c1' shock_`v'_`c2' ///
                            if qtr >= `t' - `window' + 1 & qtr <= `t'

                        quietly replace `varname' = r(rho) if qtr == `t'
                    }
                }
            }

            display "Processing Pair: `c1'-`c2' complete"
        }

        local m = `m' + 1
    }

    local n = `n' + 1
}


// --------------------------------------------------------------------------
// 2. Reshape Data to Long Format for Panel Regression
// --------------------------------------------------------------------------

/*
The final panel regression requires one observation per pair-quarter.
The reshape command converts variables such as:

    roll_gdp_chn_hkg
    roll_cpi_chn_hkg
    roll_reer_chn_hkg

into a long-format row identified by pair = "chn_hkg".
*/

keep qtr roll_*

reshape long roll_gdp_ roll_cpi_ roll_reer_, i(qtr) j(pair) string

rename roll_gdp_  corr_output
rename roll_cpi_  corr_inflation
rename roll_reer_ corr_er
rename qtr date

label var corr_output    "20-Qtr Rolling Correlation: Output Shocks"
label var corr_inflation "20-Qtr Rolling Correlation: Inflation Shocks"
label var corr_er        "20-Qtr Rolling Correlation: REER Shocks"
label var pair           "Bilateral Pair Identifier"
label var date           "Quarterly Date"

format date %tq

order pair date corr_output corr_inflation corr_er
sort pair date

// --------------------------------------------------------------------------
// 3. Save Final Long-Format Rolling Correlation Dataset
// --------------------------------------------------------------------------

save "rolling_corrs_final_long.dta", replace
