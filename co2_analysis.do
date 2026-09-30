* ============================================================
* Economic Growth, Trade, and Foreign Investment as
* Determinants of CO2 Emissions: Panel Data, 173 Countries, 1990-2010
* Author: Diksha Agrawal (NYU Wagner)
* Data: World Bank World Development Indicators (WDI)
* ============================================================

clear all
set more off

* ---- set your own folder paths here ----
global datadir "path/to/your/data"
global logdir  "path/to/your/output"

log using "$logdir/co2_analysis.smcl", replace

use "$datadir/country dataset with 2010 version 13 _3_ (8).dta", clear


* ---- data cleaning ----
codebook year, compact

encode cn, gen(country_id)
xtset country_id year

* logs
gen ln_co2       = ln(co2_em)
gen ln_exp       = ln(exp_gds_srv)
gen ln_imp       = ln(imp_gds_srv)
gen ln_gdpcap    = ln(gdpcap)
gen ln_gdpcap_sq = ln_gdpcap^2
gen ln_tot_pop   = ln(tot_pop)
gen ln_fdi       = ln(abs(for_dir_invst))

lab var ln_co2       "ln(CO2 emissions per capita)"
lab var ln_fdi       "ln(|FDI net inflows|)"
lab var ln_exp       "ln(Exports, % of GDP)"
lab var ln_imp       "ln(Imports, % of GDP)"
lab var ln_gdpcap    "ln(GDP per capita)"
lab var ln_gdpcap_sq "ln(GDP per capita) squared"
lab var ln_tot_pop   "ln(Total population)"


* ---- part 1: descriptives ----
sum ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop
tabstat co2_em, s(mean sd min max count) by(year)
corr ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_tot_pop
* gdp & co2 correlated at 0.85, as expected


* ---- part 2: diagnostics ----

* heteroskedasticity
reg ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop
estat imtest, white
estat hettest

* multicollinearity
vif

* hausman: fixed vs random effects
xtreg ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop, fe
est store fe_hausman
xtreg ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop, re
est store re_hausman
hausman fe_hausman re_hausman, sigmamore
* rejects RE, going with FE


* ---- part 3: regressions ----

* m1: pooled OLS with robust SEs
reg ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop, robust
est store M1_rob

* m2: country FE, SEs clustered by country
areg ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop, ///
    absorb(country_id) vce(cluster country_id)
est store M2_rob

* m3: country + year FE, SEs clustered by country (preferred)
areg ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop i.year, ///
    absorb(country_id) vce(cluster country_id)
est store M3_rob

* side by side
est table M1_rob M2_rob M3_rob, ///
    keep(ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop _cons) ///
    b(%9.4f) star(0.10 0.05 0.01) stats(N r2 r2_a F)


* ---- figures ----

* fig1: gdp per capita vs co2
scatter ln_co2 ln_gdpcap
graph export "$logdir/fig1.png", replace

* fig2: EKC with quadratic fit (main plot)
tw (scatter ln_co2 ln_gdpcap) (qfit ln_co2 ln_gdpcap)
graph export "$logdir/fig2.png", replace

* fig3: residuals vs fitted from m3
qui areg ln_co2 ln_fdi ln_exp ln_imp ln_gdpcap ln_gdpcap_sq ln_tot_pop i.year, ///
    absorb(country_id) vce(cluster country_id)
predict yhat
predict resid, res
scatter resid yhat, yline(0)
graph export "$logdir/fig3.png", replace

* fig4: residual histogram
hist resid, normal
graph export "$logdir/fig4.png", replace

log close
