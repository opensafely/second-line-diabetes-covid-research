* Adapted from https://github.com/opensafely/ics-research/blob/454f673d317843e9498f9b18ada65abd7ec59aa4/analysis/06b_an_ps_models_asthma.do

do `c(pwd)'/analysis/global.do
global outcome `1'
global tableoutcome `2'


cap log close
log using $logdir/ps_model_$outcome, replace t

use $outdir/analysis_dataset_ps, clear

* Note that this will throw a probable error for invalid weights 
* This is because we have people with missing exposure in the dataset which we allow to drop at this stage
* Those with missing exposure have missing weights and that's why there's an error 
stset stime_$outcome,   ///
    fail($outcome)      ///
    id(patient_id)      ///
    enter(enter_date)   ///
    origin(enter_date)

* Sense check outcomes
tab exposure $outcome, missing row

* Cox model
stcox i.exposure, vce(robust)
estimates save $outdir/univar, replace 


**** Print the results to a table ****
cap file close tablecontent
file open tablecontent using $tabfigdir/table2_$outcome.txt, write text replace
* Column headings 
file write tablecontent ( ///
    "Table 2 - Association between second-line T2DM drug use and COVID-19 $tableoutcome" ///
    ) _n
file write tablecontent _tab ("HR") _tab ("95% CI") _n              
* Row headings 
local lab1: label exposure 1
local lab2: label exposure 2
local lab3: label exposure 3
* Row 1
file write tablecontent ("`lab1'") _tab
file write tablecontent ("1.00 (ref)") _tab _n
* Row 2
file write tablecontent ("`lab2'") _tab  
estimates use $outdir/univar 
lincom 2.exposure, eform
file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n
* Row 3
file write tablecontent ("`lab3'") _tab  
lincom 3.exposure, eform
file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n

file close tablecontent

log close
