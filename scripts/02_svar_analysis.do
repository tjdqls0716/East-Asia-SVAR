/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 2: SVAR Estimation, IRF/FEVD Analysis, and Structural Shock Extraction
Author: tjdqls0716
Date: 2026-04-23

Description:
This script estimates country-specific SVAR models using the cleaned panel
dataset. The SVAR is identified using a recursive Cholesky structure with the
ordering:

    dl_gdp -> dl_cpi -> dl_reer

Global financial controls and seasonal dummies are included as exogenous
variables. The script generates impulse response functions, forecast error
variance decompositions, and extracts structural shocks for subsequent
synchronisation analysis.
========================================================================= */

clear all
set more off

// --------------------------------------------------------------------------
// 0. Load Cleaned Dataset
// --------------------------------------------------------------------------

use "final_panel_v2.dta", clear

* Check country ID mapping before estimation
tab country_id

* Panel declaration
xtset country_id qtr

// --------------------------------------------------------------------------
// 1. Structural Identification: Recursive Cholesky Ordering
// --------------------------------------------------------------------------

* Ordering: output growth -> inflation -> REER change
matrix Amat = (1, 0, 0 \ ///
               ., 1, 0 \ ///
               ., ., 1)

matrix Bmat = (., 0, 0 \ ///
               0, ., 0 \ ///
               0, 0, .)

// --------------------------------------------------------------------------
// 2. SVAR Estimation, IRFs, and FEVDs
// --------------------------------------------------------------------------

irf set myirf, replace

local countries "skorea china japan taiwan hongkong"
local ids       "1 2 3 4 5"
local labels    `" "South Korea" "China" "Japan" "Taiwan" "Hong Kong" "'

forvalues k = 1/5 {

    local id     : word `k' of `ids'
    local cname  : word `k' of `countries'
    local clabel : word `k' of `labels'

    di "=================================================="
    di "Estimating SVAR for `clabel'"
    di "Country ID = `id'"
    di "=================================================="

    svar dl_gdp dl_cpi dl_reer if country_id == `id', ///
        lags(1/4) ///
        exog(s1 s2 s3 fedfunds ln_vix) ///
        aeq(Amat) beq(Bmat)

    * Create structural IRFs with bootstrap confidence intervals.
    set seed 12345
    irf create `cname', step(12) replace bs reps(500)

    * Selected IRF tables.
    irf table sirf, irf(`cname') impulse(dl_gdp) response(dl_cpi) step(12)
    irf table sirf, irf(`cname') impulse(dl_gdp) response(dl_reer) step(12)
    irf table sirf, irf(`cname') impulse(dl_cpi) response(dl_reer) step(12)

    * Individual IRF graph: output shock to CPI.
    irf graph sirf, irf(`cname') impulse(dl_gdp) response(dl_cpi) ///
        individual xlabel(0(2)12) ///
        xtitle("Quarters after Shock") ///
        ytitle("Response of CPI") ///
        title("Response of CPI to Output Shock: `clabel'", size(medium)) ///
        subtitle("") note("")
    graph export "irf_`cname'_gdp_cpi.png", replace as(png) width(2000)

    * Individual IRF graph: output shock to REER.
    irf graph sirf, irf(`cname') impulse(dl_gdp) response(dl_reer) ///
        individual xlabel(0(2)12) ///
        xtitle("Quarters after Shock") ///
        ytitle("Response of REER") ///
        title("Response of REER to Output Shock: `clabel'", size(medium)) ///
        subtitle("") note("")
    graph export "irf_`cname'_gdp_reer.png", replace as(png) width(2000)

    * Individual IRF graph: inflation shock to REER.
    irf graph sirf, irf(`cname') impulse(dl_cpi) response(dl_reer) ///
        individual xlabel(0(2)12) ///
        xtitle("Quarters after Shock") ///
        ytitle("Response of REER") ///
        title("Response of REER to Inflation Shock: `clabel'", size(medium)) ///
        subtitle("") note("")
    graph export "irf_`cname'_cpi_reer.png", replace as(png) width(2000)

    * FEVD tables.
    irf table fevd, irf(`cname') ///
        impulse(dl_gdp dl_cpi dl_reer) response(dl_reer) step(12)

    irf table fevd, irf(`cname') ///
        impulse(dl_gdp dl_cpi dl_reer) response(dl_cpi) step(12)

    irf table fevd, irf(`cname') ///
        impulse(dl_gdp dl_cpi dl_reer) response(dl_gdp) step(12)
}

// --------------------------------------------------------------------------
// 3. Overlay IRF Graphs Across Countries
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// 3.1 Output Shock to CPI
// --------------------------------------------------------------------------

preserve

use "myirf.irf", clear
keep if inlist(irfname, "skorea", "china", "japan", "taiwan", "hongkong")

keep if impulse == "dl_gdp" & response == "dl_cpi"

twoway ///
    (line sirf step if irfname=="china",    sort lpattern(solid)) ///
    (line sirf step if irfname=="hongkong", sort lpattern(dash)) ///
    (line sirf step if irfname=="japan",    sort lpattern(shortdash)) ///
    (line sirf step if irfname=="skorea",   sort lcolor(orange) lpattern(longdash)) ///
    (line sirf step if irfname=="taiwan",   sort lpattern(dash_dot)), ///
    xtitle("Quarters after Shock", size(medsmall)) ///
    ytitle("Response of CPI", size(medsmall)) ///
    xlabel(0(2)12) ///
    yline(0, lpattern(dash) lcolor(gs8)) ///
    legend(order(1 "China" 2 "Hong Kong" 3 "Japan" 4 "Korea" 5 "Taiwan") ///
           position(6) ring(1) rows(2) size(small) region(lstyle(none))) ///
    graphregion(margin(small)) ///
    plotregion(margin(small)) ///
    xsize(8) ysize(5.5)

graph export "overlay_irf_gdp_cpi.png", replace as(png) width(2000)

restore

// --------------------------------------------------------------------------
// 3.2 Output Shock to REER
// --------------------------------------------------------------------------

preserve

use "myirf.irf", clear
keep if inlist(irfname, "skorea", "china", "japan", "taiwan", "hongkong")

keep if impulse == "dl_gdp" & response == "dl_reer"

twoway ///
    (line sirf step if irfname=="china",    sort lpattern(solid)) ///
    (line sirf step if irfname=="hongkong", sort lpattern(dash)) ///
    (line sirf step if irfname=="japan",    sort lpattern(shortdash)) ///
    (line sirf step if irfname=="skorea",   sort lcolor(orange) lpattern(longdash)) ///
    (line sirf step if irfname=="taiwan",   sort lpattern(dash_dot)), ///
    xtitle("Quarters after Shock", size(medsmall)) ///
    ytitle("Response of REER", size(medsmall)) ///
    xlabel(0(2)12) ///
    yline(0, lpattern(dash) lcolor(gs8)) ///
    legend(order(1 "China" 2 "Hong Kong" 3 "Japan" 4 "Korea" 5 "Taiwan") ///
           position(6) ring(1) rows(2) size(small) region(lstyle(none))) ///
    graphregion(margin(small)) ///
    plotregion(margin(small)) ///
    xsize(8) ysize(5.5)

graph export "overlay_irf_gdp_reer.png", replace as(png) width(2000)

restore

// --------------------------------------------------------------------------
// 3.3 Inflation Shock to REER
// --------------------------------------------------------------------------

preserve

use "myirf.irf", clear
keep if inlist(irfname, "skorea", "china", "japan", "taiwan", "hongkong")

keep if impulse == "dl_cpi" & response == "dl_reer"

twoway ///
    (line sirf step if irfname=="china",    sort lpattern(solid)) ///
    (line sirf step if irfname=="hongkong", sort lpattern(dash)) ///
    (line sirf step if irfname=="japan",    sort lpattern(shortdash)) ///
    (line sirf step if irfname=="skorea",   sort lcolor(orange) lpattern(longdash)) ///
    (line sirf step if irfname=="taiwan",   sort lpattern(dash_dot)), ///
    xtitle("Quarters after Shock", size(medsmall)) ///
    ytitle("Response of REER", size(medsmall)) ///
    xlabel(0(2)12) ///
    yline(0, lpattern(dash) lcolor(gs8)) ///
    legend(order(1 "China" 2 "Hong Kong" 3 "Japan" 4 "Korea" 5 "Taiwan") ///
           position(6) ring(1) rows(2) size(small) region(lstyle(none))) ///
    graphregion(margin(small)) ///
    plotregion(margin(small)) ///
    xsize(8) ysize(5.5)

graph export "overlay_irf_cpi_reer.png", replace as(png) width(2000)

restore

//---------------------------------------------------------------------------
// 4. Structural Shock Extraction
// --------------------------------------------------------------------------

gen shock_gdp  = .
gen shock_cpi  = .
gen shock_reer = .

forvalues i = 1/5 {

    di "=================================================="
    di "Extracting structural shocks for country_id = `i'"
    di "=================================================="

    quietly svar dl_gdp dl_cpi dl_reer if country_id == `i', ///
        lags(1/4) ///
        exog(s1 s2 s3 fedfunds ln_vix) ///
        aeq(Amat) beq(Bmat)

    tempvar u_gdp u_cpi u_reer

    * Reduced-form residuals from each SVAR equation.
    quietly predict `u_gdp'  if e(sample), res eq(dl_gdp)
    quietly predict `u_cpi'  if e(sample), res eq(dl_cpi)
    quietly predict `u_reer' if e(sample), res eq(dl_reer)

    matrix A_est = e(A)
    matrix B_est = e(B)

    * Structural shocks are obtained as e_t = inv(B) * A * u_t.
    matrix T = inv(B_est) * A_est

    quietly replace shock_gdp = ///
        T[1,1]*`u_gdp' + T[1,2]*`u_cpi' + T[1,3]*`u_reer' if e(sample)

    quietly replace shock_cpi = ///
        T[2,1]*`u_gdp' + T[2,2]*`u_cpi' + T[2,3]*`u_reer' if e(sample)

    quietly replace shock_reer = ///
        T[3,1]*`u_gdp' + T[3,2]*`u_cpi' + T[3,3]*`u_reer' if e(sample)
}

// --------------------------------------------------------------------------
// 5. Reshape Structural Shocks to Wide Format
// --------------------------------------------------------------------------

keep qtr country_id shock_gdp shock_cpi shock_reer

reshape wide shock_gdp shock_cpi shock_reer, i(qtr) j(country_id)

* Rename variables according to country_id mapping:
* 1 = South Korea, 2 = China, 3 = Japan, 4 = Taiwan, 5 = Hong Kong.

rename shock_gdp1  shock_gdp_kor
rename shock_gdp2  shock_gdp_chn
rename shock_gdp3  shock_gdp_jpn
rename shock_gdp4  shock_gdp_twn
rename shock_gdp5  shock_gdp_hkg

rename shock_cpi1  shock_cpi_kor
rename shock_cpi2  shock_cpi_chn
rename shock_cpi3  shock_cpi_jpn
rename shock_cpi4  shock_cpi_twn
rename shock_cpi5  shock_cpi_hkg

rename shock_reer1 shock_reer_kor
rename shock_reer2 shock_reer_chn
rename shock_reer3 shock_reer_jpn
rename shock_reer4 shock_reer_twn
rename shock_reer5 shock_reer_hkg


// --------------------------------------------------------------------------
// 6. Summary and Save Final Shock Dataset
// --------------------------------------------------------------------------

summ shock_gdp*
summ shock_cpi*
summ shock_reer*

save "Dataset_with_Shocks.dta", replace
