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



