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
// Section 2: Inflation (CPI) Shock Synchronization
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
// Section 3: Exchange Rate (REER) Shock Synchronization
// =========================================================================
/* Objective: 
   To analyze the correlation of real exchange rate shocks, reflecting 
   differences in exchange rate regimes (e.g., Peg in HKG, Interventions in TWN).
*/

disp "======================================================"
disp "--- Correlation Matrix: REER (Exchange Rate) Shocks ---"
disp "======================================================"
pwcorr shock_reer_kor shock_reer_chn shock_reer_jpn shock_reer_twn shock_reer_hkg, star(0.05) sig