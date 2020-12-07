do `c(pwd)'/analysis/global.do
* Open a log file

cap log close
log using $logdir\st_set, replace t

use $outdir/analysis_dataset_ps, clear

* Note that this will throw a probable error for invalid weights 
* This is because we have people with missing exposure in the dataset which we allow to drop at this stage
* Those with missing exposure have missing weights and that's why there's an error 

stset stime_hospitalised_covid, ///
    fail(hospitalised_covid)    ///
    id(patient_id)              ///
    enter(enter_date)           ///
    origin(enter_date)    
save $outdir/analysis_dataset_hospitalised_covid, replace

stset stime_death,      ///
    fail(died_covid)    ///
    id(patient_id)      ///
    enter(enter_date)   ///
    origin(enter_date)     
save $outdir/analysis_dataset_died_covid, replace
