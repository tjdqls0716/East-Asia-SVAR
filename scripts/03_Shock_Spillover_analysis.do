/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 3: Shock Spillover and Synchronisation Analysis
Author: tjdqls0716
Date: 2026-04-25

Description:
This script analyses the synchronisation of structural shocks extracted from
country-specific SVAR models. It reports static pairwise correlations, compares sub-period correlations, computes rolling bilateral correlations, constructs regional average synchronisation measures, and tests for post-2020 structural breaks using Newey-West standard errors.

Input:
    Dataset_with_Shocks.dta

Output:
    Rolling_Correlation_GDP_5Pairs.png
    Rolling_Correlation_CPI_5Pairs.png
    Rolling_Correlation_REER_5Pairs.png
    Rolling_Average_Regional_Sync.png
    Rolling_Correlations_Descriptive_Wide.dta.dta
========================================================================= */

// --------------------------------------------------------------------------
// 0. Environment Setup
// --------------------------------------------------------------------------

clear all
set more off

use "Dataset_with_Shocks.dta", clear

format qtr %tq
tsset qtr

// --------------------------------------------------------------------------
// 1. Static Shock Synchronisation: Full-Sample Correlations
// --------------------------------------------------------------------------

disp "======================================================"
disp "--- Correlation Matrix: GDP (Output) Shocks ---"
disp "======================================================"

pwcorr shock_gdp_chn shock_gdp_hkg shock_gdp_jpn shock_gdp_kor shock_gdp_twn, star(0.05) sig


disp "======================================================"
disp "--- Correlation Matrix: CPI (Inflation) Shocks ---"
disp "======================================================"

pwcorr shock_cpi_chn shock_cpi_hkg shock_cpi_jpn shock_cpi_kor shock_cpi_twn, star(0.05) sig


disp "======================================================"
disp "--- Correlation Matrix: REER (Exchange Rate) Shocks ---"
disp "======================================================"

pwcorr shock_reer_chn shock_reer_hkg shock_reer_jpn shock_reer_kor shock_reer_twn, star(0.05) sig



// --------------------------------------------------------------------------
// 2. Time-Varying Synchronisation (Method 1: Sub-period Analysis)
// --------------------------------------------------------------------------

/*
Sub-periods:
    Period 1: 2009Q2-2016Q4
    Period 2: 2017Q1-end of available sample

The second period captures the post-trade-war and fragmentation period.
The end date is set dynamically using the available sample.
*/

summ qtr, meanonly
local qmax = r(max)

local p1_start = yq(2009,2)
local p1_end   = yq(2016,4)
local p2_start = yq(2017,1)
local p2_end   = `qmax'

disp " "
disp "======================================================"
disp "   [Period 1: 2009Q2 - 2016Q4]   "
disp "======================================================"

disp "1. GDP Shocks, Period 1"
pwcorr shock_gdp_chn shock_gdp_hkg shock_gdp_jpn shock_gdp_kor shock_gdp_twn if qtr >= `p1_start' & qtr <= `p1_end', star(0.05) sig

disp "2. CPI Shocks, Period 1"
pwcorr shock_cpi_chn shock_cpi_hkg shock_cpi_jpn shock_cpi_kor shock_cpi_twn if qtr >= `p1_start' & qtr <= `p1_end', star(0.05) sig

disp "3. REER Shocks, Period 1"
pwcorr shock_reer_chn shock_reer_hkg shock_reer_jpn shock_reer_kor shock_reer_twn if qtr >= `p1_start' & qtr <= `p1_end', star(0.05) sig
	
disp " "
disp "======================================================"
disp "   [Period 2: 2017Q1 - End of Sample]   "
disp "======================================================"

disp "1. GDP Shocks, Period 2"
pwcorr shock_gdp_chn shock_gdp_hkg shock_gdp_jpn shock_gdp_kor shock_gdp_twn if qtr >= `p2_start' & qtr <= `p2_end', star(0.05) sig

disp "2. CPI Shocks, Period 2"
pwcorr shock_cpi_chn shock_cpi_hkg shock_cpi_jpn shock_cpi_kor shock_cpi_twn if qtr >= `p2_start' & qtr <= `p2_end', star(0.05) sig

disp "3. REER Shocks, Period 2"
pwcorr shock_reer_chn shock_reer_hkg shock_reer_jpn shock_reer_kor shock_reer_twn if qtr >= `p2_start' & qtr <= `p2_end', star(0.05) sig


// --------------------------------------------------------------------------
// 3. Method 2: Rolling Bilateral Correlations: All 10 Country Pairs
// --------------------------------------------------------------------------

/*
Window size:
    20 quarters, equivalent to 5 years.

Countries:
    kor = South Korea
    chn = China
    jpn = Japan
    twn = Taiwan
    hkg = Hong Kong

This section creates rolling correlations for all 10 unique bilateral pairs
for GDP, CPI, and REER structural shocks.
*/

local window = 20
local countries "kor chn jpn twn hkg"

local roll_gdp_list
local roll_cpi_list
local roll_reer_list

* Create rolling-correlation variables for all 10 pairs.
local n = 1
foreach c1 of local countries {
    local m = 1
    foreach c2 of local countries {
        if `m' > `n' {
            
            cap drop roll_gdp_`c1'_`c2'
            cap drop roll_cpi_`c1'_`c2'
            cap drop roll_reer_`c1'_`c2'
            
            gen roll_gdp_`c1'_`c2'  = .
            gen roll_cpi_`c1'_`c2'  = .
            gen roll_reer_`c1'_`c2' = .
            
            local roll_gdp_list  "`roll_gdp_list' roll_gdp_`c1'_`c2'"
            local roll_cpi_list  "`roll_cpi_list' roll_cpi_`c1'_`c2'"
            local roll_reer_list "`roll_reer_list' roll_reer_`c1'_`c2'"
        }
        local m = `m' + 1
    }
    local n = `n' + 1
}


* Define rolling-window range.
summ qtr, meanonly
local start_q = r(min) + `window' - 1
local end_q   = r(max)


* Calculate rolling correlations.
forvalues t = `start_q' / `end_q' {

    local n = 1
    foreach c1 of local countries {
        local m = 1
        foreach c2 of local countries {
            if `m' > `n' {

                * GDP shocks
                quietly count if qtr >= `t' - `window' + 1 & qtr <= `t' ///
                    & !missing(shock_gdp_`c1', shock_gdp_`c2')
                if r(N) >= 4 {
                    quietly corr shock_gdp_`c1' shock_gdp_`c2' ///
                        if qtr >= `t' - `window' + 1 & qtr <= `t'
                    quietly replace roll_gdp_`c1'_`c2' = r(rho) if qtr == `t'
                }

                * CPI shocks
                quietly count if qtr >= `t' - `window' + 1 & qtr <= `t' ///
                    & !missing(shock_cpi_`c1', shock_cpi_`c2')
                if r(N) >= 4 {
                    quietly corr shock_cpi_`c1' shock_cpi_`c2' ///
                        if qtr >= `t' - `window' + 1 & qtr <= `t'
                    quietly replace roll_cpi_`c1'_`c2' = r(rho) if qtr == `t'
                }

                * REER shocks
                quietly count if qtr >= `t' - `window' + 1 & qtr <= `t' ///
                    & !missing(shock_reer_`c1', shock_reer_`c2')
                if r(N) >= 4 {
                    quietly corr shock_reer_`c1' shock_reer_`c2' ///
                        if qtr >= `t' - `window' + 1 & qtr <= `t'
                    quietly replace roll_reer_`c1'_`c2' = r(rho) if qtr == `t'
                }
            }
            local m = `m' + 1
        }
        local n = `n' + 1
    }
}

// --------------------------------------------------------------------------
// 4. Rolling Correlation Graphs: Selected Five Pairs
// --------------------------------------------------------------------------

/*
Selected pairs:
    KOR-CHN: major trade relationship
    KOR-JPN: regional competitors and production-network links
    CHN-HKG: Greater China financial-real linkage
    JPN-TWN: technology supply-chain relationship
    KOR-TWN: semiconductor and technology supply-chain relationship
*/


// 4.1 GDP shock rolling correlations

tsline roll_gdp_kor_chn roll_gdp_kor_jpn roll_gdp_chn_hkg ///
       roll_gdp_jpn_twn roll_gdp_kor_twn, ///
    ytitle("Correlation Coefficient (r)") ///
    xtitle("") ///
    legend(label(1 "KOR-CHN") label(2 "KOR-JPN") label(3 "CHN-HKG") ///
           label(4 "JPN-TWN") label(5 "KOR-TWN") rows(2) size(small)) ///
    lpattern(solid dash shortdash longdash dash_dot) ///
    lwidth(medium medium medium medium medium) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_gdp_5pairs, replace)

graph export "Rolling_Correlation_GDP_5Pairs.png", replace as(png) width(2000)

// 4.2 CPI shock rolling correlations

tsline roll_cpi_kor_chn roll_cpi_kor_jpn roll_cpi_chn_hkg ///
       roll_cpi_jpn_twn roll_cpi_kor_twn, ///
    ytitle("Correlation Coefficient (r)") ///
    xtitle("") ///
    legend(label(1 "KOR-CHN") label(2 "KOR-JPN") label(3 "CHN-HKG") ///
           label(4 "JPN-TWN") label(5 "KOR-TWN") rows(2) size(small)) ///
    lpattern(solid dash shortdash longdash dash_dot) ///
    lwidth(medium medium medium medium medium) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_cpi_5pairs, replace)

graph export "Rolling_Correlation_CPI_5Pairs.png", replace as(png) width(2000)

// 4.3 REER shock rolling correlations

tsline roll_reer_kor_chn roll_reer_kor_jpn roll_reer_chn_hkg ///
       roll_reer_jpn_twn roll_reer_kor_twn, ///
    ytitle("Correlation Coefficient (r)") ///
    xtitle("") ///
    legend(label(1 "KOR-CHN") label(2 "KOR-JPN") label(3 "CHN-HKG") ///
           label(4 "JPN-TWN") label(5 "KOR-TWN") rows(2) size(small)) ///
    lpattern(solid dash shortdash longdash dash_dot) ///
    lwidth(medium medium medium medium medium) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_reer_5pairs, replace)

graph export "Rolling_Correlation_REER_5Pairs.png", replace as(png) width(2000)
	
// --------------------------------------------------------------------------
// 5. Regional Average Rolling Synchronisation
// --------------------------------------------------------------------------

/*
The regional average is calculated as the simple mean of all 10 bilateral
rolling correlations for each shock type.
*/

cap drop avg_roll_gdp avg_roll_cpi avg_roll_reer

unab roll_gdp_list  : roll_gdp_*
unab roll_cpi_list  : roll_cpi_*
unab roll_reer_list : roll_reer_*

egen avg_roll_gdp  = rowmean(`roll_gdp_list')
egen avg_roll_cpi  = rowmean(`roll_cpi_list')
egen avg_roll_reer = rowmean(`roll_reer_list')


tsline avg_roll_gdp avg_roll_cpi avg_roll_reer, ///
    ytitle("Average Correlation Coefficient (r)") ///
    xtitle("") ///
    legend(label(1 "Output Shocks") ///
           label(2 "Inflation Shocks") ///
           label(3 "Exchange Rate Shocks") rows(1) size(small)) ///
    lpattern(solid dash shortdash) ///
    lcolor(navy maroon forest_green) ///
    lwidth(thick thick thick) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_average_all, replace)

graph export "Rolling_Average_Regional_Sync.png", replace as(png) width(2000)
	
// --------------------------------------------------------------------------
// 6. Trend Regression with Structural Break: Post-2020 Shift
// --------------------------------------------------------------------------

/*
Objective: To test whether the regional average synchronisation measure changes after 2020Q1.

Specification:
    avg_roll_x = b0 + b1 * trend + b2 * post2020 + b3 * post-trend + error

Newey-West standard errors are used with four lags to account for serial
correlation induced by overlapping 20-quarter rolling windows.
*/

cap drop t_trend post2020 t_post

summ qtr if !missing(avg_roll_gdp), meanonly
local trend_start = r(min)

gen t_trend = qtr - `trend_start' + 1 if qtr >= `trend_start'
gen post2020 = (qtr >= yq(2020,1)) if qtr >= `trend_start'
gen t_post = t_trend * post2020

disp " "
disp "======================================================"
disp "  [GDP] Structural Break Trend Regression"
disp "======================================================"

newey avg_roll_gdp t_trend post2020 t_post ///
    if !missing(avg_roll_gdp), lag(4)


disp " "
disp "======================================================"
disp "  [CPI] Structural Break Trend Regression"
disp "======================================================"

newey avg_roll_cpi t_trend post2020 t_post ///
    if !missing(avg_roll_cpi), lag(4)


disp " "
disp "======================================================"
disp "  [REER] Structural Break Trend Regression"
disp "======================================================"

newey avg_roll_reer t_trend post2020 t_post ///
    if !missing(avg_roll_reer), lag(4)

// --------------------------------------------------------------------------
// 7. Export Rolling Correlation Dataset
// --------------------------------------------------------------------------

unab roll_gdp_list  : roll_gdp_*
unab roll_cpi_list  : roll_cpi_*
unab roll_reer_list : roll_reer_*

keep qtr `roll_gdp_list' `roll_cpi_list' `roll_reer_list' ///
     avg_roll_gdp avg_roll_cpi avg_roll_reer ///
     t_trend post2020 t_post

save "Rolling_Correlations_Descriptive_Wide.dta", replace
