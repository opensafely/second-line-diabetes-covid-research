********************************************************************************
*
*	Do-file:		000_cr_define_covariates.do
*
*	Programmed by:	John T
*
*	Data used:		input.csv
*
*	Data created:   descriptive_cohort.dta
*
********************************************************************************

clear
do `c(pwd)'/analysis/global.do

local start_date  td(01/09/2020)
local last_year   td(01/09/2019)
local four_years_ago td(01/09/2016)	 
local fifteen_months_ago td(01/06/2019)
local end_date td(01/06/2021)

import delimited $outdir/input.csv

* check population have T2DM
keep if t2dm == 1

gen indexdate = td(01/09/2020)
format indexdate %td

noi safecount

******************************
*  Convert strings to dates  *
******************************
* To be added: dates related to outcomes
foreach var of varlist deregistered	///
					   died_date_ons /// 
					   hospitalised_covid_date ///
					   first_comm_covid_date   {

capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		rename `var' `var'_dstr
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
}

* Process variables with nearest month dates only						
						
foreach var of varlist 	bmi_date_measured 				///
						hba1c_mmol_per_mol_date			///
						hba1c_percentage_date			///
						haem_cancer						///
						lung_cancer						///
						other_cancer					///
						temporary_immunodeficiency		///
						aplastic_anaemia				{
						    confirm string variable `var'
							replace `var' = `var' + "-15"
							rename `var' `var'_dstr
							replace `var'_dstr = " " if `var'_dstr == "-15"
							gen `var'_date = date(`var'_dstr, "YMD") 
							order `var'_date, after(`var'_dstr)
							drop `var'_dstr
							format `var'_date %td
						}

rename bmi_date_measured_date      	bmi_date_measured
rename hba1c_percentage_date_date  	hba1c_percentage_date
rename hba1c_mmol_per_mol_date_date hba1c_mmol_per_mol_date


*******************************
*  Cleaning
*******************************

* The default deregistration date is 9999-12-31, so:
replace deregistered_date = . if deregistered_date > `end_date'

* Note: There may be deaths recorded after end of our study 
* Set these to missing
replace died_date_ons_date = . if died_date_ons_date>`end_date'


*******************************
*  Recode implausible values  *
*******************************

* BMI 

* Only keep if within certain time period? using bmi_date_measured ?
* NB: Some BMI dates in future or after cohort entry

* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)



**********************
*  Recode variables  *
**********************
/* Exposure  */
gen exp = .
replace exp = 1 if exposure == "SGLT2i"
replace exp = 2 if exposure == "DPP4i"
replace exp = 3 if exposure == "Sulfonylureas"
replace exp = 4 if exposure == "Three"
replace exp = 5 if exposure == "Four"

label define exLab 1  "SGLT2i"  2 "DPP4i" 3 "Sulfonylureas" 4  "Three" 5 "Four"
label values exp exLab



/*  Demographics  */

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
drop sex
label define sexLab 1 "male" 0 "female"
label values male sexLab
label var male "sex = 0 F, 1 M"

/*  IMD  */
* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes
replace imd = imd + 1
replace imd = . if imd_o==-1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5=1 4=2 3=3 2=4 1=5 .=.

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" 
label values imd imd 

noi di "DROPPING IF NO IMD" 
drop if imd>=.

* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" 

gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = . if smoking_status=="M"
label values smoke smoke
drop smoking_status


* Ethnicity (5 category)
replace ethnicity = 6 if ethnicity==.
label define ethnicity_lab 	1 "White"  								///
						2 "Mixed" 								///
						3 "Asian or Asian British"				///
						4 "Black"  								///
						5 "Other"								///
						6 "Unknown"
label values ethnicity ethnicity_lab


/*  Geographical location  */

/* Region
rename region region_string
assert inlist(region_string, 								///
					"East Midlands", 						///
					"East",  								///
					"London", 								///
					"North East", 							///
					"North West", 							///
					"South East", 							///
					"South West",							///
					"West Midlands", 						///
					"Yorkshire and The Humber") 
* Nine regions
gen     region_9 = 1 if region_string=="East Midlands"
replace region_9 = 2 if region_string=="East"
replace region_9 = 3 if region_string=="London"
replace region_9 = 4 if region_string=="North East"
replace region_9 = 5 if region_string=="North West"
replace region_9 = 6 if region_string=="South East"
replace region_9 = 7 if region_string=="South West"
replace region_9 = 8 if region_string=="West Midlands"
replace region_9 = 9 if region_string=="Yorkshire and The Humber"

label define region_9 	1 "East Midlands" 					///
						2 "East"   							///
						3 "London" 							///
						4 "North East" 						///
						5 "North West" 						///
						6 "South East" 						///
						7 "South West"						///
						8 "West Midlands" 					///
						9 "Yorkshire and The Humber"
label values region_9 region_9
label var region_9 "Region of England (9 regions)"

* Seven regions
recode region_9 2=1 3=2 1 8=3 4 9=4 5=5 6=6 7=7, gen(region_7)

label define region_7 	1 "East"							///
						2 "London" 							///
						3 "Midlands"						///
						4 "North East and Yorkshire"		///
						5 "North West"						///
						6 "South East"						///	
						7 "South West"
label values region_7 region_7
label var region_7 "Region of England (7 regions)"
drop region_string
*/
	
**************************
*  Categorise variables  *
**************************
/* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old
*/
* Create categorised age
recode 	age 			min/49.9999=1 	///
						50/59.9999=2 	///
						60/69.9999=3 	///
						70/79.9999=4 	///
						80/max=5, 		///
						gen(agegroup) 

label define agegroup 	1 "18-<50" 		///
						2 "50-<60" 		///
						3 "60-<70" 		///
						4 "70-<80" 		///
						5 "80+"
label values agegroup agegroup


* Check there are no missing ages
assert age<.
assert agegroup<.

* Create restricted cubic splines fir age
mkspline age = age, cubic nknots(4)

/*  Body Mass Index  */

* BMI (NB: watch for missingness)
gen 	bmicat = .
recode  bmicat . = 1 if bmi<18.5
recode  bmicat . = 2 if bmi<25
recode  bmicat . = 3 if bmi<30
recode  bmicat . = 4 if bmi<35
recode  bmicat . = 5 if bmi<40
recode  bmicat . = 6 if bmi<.
replace bmicat = . if bmi>=.

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			
					
label values bmicat bmicat


* Create more granular categorisation
recode bmicat 1/3 . = 1 4=2 5=3 6=4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		
label values obese4cat obese4cat
order obese4cat, after(bmicat)

gen obese4cat_withmiss = obese4cat
replace obese4cat_withmiss =. if bmicat ==.


/*  Smoking  */


* Create non-missing 3-category variable for current smoking
recode smoke .=1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke

/* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3 .=1
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat

gen asthma = (asthmacat==2|asthmacat==3)*/



/*  Blood pressure   */

/* Categorise
gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
replace bpcat = . if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

label define bpcat 1 "Normal" 2 "Elevated" 3 "High, stage I"	///
					4 "High, stage II" 
label values bpcat bpcat

recode bpcat .=1, gen(bpcat_nomiss)
label values bpcat_nomiss bpcat

* Create non-missing indicator of known high blood pressure
gen bphigh = (bpcat==4)
order bpcat bphigh, after(bp_sys_date)
*/


***************************
*  Grouped comorbidities  *
***************************


/*  Spleen  */

* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
egen spleen = rowmax(dysplenia sickle_cell) 
order spleen, after(sickle_cell)



/*  Cancer  */

label define cancer 1 "Never" 2 "Last year" 3 "2-5 years ago" 4 "5+ years"

gen fiveybefore = indexdate-5*365.25
gen oneybefore = indexdate-365.25

* Haematological malignancies
gen     cancer_haem_cat = 4 if inrange(haem_cancer_date, d(1/1/1900), fiveybefore)
replace cancer_haem_cat = 3 if inrange(haem_cancer_date, fiveybefore, oneybefore)
replace cancer_haem_cat = 2 if inrange(haem_cancer_date, oneybefore, indexdate)
recode  cancer_haem_cat . = 1
label values cancer_haem_cat cancer


* All other cancers
gen     cancer_exhaem_cat = 4 if inrange(lung_cancer_date,  d(1/1/1900), fiveybefore) | ///
								 inrange(other_cancer_date, d(1/1/1900), fiveybefore) 
replace cancer_exhaem_cat = 3 if inrange(lung_cancer_date,  fiveybefore, oneybefore) | ///
								 inrange(other_cancer_date, fiveybefore, oneybefore) 
replace cancer_exhaem_cat = 2 if inrange(lung_cancer_date,  oneybefore, indexdate) | ///
								 inrange(other_cancer_date, oneybefore, indexdate)
recode  cancer_exhaem_cat . = 1
label values cancer_exhaem_cat cancer


* Put variables together
order cancer_exhaem_cat cancer_haem_cat, after(other_cancer_date)



/*  Immunosuppression  */

* Immunosuppressed:
* HIV, permanent immunodeficiency ever, OR 
* temporary immunodeficiency or aplastic anaemia last year
gen temp1  = max(hiv, permanent_immunodeficiency)
gen temp2  = inrange(temporary_immunodeficiency_date, oneybefore, indexdate)
gen temp3  = inrange(aplastic_anaemia_date, oneybefore, indexdate)

egen other_immunosuppression = rowmax(temp1 temp2 temp3)
drop temp1 temp2 temp3
order other_immunosuppression, after(temporary_immunodeficiency)

/************
*   eGFR   *
************

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 
	
* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min=.
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no eth"


* Categorise into ckd stages
egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat 0=5 15=4 30=3 45=2 60=0, generate(ckd)
* 0 = "No CKD" 	2 "stage 3a" 3 "stage 3b" 4 "stage 4" 5 "stage 5"
label define ckd 0 "No CKD" 1 "CKD"
label values ckd ckd
label var ckd "CKD stage calc without eth"

* Convert into CKD group
recode ckd 2/5=1, gen(chronic_kidney_disease)
replace chronic_kidney_disease = 0 if creatinine==. 

recode ckd 0=1 2/3=2 4/5=3, gen(reduced_kidney_function_cat)
replace reduced_kidney_function_cat = 1 if creatinine==. 
label define reduced_kidney_function_catlab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4/5 egfr<30"
label values reduced_kidney_function_cat reduced_kidney_function_catlab 

*More detailed version incorporating stage 5 or dialysis as a separate category	
recode ckd 0=1 2/3=2 4=3 5=4, gen(reduced_kidney_function_cat2)
replace reduced_kidney_function_cat2 = 1 if creatinine==. 
replace reduced_kidney_function_cat2 = 4 if dialysis==1 

label define reduced_kidney_function_cat2lab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4 egfr 15-<30" 4 "Stage 5 egfr <15 or dialysis"
label values reduced_kidney_function_cat2 reduced_kidney_function_cat2lab 


* dialysis
if "$group" == "covid" | "$group" == "pneumonia"  { 
gen dialysis_flag = 1 if dialysis_date < hosp_expo_date
replace dialysis_flag = 0 if dialysis_flag ==.
}
if "$group" == "gen_population" | "$group" == "covid_community"{
gen dialysis_flag = 1 if dialysis_date < indexdate
replace dialysis_flag = 0 if dialysis_flag ==.
}

gen aki_exclusion_flag = 1 if egfr < 15 | dialysis_flag==1
replace aki_exclusion_flag = 0 if aki_exclusion_flag ==.
*/
 
	
************
*   Hba1c  *
************
	

/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage<=0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol<=0


local fifteenmbefore = `studystart'-15*(365.25/12)

* Only consider measurements in last 15 months
replace hba1c_percentage   = . if hba1c_percentage_date   < `fifteenmbefore'
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol_date < `fifteenmbefore'



/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)


/* Categorise hba1c and diabetes  */

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
tab hba1ccat

* Create diabetes, split by control/not
gen     diabcat = 1 if inlist(hba1ccat, 0, 1)
replace diabcat = 2 if inlist(hba1ccat, 2, 3, 4)
replace diabcat = 3 if !inlist(hba1ccat, 0, 1, 2, 3, 4)

label define diab_control 1 "Controlled diabetes"		///
						2 "Uncontrolled diabetes" 	///
						3 "No hba1c measure"
label values diabcat diab_control

* Delete unneeded variables
* Region might need to be added later
keep deregistered_date  other_immunosuppression hospitalised_covid_date ///  
 died_date_ons_date first_comm_covid_date age ethnicity chronic_cardiac_disease hypertension chronic_respiratory_disease ///
 organ_transplant dysplenia sickle_cell spleen hiv permanent_immunodeficiency /// 
 ra_sle_psoriasis other_neuro dementia chronic_liver_disease metformin_3mths exp insulin_meds_3mths hospitalised_covid ///  
 died_covid first_comm_covid patient_id indexdate male imd smoke smoke_nomiss ///  
  agegroup age1 age2 age3 bmicat obese4cat obese4cat_withmiss hba1ccat diabcat cancer*


order patient_id indexdate exp hospitalised_covid_date died_date_ons_date first_comm_covid_date metformin_3mths insulin_meds_3mths  ///
hospitalised_covid died_covid first_comm_covid 
**************
*  Outcomes  *
**************	
gen died  = cond(died_date_ons_date !=., 1,0)

* Individual outcomes only
gen comm_only = cond(first_comm_covid == 1 & died_date_ons_date ==. & hospitalised_covid ==0, 1, 0)
gen hosp_only = cond(hospitalised_covid == 1 & died_date_ons_date ==. & first_comm_covid ==0, 1, 0)
gen died_only = cond(died == 1 & hospitalised_covid ==0 & first_comm_covid ==0, 1, 0)

* Combinations
* 2 
gen comm_death = cond((first_comm_covid_date <= died_date_ons_date) & first_comm_covid == 1 & died_date_ons_date!=. & hospitalised_covid ==0, 1, 0)
gen comm_hosp  = cond((first_comm_covid_date <= hospitalised_covid_date) & first_comm_covid == 1 & died_date_ons_date==. & hospitalised_covid ==1, 1, 0)
gen hosp_comm  = cond((hospitalised_covid_date <= first_comm_covid_date) & first_comm_covid ==1 & died_date_ons_date==. & hospitalised_covid ==1, 1, 0)
gen hosp_death = cond((hospitalised_covid_date <= died_date_ons_date) & first_comm_covid ==0 & died_date_ons_date!=. & hospitalised_covid ==1, 1, 0)

* 3
gen comm_hosp_death  = cond((first_comm_covid_date <= hospitalised_covid_date <= died_date_ons_date) & first_comm_covid ==1 & died_date_ons_date!=. & hospitalised_covid ==1, 1, 0)
gen hosp_comm_death  = cond((hospitalised_covid_date <= first_comm_covid_date <= died_date_ons_date) & first_comm_covid ==1 & died_date_ons_date!=. & hospitalised_covid ==1, 1, 0)
gen death_comm_hosp  = cond((died_date_ons_date <= first_comm_covid_date <= hospitalised_covid_date) & first_comm_covid ==1 & died_date_ons_date!=. & hospitalised_covid ==1, 1, 0)
gen death_hosp_comm  = cond((died_date_ons_date <= hospitalised_covid_date <= first_comm_covid_date) & first_comm_covid ==1 & died_date_ons_date!=. & hospitalised_covid ==1, 1, 0)


**************
* Output 
**************

**************
* 1. Propns
**************
tempname john

postfile `john' str20(outcome) str20(treatment) numPatients numEvents propEvents using $tabfigdir/descriptive_stats.dta, replace

foreach out in comm_only hosp_only died_only comm_death comm_hosp hosp_comm hosp_death comm_hosp_death hosp_comm_death death_comm_hosp death_hosp_comm {

	forvalues t = 1/5 {
		
			if "`t'" ==  "1"  {
						local trt_grp = "SGLT2i" 
						safecount if exp == `t'
						local N = `r(N)'
												}
	
			if "`t'" ==  "2"  {
						local trt_grp = "DPP4i" 
						safecount if exp == `t'
						local N = `r(N)'
												}
	
			if "`t'" ==  "3"  {
						local trt_grp = "Sulfonylureas" 
						safecount if exp == `t'
						local N = `r(N)'
												}
	
			if "`t'" ==  "4"  {
						local trt_grp = "Three" 
						safecount if exp == `t'
						local N = `r(N)'
												}
	
			if "`t'" ==  "5"  {
						local trt_grp = "Four" 
						safecount if exp == `t'
						local N = `r(N)'
												}						
	
			
			safecount if `out' == 1 & exp == `t' 
			local numEvents .
			if `r(N)' != . local numEvents `r(N)'
	
			local prop = round(100*`numEvents'/`N', 0.1)
	
	post `john' ("`out'")  ("`trt_grp'") (`N') (`numEvents') (`prop')

	}

}
postclose `john'

**************
* 2. Table 1
**************
tempname john2

postfile `john2' str25(variable) category SGLT2i DPP4i Sulfs Three Four using $tabfigdir/table_1.dta, replace

safecount if exp == 1 
local exp_1_N = `r(N)'
safecount if exp == 2
local exp_2_N = `r(N)'
safecount if exp == 3 
local exp_3_N = `r(N)'
safecount if exp == 4 
local exp_4_N = `r(N)'
safecount if exp == 5
local exp_5_N = `r(N)'

post `john2' ("N") (1) (`exp_1_N') (`exp_2_N') (`exp_3_N') (`exp_4_N') (`exp_5_N') 

post `john2' ("Demographics") (1) (.) (.) (.) (.) (.)


foreach var in agegroup male ethnicity imd smoke_nomiss obese4cat {

	levelsof `var', local(cats)
	
	* Removes category 0 (only us for binary variables)
	local not 0
	local cats: list cats- not
	
		local i = 1
		foreach c of local cats { 
		
		
				safecount if `var' == `c' & exp == 1
				local exp_1_count = `r(N)'
				
				safecount if `var' == `c' & exp == 2
				local exp_2_count = `r(N)'

				safecount if `var' == `c' & exp == 3
				local exp_3_count = `r(N)'
				
				safecount if `var' == `c' & exp == 4
				local exp_4_count = `r(N)'
				
				safecount if `var' == `c' & exp == 5
				local exp_5_count = `r(N)'
		
		if `i' == 1 {
		post `john2' ("`var'") (`c') (`exp_1_count') (`exp_2_count') (`exp_3_count') (`exp_4_count') (`exp_5_count') 
		local ++i
		}
		else{
		post `john2' ("`var'") (`c') (`exp_1_count') (`exp_2_count') (`exp_3_count') (`exp_4_count') (`exp_5_count') 
		}
	}

}

post `john2' ("Diabetes") (1) (.) (.) (.) (.) (.)

foreach var in diabcat metformin_3mths insulin_meds_3mths  {

	levelsof `var', local(cats)
	
	* Removes category 0 (only us for binary variables)
	local not 0
	local cats: list cats- not
		
		local i = 1
	
		foreach c of local cats { 
		
		
				safecount if `var' == `c' & exp == 1
				local exp_1_count = `r(N)'
				
				safecount if `var' == `c' & exp == 2
				local exp_2_count = `r(N)'

				safecount if `var' == `c' & exp == 3
				local exp_3_count = `r(N)'
				
				safecount if `var' == `c' & exp == 4
				local exp_4_count = `r(N)'
				
				safecount if `var' == `c' & exp == 5
				local exp_5_count = `r(N)'
		
		if `i' == 1 {
		post `john2' ("`var'") (`c') (`exp_1_count') (`exp_2_count') (`exp_3_count') (`exp_4_count') (`exp_5_count') 
		local ++i
		}
		else{
		post `john2' ("`var'") (`c') (`exp_1_count') (`exp_2_count') (`exp_3_count') (`exp_4_count') (`exp_5_count') 
		}
	}

}

post `john2' ("Clinical characteristics") (1) (.) (.) (.) (.) (.)

foreach var in chronic_cardiac_disease hypertension chronic_respiratory_disease chronic_liver_disease cancer_exhaem_cat cancer_haem_cat permanent_immunodeficiency other_immunosuppression dysplenia sickle_cell spleen hiv ra_sle_psoriasis other_neuro dementia  {
	
	levelsof `var', local(cats)
	local not 0
	local cats: list cats- not
		
		local i = 1
	
		foreach c of local cats { 
		
				safecount if `var' == `c' & exp == 1
				local exp_1_count = `r(N)'
				
				safecount if `var' == `c' & exp == 2
				local exp_2_count = `r(N)'

				safecount if `var' == `c' & exp == 3
				local exp_3_count = `r(N)'
				
				safecount if `var' == `c' & exp == 4
				local exp_4_count = `r(N)'
				
				safecount if `var' == `c' & exp == 5
				local exp_5_count = `r(N)'
		
		if `i' == 1 {
		post `john2' ("`var'") (`c') (`exp_1_count') (`exp_2_count') (`exp_3_count') (`exp_4_count') (`exp_5_count') 
		local ++i
		}
		else{
		post `john2' ("`var'") (`c') (`exp_1_count') (`exp_2_count') (`exp_3_count') (`exp_4_count') (`exp_5_count') 
		}
	}
}

postclose `john2'

**** Tidy output save
save $outdir/descriptive_cohort.dta, replace

use $tabfigdir/descriptive_stats.dta, clear
export delimited using $tabfigdir/descriptive_stats.csv, replace

use $tabfigdir/table_1.dta, clear

* Add percentages
local N = SGLT2i[1]
gen SGLT2i_perc = round(100*SGLT2i/`N',0.1)

local N = DPP4i[1]
gen DPP4i_perc = round(100*DPP4i/`N',0.1)

local N = Sulfs[1]
gen Sulfs_perc = round(100*Sulfs/`N',0.1)

local N = Three[1]
gen Three_perc = round(100*Three/`N',0.1)

local N = Four[1]
gen Four_perc = round(100*Four/`N',0.1)

* labelling variables
rename category category2

* agegroup
gen category = "18-<50" if variable == "agegroup" & category2==1
replace category = "50-<60" if variable == "agegroup" & category2==2
replace category = "60-<60" if variable == "agegroup" & category2==3
replace category = "70-<60" if variable == "agegroup" & category2==4
replace category = "80+" if variable == "agegroup" & category2==5

* ethnicity
replace category = "White" if variable == "ethnicity" & category2==1
replace category = "Mixed" if variable == "ethnicity" & category2==2
replace category = "Asian or Asian British" if variable == "ethnicity" & category2==3
replace category = "Black" if variable == "ethnicity" & category2==4
replace category = "Other" if variable == "ethnicity" & category2==5
replace category = "Unknown" if variable == "ethnicity" & category2==6

* imd
replace category = "1 least deprived" if variable == "imd" & category2==1
replace category = "2" if variable == "imd" & category2==2
replace category = "3" if variable == "imd" & category2==3
replace category = "4" if variable == "imd" & category2==4
replace category = "5 most deprived" if variable == "imd" & category2==5

/* region_9
replace category = "East Midlands" if variable == "region_9" & category2==1
replace category = "East" if variable == "region_9" & category2==2
replace category = "London" if variable == "region_9" & category2==3
replace category = "North East" if variable == "region_9" & category2==4
replace category = "North West" if variable == "region_9" & category2==5
replace category = "South East" if variable == "region_9" & category2==6
replace category = "South West" if variable == "region_9" & category2==7
replace category = "West Midlands" if variable == "region_9" & category2==8
replace category = "Yorkshire and The Humber" if variable == "region_9" & category2==9
*/

* smoke_nomiss
replace category = "Never" if variable == "smoke_nomiss" & category2 == 1
replace category = "Former" if variable == "smoke_nomiss" & category2 == 2
replace category = "Current" if variable == "smoke_nomiss" & category2 == 3

* obese4cat
replace category = "No record of obesity" if variable == "obese4cat" & category2 == 1
replace category = "Obese I (30-34.9)" if variable == "obese4cat" & category2 == 2
replace category = "Obese II (35-39.9)" if variable == "obese4cat" & category2 == 3
replace category = "Obese III (40+)" if variable == "obese4cat" & category2 == 4


* diabcat 
replace category = "Controlled diabetes" if variable == "diabcat" & category2 == 1
replace category = "Uncontrolled diabetes" if variable == "diabcat" & category2 == 2
replace category = "No hba1c measure" if variable == "diabcat" & category2 == 3

* cancer
replace category = "Never" if (variable =="cancer_exhaem_cat" | variable =="cancer_haem_cat") & category2 == 1
replace category = "Last year" if (variable =="cancer_exhaem_cat" | variable =="cancer_haem_cat") & category2 == 2
replace category = "2-5 years ago" if (variable =="cancer_exhaem_cat" | variable =="cancer_haem_cat") & category2 == 3
replace category = "5+ years" if (variable =="cancer_exhaem_cat" | variable =="cancer_haem_cat") & category2 == 4

* Tidy 
replace category = " - " if variable =="N" 

* Remove old category var 
replace variable = "" if category2!=1
drop category2
order variable category SGLT2i SGLT2i_perc DPP4i DPP4i_perc Sulfs Sulfs_perc Three Three_perc Four Four_perc

export delimited using $tabfigdir/table_1.csv, replace



