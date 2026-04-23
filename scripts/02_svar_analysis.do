/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 5: SVAR Estimation and Identification Strategy
Author: tjdqls0716
Date: 2026-04-23
=========================================================================
*/

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
// 2. SVAR Estimation for South Korea (Country ID: 1)
// -------------------------------------------------------------------------
/* Estimation Details:
   - Sample: South Korea (id == 1)
   - Lags: 4 (Determined by SBIC/HQIC criteria in Part 1)
   - Exogenous: s1, s2, s3 (Seasonal dummies to control for quarterly effects)
*/

svar dl_gdp dl_cpi dl_reer if country_id==1, ///
     lags(1/4) ///
     exog(s1 s2 s3) ///
     aeq(Amat) beq(Bmat)
	 
// Note: Signs of coefficients in Matrix A should be reversed for interpretation due to the form Ay = B*e.

// -------------------------------------------------------------------------
// Part 3: Impulse Response Function (IRF) Analysis
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
    title("Response: GDP Shock to CPI (South Korea)", size(medium)) ///
    subtitle("") ///
	note("") // 
graph export "irf_korea_gdp_cpi.png", replace as(png) width(2000)

* 2. GDP -> REER 
irf graph sirf, impulse(dl_gdp) response(dl_reer) ///
    individual ///
	xlabel(0(2)12) xtitle("Quarters after Shock") ///
    ytitle("Response of REER") ///
    title("Response: GDP Shock to REER (South Korea)", size(medium)) ///
    subtitle("") ///
    note("")
graph export "irf_korea_gdp_reer.png", replace as(png) width(2000)

* 3. CPI -> REER 
irf graph sirf, impulse(dl_cpi) response(dl_reer) ///
    individual ///
	xlabel(0(2)12) xtitle("Quarters after Shock") ///
    ytitle("Response of REER") ///
    title("Response: CPI Shock to REER (South Korea)") ///
    subtitle("") note("")
graph export "irf_korea_cpi_reer.png", replace as(png) width(2000)

