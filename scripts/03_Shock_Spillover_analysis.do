/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 13: Shock Spillover and Synchronisation Analysis
Author: tjdqls0716
Date: 2026-04-25
=========================================================================
*/

// 0. Environment Setup
clear all
set more off

// 1. Load the dataset containing extracted structural shocks (Wide format)
use "Dataset_with_Shocks", clear

// =========================================================================
// Section 1: Output (GDP) Shock Synchronization
// =========================================================================
/* Objective: 
   To examine how closely real economic growth shocks are aligned across 
   the 5 East Asian economies. 
*/

disp "======================================================"
disp "--- Correlation Matrix: GDP (Output) Shocks ---"
disp "======================================================"
// Note: 'star(0.05)' puts an asterisk on correlations significant at the 5% level
// 'sig' displays the exact p-value under the correlation coefficient
pwcorr shock_gdp_kor shock_gdp_chn shock_gdp_jpn shock_gdp_twn shock_gdp_hkg, star(0.05) sig

// =========================================================================
// Section 2: Inflation (CPI) Shock Synchronisation
// =========================================================================
/* Objective: 
   To investigate the co-movement of inflation shocks, highlighting 
   whether domestic price pressures are regionally synchronized.
*/

disp "======================================================"
disp "--- Correlation Matrix: CPI (Inflation) Shocks ---"
disp "======================================================"
pwcorr shock_cpi_kor shock_cpi_chn shock_cpi_jpn shock_cpi_twn shock_cpi_hkg, star(0.05) sig

// =========================================================================
// Section 3: Exchange Rate (REER) Shock Synchronisation
// =========================================================================
/* Objective: 
   To analyze the correlation of real exchange rate shocks, reflecting 
   differences in exchange rate regimes (e.g., Peg in HKG, Interventions in TWN).
*/

disp "======================================================"
disp "--- Correlation Matrix: REER (Exchange Rate) Shocks ---"
disp "======================================================"
pwcorr shock_reer_kor shock_reer_chn shock_reer_jpn shock_reer_twn shock_reer_hkg, star(0.05) sig

// =========================================================================
// Section 4: Time-Varying Synchronisation (Method 1: Sub-period Analysis)
// =========================================================================
/* Objective: 
   To compare shock synchronisation between two sub-periods:
   - Period 1 (Pre-Trade War / GVC Expansion): 2009Q2 - 2016Q4
   - Period 2 (Post-Trade War / Fragmentation): 2017Q1 - 2025Q4
*/

disp " "
disp "======================================================"
disp "   [Period 1: 2009Q2 - 2016Q4] (Pre-Trade War)   "
disp "======================================================"

disp "1. GDP Shocks (Period 1)"
pwcorr shock_gdp_kor shock_gdp_chn shock_gdp_jpn shock_gdp_twn shock_gdp_hkg ///
    if qtr >= yq(2009,2) & qtr <= yq(2016,4), star(0.05) sig

disp "2. CPI Shocks (Period 1)"
pwcorr shock_cpi_kor shock_cpi_chn shock_cpi_jpn shock_cpi_twn shock_cpi_hkg ///
    if qtr >= yq(2009,2) & qtr <= yq(2016,4), star(0.05) sig

disp "3. REER Shocks (Period 1)"
pwcorr shock_reer_kor shock_reer_chn shock_reer_jpn shock_reer_twn shock_reer_hkg ///
    if qtr >= yq(2009,2) & qtr <= yq(2016,4), star(0.05) sig
	
disp " "
disp "======================================================"
disp "   [Period 2: 2017Q1 - 2025Q4] (Post-Trade War)  "
disp "======================================================"

disp "1. GDP Shocks (Period 2)"
pwcorr shock_gdp_kor shock_gdp_chn shock_gdp_jpn shock_gdp_twn shock_gdp_hkg ///
    if qtr >= yq(2017,1) & qtr <= yq(2025,4), star(0.05) sig

disp "2. CPI Shocks (Period 2)"
pwcorr shock_cpi_kor shock_cpi_chn shock_cpi_jpn shock_cpi_twn shock_cpi_hkg ///
    if qtr >= yq(2017,1) & qtr <= yq(2025,4), star(0.05) sig

disp "3. REER Shocks (Period 2)"
pwcorr shock_reer_kor shock_reer_chn shock_reer_jpn shock_reer_twn shock_reer_hkg ///
    if qtr >= yq(2017,1) & qtr <= yq(2025,4), star(0.05) sig

// =========================================================================
// Section 5-1: Time-Varying Synchronisation (Method 2: Rolling Correlation)
// =========================================================================
/* Objective: 
   To visualise the dynamic relationship of key bilateral pairs over time.
   - Window size: 20 quarters (5 years)
*/

// 1. Ensure time series is set
tsset qtr

// 2. Create empty variables to store correlation coefficients (drop if they already exist)
cap drop roll_gdp_kor_chn roll_gdp_kor_jpn roll_gdp_chn_hkg roll_gdp_jpn_twn roll_gdp_kor_twn
gen roll_gdp_kor_chn = .
gen roll_gdp_kor_jpn = .
gen roll_gdp_chn_hkg = .
gen roll_gdp_jpn_twn = .  
gen roll_gdp_kor_twn = . 

// 3. Loop to calculate 20-quarter (5-year) rolling correlations
qui summarize qtr
local start_q = r(min) + 19 
local end_q = r(max)

forvalues t = `start_q' / `end_q' {
    // [1] KOR - CHN (Trade/General)
    qui corr shock_gdp_kor shock_gdp_chn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_gdp_kor_chn = r(rho) if qtr == `t'
    
    // [2] KOR - JPN (Competitors/GVC)
    qui corr shock_gdp_kor shock_gdp_jpn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_gdp_kor_jpn = r(rho) if qtr == `t'
    
    // [3] CHN - HKG (Greater China Block)
    qui corr shock_gdp_chn shock_gdp_hkg if qtr <= `t' & qtr > `t' - 20
    qui replace roll_gdp_chn_hkg = r(rho) if qtr == `t'
    
    // [4] JPN - TWN (Tech Supply Chain)
    qui corr shock_gdp_jpn shock_gdp_twn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_gdp_jpn_twn = r(rho) if qtr == `t'
    
    // [5] KOR - TWN (Tech Supply Chain)
    qui corr shock_gdp_kor shock_gdp_twn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_gdp_kor_twn = r(rho) if qtr == `t'
}

// 4. Plot time-series line chart (5 pairs)
tsline roll_gdp_kor_chn roll_gdp_kor_jpn roll_gdp_chn_hkg roll_gdp_jpn_twn roll_gdp_kor_twn, ///
    title("Dynamic Shock Synchronisation (Output Shocks)", size(medium)) ///
    subtitle("20-Quarter Rolling Correlation") ///
    ytitle("Correlation Coefficient (r)") xtitle("") ///
    legend(label(1 "KOR-CHN") label(2 "KOR-JPN") label(3 "CHN-HKG") ///
           label(4 "JPN-TWN") label(5 "KOR-TWN") rows(2) size(small)) ///
    lpattern(solid dash shortdash dot dash_dot) ///
    lwidth(medium medium medium medium medium) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_gdp_5pairs, replace)
	
// Export graph to image file
graph export "Rolling_Correlation_GDP_5Pairs.png", replace as(png) width(2000)
	
// =========================================================================
// Section 5-2: Time-Varying Synchronisation (Method 2: CPI & REER)
// =========================================================================
/* Objective: 
   To visualise the dynamic relationship of key bilateral pairs over time for nominal and exchange rate shocks.
   - Variables: CPI Shocks, REER Shocks
   - Window size: 20 quarters (5 years)
   - Note: This analysis serves as a robustness/sanity check and is often included in the Appendix.
*/

// 1. Create empty variables for CPI and REER rolling correlations
cap drop roll_cpi_kor_chn roll_cpi_kor_jpn roll_cpi_chn_hkg roll_cpi_jpn_twn roll_cpi_kor_twn
cap drop roll_reer_kor_chn roll_reer_kor_jpn roll_reer_chn_hkg roll_reer_jpn_twn roll_reer_kor_twn

gen roll_cpi_kor_chn = .
gen roll_cpi_kor_jpn = .
gen roll_cpi_chn_hkg = .
gen roll_cpi_jpn_twn = .
gen roll_cpi_kor_twn = .

gen roll_reer_kor_chn = .
gen roll_reer_kor_jpn = .
gen roll_reer_chn_hkg = .
gen roll_reer_jpn_twn = .
gen roll_reer_kor_twn = .

// 2. Loop to calculate 20-quarter rolling correlations for CPI and REER
qui summarize qtr
local start_q = r(min) + 19 
local end_q = r(max)

forvalues t = `start_q' / `end_q' {
    // ---- CPI Correlations ----
    qui corr shock_cpi_kor shock_cpi_chn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_cpi_kor_chn = r(rho) if qtr == `t'
    
    qui corr shock_cpi_kor shock_cpi_jpn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_cpi_kor_jpn = r(rho) if qtr == `t'
    
    qui corr shock_cpi_chn shock_cpi_hkg if qtr <= `t' & qtr > `t' - 20
    qui replace roll_cpi_chn_hkg = r(rho) if qtr == `t'
    
    qui corr shock_cpi_jpn shock_cpi_twn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_cpi_jpn_twn = r(rho) if qtr == `t'
    
    qui corr shock_cpi_kor shock_cpi_twn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_cpi_kor_twn = r(rho) if qtr == `t'

    // ---- REER Correlations ----
    qui corr shock_reer_kor shock_reer_chn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_reer_kor_chn = r(rho) if qtr == `t'
    
    qui corr shock_reer_kor shock_reer_jpn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_reer_kor_jpn = r(rho) if qtr == `t'
    
    qui corr shock_reer_chn shock_reer_hkg if qtr <= `t' & qtr > `t' - 20
    qui replace roll_reer_chn_hkg = r(rho) if qtr == `t'
    
    qui corr shock_reer_jpn shock_reer_twn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_reer_jpn_twn = r(rho) if qtr == `t'
    
    qui corr shock_reer_kor shock_reer_twn if qtr <= `t' & qtr > `t' - 20
    qui replace roll_reer_kor_twn = r(rho) if qtr == `t'
}

// 3. Plot time-series line chart for CPI
tsline roll_cpi_kor_chn roll_cpi_kor_jpn roll_cpi_chn_hkg roll_cpi_jpn_twn roll_cpi_kor_twn, ///
    title("Dynamic Shock Synchronisation (Inflation Shocks)", size(medium)) ///
    subtitle("20-Quarter Rolling Correlation") ///
    ytitle("Correlation Coefficient (r)") xtitle("") ///
    legend(label(1 "KOR-CHN") label(2 "KOR-JPN") label(3 "CHN-HKG") ///
           label(4 "JPN-TWN") label(5 "KOR-TWN") rows(2) size(small)) ///
    lpattern(solid dash shortdash dot dash_dot) ///
    lwidth(medium medium medium medium medium) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_cpi_5pairs, replace)

// Export CPI graph
graph export "Rolling_Correlation_CPI_5Pairs.png", replace as(png) width(2000)

// 4. Plot time-series line chart for REER
tsline roll_reer_kor_chn roll_reer_kor_jpn roll_reer_chn_hkg roll_reer_jpn_twn roll_reer_kor_twn, ///
    title("Dynamic Shock Synchronisation (Exchange Rate Shocks)", size(medium)) ///
    subtitle("20-Quarter Rolling Correlation") ///
    ytitle("Correlation Coefficient (r)") xtitle("") ///
    legend(label(1 "KOR-CHN") label(2 "KOR-JPN") label(3 "CHN-HKG") ///
           label(4 "JPN-TWN") label(5 "KOR-TWN") rows(2) size(small)) ///
    lpattern(solid dash shortdash dot dash_dot) ///
    lwidth(medium medium medium medium medium) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_reer_5pairs, replace)

// Export REER graph
graph export "Rolling_Correlation_REER_5Pairs.png", replace as(png) width(2000)

// =========================================================================
// Section 6: Time-Varying Synchronisation (Method 3: Regional Average)
// =========================================================================
/* Objective: 
   To calculate and visualise the regional average rolling correlation 
   (mean of all 10 bilateral pairs) for GDP, CPI, and REER shocks.
   This provides a single macroeconomic indicator of regional integration.
*/

// 1. Ensure time series is set
tsset qtr

// 2. Create variables for regional averages
cap drop avg_roll_gdp avg_roll_cpi avg_roll_reer
gen avg_roll_gdp = .
gen avg_roll_cpi = .
gen avg_roll_reer = .

// 3. Loop to calculate correlations for all 10 pairs and take the average
qui summarize qtr
local start_q = r(min) + 19 
local end_q = r(max)

forvalues t = `start_q' / `end_q' {
    // Temporary scalars to store sums
    scalar sum_gdp = 0
    scalar sum_cpi = 0
    scalar sum_reer = 0
    
    // Define the 5 countries
    local countries "kor chn jpn twn hkg"
    
    // Nested loop for 10 unique pairs (combinations of 5 countries)
    local n 1
    foreach c1 of local countries {
        local m 1
        foreach c2 of local countries {
            if `m' > `n' {
                // GDP Correlation
                qui corr shock_gdp_`c1' shock_gdp_`c2' if qtr <= `t' & qtr > `t' - 20
                scalar sum_gdp = sum_gdp + r(rho)
                
                // CPI Correlation
                qui corr shock_cpi_`c1' shock_cpi_`c2' if qtr <= `t' & qtr > `t' - 20
                scalar sum_cpi = sum_cpi + r(rho)
                
                // REER Correlation
                qui corr shock_reer_`c1' shock_reer_`c2' if qtr <= `t' & qtr > `t' - 20
                scalar sum_reer = sum_reer + r(rho)
            }
            local m = `m' + 1
        }
        local n = `n' + 1
    }
    
    // Calculate average (divide by 10) and assign to variables
    qui replace avg_roll_gdp = sum_gdp / 10 if qtr == `t'
    qui replace avg_roll_cpi = sum_cpi / 10 if qtr == `t'
    qui replace avg_roll_reer = sum_reer / 10 if qtr == `t'
}

// 4. Plot the final integrated regional average chart
tsline avg_roll_gdp avg_roll_cpi avg_roll_reer, ///
    title("Regional Shock Synchronisation in Northeast Asia", size(medium)) ///
    subtitle("Average of 10 Bilateral Pairs (20-Quarter Rolling Window)") ///
    ytitle("Average Correlation Coefficient (r)") xtitle("") ///
    legend(label(1 "Output Shocks (Real)") label(2 "Inflation Shocks (Nominal)") ///
           label(3 "Exchange Rate Shocks") rows(1) size(small)) ///
    lpattern(solid dash shortdash) ///
    lcolor(navy maroon forest_green) ///
    lwidth(thick thick thick) ///
    yline(0, lcolor(gs10) lpattern(dot)) ///
    name(rolling_average_all, replace)
	
// Export the final graph
graph export "Rolling_Average_Regional_Sync.png", replace as(png) width(2000)

// =========================================================================
// Section 7: Trend Regression with Structural Break (COVID-19 Impact)
// =========================================================================
/* Objective: 
   To test for a structural break in the dynamic synchronisation trend post-COVID-19.
   Variables defined:
   - t_trend: Pre-trend (base linear time trend)
   - post2020: Level shift after 2020Q1 (intercept change)
   - t_post: Post-trend change (slope change after 2020Q1)
   
   * Note: Newey-West standard errors (HAC) are applied with a lag of 4 quarters to robustly control for the severe autocorrelation inherently generated by the 20-quarter overlapping rolling windows.
*/

// 1. Drop variables if they already exist to avoid errors during multiple runs
cap drop t_trend post2020 t_post

// 2. Generate time trend and structural break dummy variables
gen t_trend = _n                        // Linear time trend index (1, 2, 3...)
gen post2020 = (qtr >= yq(2020,1))      // Dummy: 1 if 2020Q1 or later, 0 otherwise
gen t_post = t_trend * post2020         // Interaction term for slope shift

// 3. Execute Newey-West regressions
disp " "
disp "======================================================"
disp "  [GDP] Structural Break Trend Regression"
disp "======================================================"
newey avg_roll_gdp t_trend post2020 t_post, lag(4)

disp " "
disp "======================================================"
disp "  [CPI] Structural Break Trend Regression"
disp "======================================================"
newey avg_roll_cpi t_trend post2020 t_post, lag(4)

disp " "
disp "======================================================"
disp "  [REER] Structural Break Trend Regression"
disp "======================================================"
newey avg_roll_reer t_trend post2020 t_post, lag(4)
