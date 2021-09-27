from cohortextractor import codelist, codelist_from_csv

##### Outcomes
# COVID ICD10
covid_codelist = codelist_from_csv(
    "codelists/opensafely-covid-identification.csv",
    system="icd10",
    column="icd10_code",
)

##### Diabetes        
diabetes_t1_codes = codelist_from_csv(
    "codelists/opensafely-type-1-diabetes.csv", system="ctv3", column="CTV3ID"
)
diabetes_t2_codes = codelist_from_csv(
    "codelists/opensafely-type-2-diabetes.csv", system="ctv3", column="CTV3ID"
)
diabetes_unknown_codes = codelist_from_csv(
    "codelists/opensafely-diabetes-unknown-type.csv", system="ctv3", column="CTV3ID"
)
diabetes_t1_codes_hospital = codelist_from_csv(
    "codelists/opensafely-type-1-diabetes-secondary-care.csv",
    system="icd10",
    column="icd10_code",
)
diabetes_t2_codes_hospital = codelist(
    ["E11", "E110", "E112", "E113", "E114", "E115", "E116", "E118", "E119"],
    system="icd10",
)

oad_med_codes = codelist_from_csv(
    "codelists/opensafely-antidiabetic-drugs.csv", system="snomed", column="id"
)

##### Medications
# Metform
metformin_med_codes = codelist_from_csv(
    "codelists/user-john-tazare-metformin-dmd.csv",
    system="snomed",
    column="dmd_id",
)

# DPP4i
dpp4i_med_codes = codelist_from_csv(
    "codelists/user-john-tazare-dpp-inhibitors-dmd.csv",
    system="snomed",
    column="dmd_id",
)

# SGLT2i
sglt2i_med_codes = codelist_from_csv(
    "codelists/user-john-tazare-sglt2-inhibitors-dmd.csv",
    system="snomed",
    column="dmd_id",
)

# Sulfonylureas
sulfs_med_codes = codelist_from_csv(
    "codelists/user-john-tazare-sulfonylureas-dmd.csv",
    system="snomed",
    column="dmd_id",
)

# Insulin
insulin_med_codes = codelist_from_csv(
    "codelists/opensafely-insulin-medication.csv", system="snomed", column="id"
)


##### Characteristics
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

hba1c_new_codes = codelist(["XaPbt", "Xaeze", "Xaezd"], system="ctv3")
hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")


# Neuro

dementia_codes = codelist_from_csv(
    "codelists/opensafely-dementia-complete.csv", system="ctv3", column="code"
)


other_neuro_codes = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)

# respiratory

chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv",
    system="ctv3",
    column="CTV3ID",
)


chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID"
)

hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv", system="ctv3", column="CTV3ID"
)

systolic_blood_pressure_codes = codelist(["2469."], system="ctv3")
diastolic_blood_pressure_codes = codelist(["246A."], system="ctv3")

# gastro

chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID"
)
# immuno

chemo_radio_therapy_codes = codelist_from_csv(
    "codelists/opensafely-chemotherapy-or-radiotherapy-updated.csv",
    system="ctv3",
    column="CTV3ID",
)

hiv_codes = codelist_from_csv(
    "codelists/opensafely-hiv.csv", system="ctv3", column="CTV3ID", category_column="CTV3ID"
)

permanent_immune_codes = codelist_from_csv(
    "codelists/opensafely-permanent-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)

temp_immune_codes = codelist_from_csv(
    "codelists/opensafely-temporary-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)

aplastic_codes = codelist_from_csv(
    "codelists/opensafely-aplastic-anaemia.csv", system="ctv3", column="CTV3ID"
)


spleen_codes = codelist_from_csv(
    "codelists/opensafely-asplenia.csv", system="ctv3", column="CTV3ID"
)

organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv",
    system="ctv3",
    column="CTV3ID",
)

sickle_cell_codes = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv", system="ctv3", column="CTV3ID"
)

ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/opensafely-ra-sle-psoriasis.csv", system="ctv3", column="CTV3ID"
)

# cancer

lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", system="ctv3", column="CTV3ID"
)

haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", system="ctv3", column="CTV3ID"
)

other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)


chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID"
)

