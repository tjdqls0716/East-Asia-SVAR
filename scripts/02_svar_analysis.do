/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 5: SVAR Estimation with Global Controls (Enhanced Model)
Author: tjdqls0716
Date: 2026-04-23 (Updated)
=========================================================================
*/

// 0. Load the Integrated Dataset
// Make sure to point to the correct path if you moved the file to the 'data/' folder
use "data/final_panel_v2.dta", clear

// -------------------------------------------------------------------------
// 1. Structural Identification Strategy (A & B Matrices)
// -------------------------------------------------------------------------
/* We employ the Cholesky Decomposition (Recursive Identification) to identify 
   structural shocks. The ordering of variables is based on their relative 
   sluggishness in responding to economic news:
   
   Ordering: dl_gdp -> dl_cpi -> dl_reer
   
   - dl_gdp: Most exogenous; does not respond contemporaneously to other shocks.
   - dl_cpi: Responds to output shocks within the same quarter, but not to REER.
   - dl_reer: Most endogenous; responds immediately to both output and price shocks.
*/

// A Matrix: Contemporaneous relations among endogenous variables
// (1s on the diagonal, 0s for restrictions, '.' for coefficients to be estimated)
matrix Amat = (1, 0, 0 \ ///
               ., 1, 0 \ ///
               ., ., 1)
			   
// B Matrix: Structural shocks (diagonal matrix assuming orthogonal shocks)
matrix Bmat = (., 0, 0 \ ///
               0, ., 0 \ ///
               0, 0, .)

// -------------------------------------------------------------------------
// 2. SVAR Estimation for South Korea (Country ID: 1) with Global Controls
// -------------------------------------------------------------------------
/* Estimation Details:
   - Sample: South Korea (id == 1)
   - Lags: 4 (Determined by SBIC/HQIC criteria in Part 1)
   - Exogenous: s1, s2, s3 (Seasonal dummies to control for quarterly effects) + fedfunds, ln_vix (Global Factors)
*/
	 
svar dl_gdp dl_cpi dl_reer if country_id==1, ///
     lags(1/4) ///
     exog(s1 s2 s3 fedfunds ln_vix) /// 
     aeq(Amat) beq(Bmat)
	 
// Note: Signs of coefficients in Matrix A should be reversed for interpretation due to the form Ay = B*e.

// -------------------------------------------------------------------------
// Part 6: Impulse Response Function (IRF) Analysis
// -------------------------------------------------------------------------
/* Objective: 
   To visualise the dynamic responses of inflation (CPI) and exchange rates (REER) to a structural shock in output growth (GDP).
   
   Settings:
   - File: 'skorea' results are stored in the 'myirf' dataset.
   - Horizon: 12 quarters (3 years) to capture the medium-term transmission.
   - Confidence Interval: 95% (shaded area).
*/

// [1] Create and save the IRF results for South Korea
irf create skorea, set(myirf) step(12) replace

// [2] Generate the IRF Graph with professional formatting
/* Formatting details:
   - 'sirf': Uses Structural IRF based on our A & B matrices.
   - 'xlabel': Displays ticks every 2 quarters for better readability up to step 12.
   - 'yrescale': Allows each subplot to have its own optimal Y-axis scale.
*/
* 1. GDP -> CPI 
irf graph sirf, impulse(dl_gdp) response(dl_cpi) ///
    individual ///
	xlabel(0(2)12) xtitle("Quarters after Shock") ///
    ytitle("Response of CPI") ///
    title("Response: Output Shock to CPI (South Korea)", size(medium)) ///
    subtitle("") ///
	note("") // 
graph export "irf_korea_gdp_cpi.png", replace as(png) width(2000)

* 2. GDP -> REER 
irf graph sirf, impulse(dl_gdp) response(dl_reer) ///
    individual ///
	xlabel(0(2)12) xtitle("Quarters after Shock") ///
    ytitle("Response of REER") ///
    title("Response: Output Shock to REER (South Korea)", size(medium)) ///
    subtitle("") ///
    note("")
graph export "irf_korea_gdp_reer.png", replace as(png) width(2000)

* 3. CPI -> REER 
irf graph sirf, impulse(dl_cpi) response(dl_reer) ///
    individual ///
	xlabel(0(2)12) xtitle("Quarters after Shock") ///
    ytitle("Response of REER") ///
    title("Response: Inflation Shock to REER (South Korea)") ///
    subtitle("") note("")
graph export "irf_korea_cpi_reer.png", replace as(png) width(2000)

// ------------------------------------------------------------------------
// Part 7: Variance Decomposition (FEVD) (FEVD)
// ------------------------------------------------------------------------
/* Objective: 
   To quantify the relative importance of structural shocks (GDP, CPI, REER) 
   in explaining the variance of each macroeconomic variable over a 12-quarter horizon,
   after controlling for global exogenous factors.
*/

// [1] FEVD of REER: To what extent do domestic fundamentals drive the exchange rate?
irf table fevd, impulse(dl_gdp dl_cpi dl_reer) response(dl_reer) step(12)

// [2] FEVD of CPI: Is inflation driven by demand-pull (GDP) or imported inflation (REER)?
irf table fevd, impulse(dl_gdp dl_cpi dl_reer) response(dl_cpi) step(12)

// [3] FEVD of GDP: How independent is domestic growth from nominal and external shocks?
irf table fevd, impulse(dl_gdp dl_cpi dl_reer) response(dl_gdp) step(12)

// =========================================================================
// Part 8: SVAR Estimation for China (Country ID: 2)
// =========================================================================
/* Consistent with the South Korean model, we maintain the same:
   - Identification: Cholesky (Recursive)
   - Global Controls: fedfunds, ln_vix
   - Lags: 4
*/

svar dl_gdp dl_cpi dl_reer if country_id==2, ///
     lags(1/4) ///
     exog(s1 s2 s3 fedfunds ln_vix) /// 
     aeq(Amat) beq(Bmat)
	 
// --- IRF and FEVD for China ---
irf create china, set(myirf) step(12) replace
**"Repeat the same graphing procedure as South Korea"**

// =========================================================================
// Part 9: SVAR Estimation for Japan (Country ID: 3)
// =========================================================================
/* Consistent with the South Korean model, we maintain the same:
   - Identification: Cholesky (Recursive)
   - Global Controls: fedfunds, ln_vix
   - Lags: 4
*/

svar dl_gdp dl_cpi dl_reer if country_id==3, ///
     lags(1/4) ///
     exog(s1 s2 s3 fedfunds ln_vix) /// 
     aeq(Amat) beq(Bmat)
	 
// --- IRF and FEVD for China ---
irf create japan, set(myirf) step(12) replace
**"Repeat the same graphing procedure as South Korea"**

// =========================================================================
// Part 10: SVAR Estimation for Taiwan (Country ID: 4)
// =========================================================================
/* Consistent with the South Korean model, we maintain the same:
   - Identification: Cholesky (Recursive)
   - Global Controls: fedfunds, ln_vix
   - Lags: 4
*/

svar dl_gdp dl_cpi dl_reer if country_id==4, ///
     lags(1/4) ///
     exog(s1 s2 s3 fedfunds ln_vix) /// 
     aeq(Amat) beq(Bmat)
	 
// --- IRF and FEVD for China ---
irf create taiwan, set(myirf) step(12) replace
**"Repeat the same graphing procedure as South Korea"**

// =========================================================================
// Part 11: SVAR Estimation for HongKong (Country ID: 5)
// =========================================================================
/* Consistent with the South Korean model, we maintain the same:
   - Identification: Cholesky (Recursive)
   - Global Controls: fedfunds, ln_vix
   - Lags: 4
*/

svar dl_gdp dl_cpi dl_reer if country_id==5, ///
     lags(1/4) ///
     exog(s1 s2 s3 fedfunds ln_vix) /// 
     aeq(Amat) beq(Bmat)
	 
// --- IRF and FEVD for China ---
irf create hongkong, set(myirf) step(12) replace
**"Repeat the same graphing procedure as South Korea"**

// =========================================================================
// Part 12: Structural Shock Extraction & Reshaping (For Spillover Analysis)
// =========================================================================
/* Objective: 
   1. Extract structural shocks (e_t) from reduced-form residuals (u_t) for all 5 countries.
   2. Reshape the dataset from Long to Wide format so countries align on the same 'date' row.
   3. Save as a new dataset for Correlation/Spillover analysis.
*/

// 1. Create generic variables for the shocks
gen shock_gdp = .
gen shock_cpi = .
gen shock_reer = .

// 2. Loop through all 5 countries to extract shocks
// (1:KOR, 2:CHN, 3:JPN, 4:TWN, 5:HKG)
forvalues i = 1/5 {
    // Silently estimate SVAR for each country
    quietly svar dl_gdp dl_cpi dl_reer if country_id==`i', ///
         lags(1/4) exog(s1 s2 s3 fedfunds ln_vix) aeq(Amat) beq(Bmat) 
		 // Predict reduced-form residuals
    quietly predict u_gdp if e(sample), res eq(dl_gdp)
    quietly predict u_cpi if e(sample), res eq(dl_cpi)
    quietly predict u_reer if e(sample), res eq(dl_reer)
    
    // Extract matrices and calculate Transformation Matrix T = B^-1 * A
    matrix A_est = e(A)
    matrix B_est = e(B)
    matrix T = inv(B_est) * A_est
    
    // Generate structural shocks using matrix algebra (e_t = T * u_t)
    quietly replace shock_gdp = T[1,1]*u_gdp + T[1,2]*u_cpi + T[1,3]*u_reer if e(sample)
    quietly replace shock_cpi = T[2,1]*u_gdp + T[2,2]*u_cpi + T[2,3]*u_reer if e(sample)
    quietly replace shock_reer = T[3,1]*u_gdp + T[3,2]*u_cpi + T[3,3]*u_reer if e(sample)
    
    // Drop temporary residuals for the next loop iteration
    drop u_gdp u_cpi u_reer
}

// 3. Keep ONLY the variables needed for correlation analysis
keep qtr country_id shock_gdp shock_cpi shock_reer

// 4. Reshape data from Long to Wide format
// (This puts all countries' shocks on the same row for the same date)
reshape wide shock_gdp shock_cpi shock_reer, i(qtr) j(country_id)

// 5. Rename variables for easy identification
// Output Shocks
rename shock_gdp1 shock_gdp_kor
rename shock_gdp2 shock_gdp_chn
rename shock_gdp3 shock_gdp_jpn
rename shock_gdp4 shock_gdp_twn
rename shock_gdp5 shock_gdp_hkg

// Inflation Shocks
rename shock_cpi1 shock_cpi_kor
rename shock_cpi2 shock_cpi_chn
rename shock_cpi3 shock_cpi_jpn
rename shock_cpi4 shock_cpi_twn
rename shock_cpi5 shock_cpi_hkg

// Exchange Rate Shocks
rename shock_reer1 shock_reer_kor
rename shock_reer2 shock_reer_chn
rename shock_reer3 shock_reer_jpn
rename shock_reer4 shock_reer_twn
rename shock_reer5 shock_reer_hkg

// 6. Sanity Check
summ shock_gdp*
summ shock_cpi*
summ shock_reer*

matrix list e(A)
matrix list e(B)

// 7. Save the final dataset 
save "Dataset_with_Shocks.dta", replace
