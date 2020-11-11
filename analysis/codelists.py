from cohortextractor import codelist, codelist_from_csv

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

placeholder_codelist=codelist(["cndjksfks","jifsjiofs", "hfuisahfl"], system="ctv3")

placeholder_med_codelist=codelist(["cndjksfks"], system="snomed")