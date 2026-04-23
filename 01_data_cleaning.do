/*
Project: Structural VAR (SVAR) Analysis of East Asian Economies
Part 1: Data Cleaning and Variable Transformation
Author: tjdqls0716
Date: 2026-04-23

Description: 
This script imports the raw Excel data, sets the panel time-series 
structure, and generates log-transformed and first-differenced variables 
for Real GDP, CPI, and REER.
*/

clear all
import excel "PPE Macrodata.xlsx", sheet("Sheet1") firstrow clear

**Data Cleaning**
*1. Set Time series
gen qtr = quarterly(quarter, "YQ")
format qtr %tq
xtset country_id qtr

*2. Log Transformation
gen l_gdp = ln(real_gdp)
gen l_cpi = ln(cpi)
gen l_reer = ln(reer)

*3. Difference
gen dl_gdp = d.l_gdp
gen dl_cpi = d.l_cpi
gen dl_reer = d.l_reer

