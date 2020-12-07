do `c(pwd)'/analysis/global.do
* Open a log file

cap log close
log using $logdir/derive_ps, replace t

use $outdir/analysis_dataset, clear

/* PS Model===================================================================*/

mlogit exposure i.male age1 age2 age3 $varlist, base(1)
predict p1 p2 p3, pr 

bysort exposure: summarize p1 
bysort exposure: summarize p2 
bysort exposure: summarize p3 

gen check = p1 + p2 + p3 
summarize check 

* Check PS distribution 
* Main interest is for p2, but also of interest to plot the other probabilities 

* Plot and export graphs of the PS distribution 
graph twoway kdensity p1 if exposure == 1 || ///
             kdensity p1 if exposure == 2 || ///
             kdensity p1 if exposure == 3, ///
                graphregion(fcolor(white)) ///
                legend(size(small) ///
                label(1 "P1 - DPP4i") ///
                label (2 "P1 - SGLT2i") ///
                label (3 "P1 - Sulfonylurea") ///
                region(lwidth(none))) 

graph export $tabfigdir/psplot1.svg, as(svg) replace
graph close

graph twoway kdensity p2 if exposure == 1 || ///
             kdensity p2 if exposure == 2 || ///
             kdensity p2 if exposure == 3, ///
                graphregion(fcolor(white)) ///
                legend(size(small) ///
                label(1 "P2 - DPP4i") ///
                label (2 "P2 - SGLT2i") ///
                label (3 "P2 - Sulfonylurea") ///
                region(lwidth(none))) 

graph export $tabfigdir/psplot2.svg, as(svg) replace
graph close

graph twoway kdensity p3 if exposure == 1 || ///
             kdensity p3 if exposure == 2 || ///
             kdensity p3 if exposure == 3, ///
                graphregion(fcolor(white)) ///
                legend(size(small) ///
                label(1 "P3 - DPP4i") ///
                label (2 "P3 - SGLT2i") ///
                label (3 "P3 - Sulfonylurea") ///
                region(lwidth(none))) 

graph export $tabfigdir/psplot3.svg, as(svg) replace
graph close

* Estimate and tabulate standardised differences 
* Note, this relies on the stddiff ado, provided in the repo. 
* Because 3 level treatment, compare both against baseline, so need to create indicators for this

gen exposure2v1 = 0 if exposure == 1 
replace exposure2v1 = 1 if exposure == 2 

gen exposure3v1 = 0 if exposure == 1 
replace exposure3v1 = 1 if exposure == 3 

local lab1: label exposure 1
local lab2: label exposure 2
local lab3: label exposure 3

cap file close tablecontent
file open tablecontent using $tabfigdir/table_stddiff.txt, write text replace

file write tablecontent ("Table S1: Standardised differences before weighting") _n
file write tablecontent ("Variable") _tab ("SD - `lab2' vs `lab1'") _tab ("SD - `lab3' vs `lab1'") _n 

*Gender

local lab: variable label male 
file write tablecontent ("`lab'") _tab
tab exposure2v1
stddiff i.male, by(exposure2v1)
file write tablecontent (r(stddiff)[1,1]) _tab

stddiff i.male, by(exposure3v1)
file write tablecontent (r(stddiff)[1,1]) _n 

*Age

local lab: variable label age
file write tablecontent ("`lab'") _tab

stddiff age, by(exposure2v1)
file write tablecontent (r(stddiff)[1,1]) _tab

stddiff age, by(exposure3v1)
file write tablecontent (r(stddiff)[1,1]) _n 
    
* All other things 

foreach comorb in $varlist {

    local comorb: subinstr local comorb "i." ""
    local lab: variable label `comorb'
    file write tablecontent ("`lab'") _tab
    
    stddiff `comorb', by(exposure2v1)
    file write tablecontent (r(stddiff)[1,1]) _tab 
    
    stddiff `comorb', by(exposure3v1)
    file write tablecontent (r(stddiff)[1,1]) _n                 
}

file close tablecontent

/* Create weights=============================================================*/

* ATE weights 
gen ipw = 1/p1 if exposure == 1 
replace ipw = 1/p2 if exposure == 2 
replace ipw = 1/p3 if exposure == 3 

summarize ipw, d

/* Check overlap and standardised differences in the weighted sample==========*/

* Plot and export graphs of the PS distribution 
* Left graph export for now for same reason as above 
* Adapt probability weights to frequency weights to use in graphs
* These need to be rounded up for sufficient granularity 

gen ipw_f = round(ipw*100) 

* Plots in the weighted populations 

graph twoway kdensity p1 if exposure == 1  [fw = ipw_f] || ///
             kdensity p1 if exposure == 2  [fw = ipw_f] || ///
             kdensity p1 if exposure == 3  [fw = ipw_f], ///
                graphregion(fcolor(white)) ///
                legend(size(small) ///
                label(1 "P1 - DPP4i") ///
                label (2 "P1 - SGLT2i") ///
                label (3 "P1 - Sulfonylurea") ///
                region(lwidth(none))) 

graph export $tabfigdir/psplot4.svg, as(svg) replace
graph close

graph twoway kdensity p2 if exposure == 1  [fw = ipw_f]|| ///
             kdensity p2 if exposure == 2  [fw = ipw_f]|| ///
             kdensity p2 if exposure == 3  [fw = ipw_f], ///
                graphregion(fcolor(white)) ///
                legend(size(small) ///
                label(1 "P2 - DPP4i") ///
                label (2 "P2 - SGLT2i") ///
                label (3 "P2 - Sulfonylurea") ///
                region(lwidth(none))) 

graph export $tabfigdir/psplot5.svg, as(svg) replace
graph close

graph twoway kdensity p3 if exposure == 1  [fw = ipw_f]|| ///
             kdensity p3 if exposure == 2  [fw = ipw_f]|| ///
             kdensity p3 if exposure == 3  [fw = ipw_f], ///
                graphregion(fcolor(white)) ///
                legend(size(small) ///
                label(1 "P3 - DPP4i") ///
                label (2 "P3 - SGLT2i") ///
                label (3 "P3 - Sulfonylurea") ///
                region(lwidth(none))) 

graph export $tabfigdir/psplot6.svg, as(svg) replace
graph close


* Estimate and tabulate standardised differences 
* Note, this required amending the stddiff ado file 
* The amended file is saved as Weighted STDs and called before calculating these 
* The weights are frequency weights used above and in a variable called 'wts'

gen wts = ipw_f

run "analysis/Weighted STDs.do" 

cap file close tablecontent
file open tablecontent using $tabfigdir/table_stddiff2.txt, write text replace

file write tablecontent ("Table S2: Standardised differences after weighting - ATE") _n
file write tablecontent ("Variable") _tab ("SD - `lab2' vs `lab1'") _tab ("SD - `lab3` vs `lab1'") _n 

*Gender

local lab: variable label male 
file write tablecontent ("`lab'") _tab
tab exposure2v1
stddiff2 i.male, by(exposure2v1)
file write tablecontent (r(stddiff)[1,1]) _tab

stddiff2 i.male, by(exposure3v1)
file write tablecontent (r(stddiff)[1,1]) _n 

*Age

local lab: variable label age
file write tablecontent ("`lab'") _tab

stddiff2 age, by(exposure2v1)
file write tablecontent (r(stddiff)[1,1]) _tab

stddiff2 age, by(exposure3v1)
file write tablecontent (r(stddiff)[1,1]) _n 
    
* All other things 

foreach comorb in $varlist {

    local comorb: subinstr local comorb "i." ""
    local lab: variable label `comorb'
    file write tablecontent ("`lab'") _tab
    
    stddiff2 `comorb', by(exposure2v1)
    file write tablecontent (r(stddiff)[1,1]) _tab 
    
    stddiff2 `comorb', by(exposure3v1)
    file write tablecontent (r(stddiff)[1,1]) _n                 
}

file close tablecontent

/* Output weighted dataset for analyses=======================================*/

save $outdir/analysis_dataset_ps, replace

* Close log file 
log close
