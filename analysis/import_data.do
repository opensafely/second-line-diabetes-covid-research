do `c(pwd)'/analysis/global.do

cap log close
log using $logdir/import_data, replace t

import delimited $outdir/input.csv, clear

********* EXPOSURE VARIABLE *********

rename exposure exposure_temp
encode exposure_temp, generate(exposure)
drop exposure_temp

********* CREATE VARIABLES *********

** Sex
gen     male = 1 if sex == "M"
replace male = 0 if sex == "F"


** Ethnicity 
replace ethnicity = .u if ethnicity == .
label define ethnicity  1 "White"           ///
                        2 "Mixed"           ///
                        3 "South Asian"     ///
                        4 "Black"           ///
                        5 "Other"           ///
                        .u "Unknown"
label values ethnicity ethnicity


** STP 
rename stp stp_temp
encode stp_temp, generate(stp)
drop stp_temp


** Region
rename region region_temp
encode region_temp, generate(region)
drop region_temp

** IMD
* Group into 5 groups
rename imd imd_temp
egen imd = cut(imd_temp), group(5) icodes
* add one to create groups 1 - 5 
replace imd = imd + 1
* Reverse the order (so high is more deprived)
recode imd 5 = 1 4 = 2 3 = 3 2 = 4 1 = 5 .u = .u
label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" .u "Unknown"
label values imd imd 
drop imd_temp

* Check there are no missing ages
assert age < .

* Create restricted cubic splines for age
mkspline age = age, cubic nknots(4)


** BMI
* Recode strange values 
replace bmi = . if !inrange(bmi, 15, 50)

gen     bmicat = .
recode  bmicat . = 1 if bmi < 18.5
recode  bmicat . = 2 if bmi < 25
recode  bmicat . = 3 if bmi < 30
recode  bmicat . = 4 if bmi < 35
recode  bmicat . = 5 if bmi < 40
recode  bmicat . = 6 if bmi < .
replace bmicat  = .u if bmi >= .

label define bmicat 1 "Underweight (<18.5)"     ///
                    2 "Normal (18.5-24.9)"      ///
                    3 "Overweight (25-29.9)"    ///
                    4 "Obese I (30-34.9)"       ///
                    5 "Obese II (35-39.9)"      ///
                    6 "Obese III (40+)"         ///
                    .u "Unknown (.u)"
label values bmicat bmicat


** Smoking 
gen     smoke = 1  if smoking_status == "N"
replace smoke = 2  if smoking_status == "E"
replace smoke = 3  if smoking_status == "S"
replace smoke = .u if smoking_status == "M"
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"
label values smoke smoke
drop smoking_status

* Create non-missing 3-category variable for current smoking
* Assumes missing smoking is never smoking 
recode smoke .u = 1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke


** eGFR
* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 

* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min = .
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen     max = .
replace max = SCr_adj/0.7 if male==0
replace max = SCr_adj/0.9 if male==1
replace max = max^-1.209
replace max = 1 if max>1

gen     egfr = min*max*141
replace egfr = egfr*(0.993^age)
replace egfr = egfr*1.018 if male==0
label var egfr "eGFR calculated using CKD-EPI formula with no eth"

* Categorise into ckd stages
egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat 0 = 5 15 = 4 30 = 3 45 = 2 60 = 0, generate(ckd_egfr)

* Add in end stage renal failure and create a single CKD variable 
* Missing assumed to not have CKD 
gen     ckd = 0
replace ckd = 1 if ckd_egfr != . & ckd_egfr >= 1
replace ckd = 1 if esrf == 1

label define ckd 0 "No CKD" 1 "CKD"
label values ckd ckd
label var ckd "CKD stage calc without eth"


** HbA1c
* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage <= 0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0

* Express all values as percentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen     hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)

* Group HbA1c
gen     hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
tab hba1ccat

* Delete unneeded variables
drop hba1c_pct hba1c_percentage hba1c_mmol_per_mol

* Other binary variables
foreach var in retinopathy neuropathy cvd {
    recode `var' . = 0
}


********* OUTCOME AND SURVIVAL TIME *********

gen enter_date = date("$indexdate", "YMD")
gen last_data_date = date("$last_data_date", "YMD")
format  enter_date      ///
        last_data_date  ///
        %td

** CONVERT STRINGS TO DATE
foreach var of varlist      ///
    hospitalised_covid_date ///
    died_date_ons           ///
{
    rename `var' `var'_dstr
    gen `var' = date(`var'_dstr, "YMD") 
    order `var', after(`var'_dstr)
    drop `var'_dstr
    format `var' %td
}

* Survival time = last followup date (first: end study, death, or that outcome)
gen stime_hospitalised_covid = min(last_data_date, died_date_ons, hospitalised_covid_date)
gen stime_death              = min(last_data_date, died_date_ons)
format  stime* %td

* If outcome was after censoring occurred, set to zero
recode hospitalised_covid . = 0
recode died_covid         . = 0
replace hospitalised_covid  = 0 if (hospitalised_covid > last_data_date)
replace died_covid          = 0 if (died_date_ons      > last_data_date)

** Label key variables
label var age           "Age"
label var age1          "Age spline 1"
label var age2          "Age spline 2"
label var age3          "Age spline 3"
label var male          "Male"
label var hba1ccat      "HbA1c"
label var imd           "IMD"
label var bmicat        "BMI"
label var smoke_nomiss  "Smoking"
label var ckd           "Chronic kidney disease" 
label var retinopathy   "Retinopathy" 
label var neuropathy    "Neuropathy"
label var cvd           "Cardiovascular disease"
label var region        "Region"
label var stp           "STP"

********* SAVE *********

save $outdir/analysis_dataset, replace

* Close log file 
log close
