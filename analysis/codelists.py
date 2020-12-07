from cohortextractor import codelist, codelist_from_csv

chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_codelist = codelist_from_csv(
    "codelists/opensafely-covid-identification.csv",
    system="icd10",
    column="icd10_code",
)

clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

creatinine_codes = codelist(
    [
        "44J3.",
        "44J3z",
        "4I37.",
        "X771Q",
        "X80D7",
        "XE26a",
        "XE2q5",
        "XaERX",
        "XaERc",
        "XaETQ",
    ],
    system="ctv3",
)
esrf_codes = codelist_from_csv(
    "codelists/opensafely-chronic-kidney-disease.csv", system="ctv3", column="CTV3ID",
)

type_2_diabetes_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

hba1c_new_codes = codelist(["XaPbt", "Xaeze", "Xaezd"], system="ctv3")
hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")

placeholder_codelist = codelist(["cndjksfksfean"], system="ctv3")

placeholder_med_codelist = codelist(["cndjksfksfean"], system="snomed")

insulin_codes = codelist_from_csv(
    "codelists/opensafely-insulin-medication.csv",
    system="snomed",
    column="id",
)
