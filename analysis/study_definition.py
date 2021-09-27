from datetime import datetime, timedelta
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist,
    codelist_from_csv,
    filter_codes_by_category,
)
from codelists import *

start_date  = "2020-09-01"

def days_before(s, days):
    date = datetime.strptime(s, "%Y-%m-%d")
    modified_date = date - timedelta(days=days)
    return datetime.strftime(modified_date, "%Y-%m-%d")


study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.7,
    },
    # This line defines the study population
    population=patients.satisfying(
        """
             has_follow_up
        AND t2dm = 1     
        AND NOT exposure = "none"
        AND (age >=18 AND age <= 110)
        AND (sex = "M" OR sex = "F")
        AND imd > 0
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2019-09-01", "2020-09-01"
        ),
    ),

    index_date = "2020-09-01",
    deregistered=patients.date_deregistered_from_all_supported_practices(
            date_format="YYYY-MM-DD"
        ),
#####################    
##### T2DM population
#####################

    t1dm_gp=patients.with_these_clinical_events(
            diabetes_t1_codes,
            on_or_before=start_date,
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
    t2dm_gp=patients.with_these_clinical_events(
            diabetes_t2_codes,
            on_or_before=f"{start_date}",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
    unknown_diabetes_gp=patients.with_these_clinical_events(
            diabetes_unknown_codes,
            on_or_before=f"{start_date}",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
    t1dm_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=diabetes_t1_codes_hospital,
            on_or_before=f"{start_date}",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
    t2dm_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=diabetes_t1_codes_hospital,
            on_or_before=f"{start_date}",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
    oad_lastyear_meds=patients.with_these_medications(
            oad_med_codes,
            between=[
               "2019-09-01",
                f"{start_date}"
            ],
            return_expectations={"incidence": 0.05},
        ),
    type1_agg=patients.satisfying("t1dm_gp OR t1dm_hospital"
        ),
    type2_agg=patients.satisfying("t2dm_gp OR t2dm_hospital"
        ),
    t2dm=patients.satisfying(
            """
                (type2_agg AND NOT
                type1_agg)
            OR
                (((type1_agg AND type2_agg) OR
                (type2_agg AND unknown_diabetes_gp AND NOT type1_agg) OR
                (unknown_diabetes_gp AND NOT type1_agg AND NOT type2_agg))
                AND
                (oad_lastyear_meds))
            """,
            return_expectations={"incidence": 0.5},
        ),

#####################
##### Characteristics
#####################

    age=patients.age_as_of(
        f"{start_date}",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
             },
        ),
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
            }
        ),
    region=patients.registered_practice_as_of(
        f"{start_date}",
        returning="nuts1_region_name",
        return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "North East": 0.1,
                        "North West": 0.1,
                        "Yorkshire and The Humber": 0.1,
                        "East Midlands": 0.1,
                        "West Midlands": 0.1,
                        "East": 0.1,
                        "London": 0.2,
                        "South East": 0.1,
                        "South West": 0.1,
                    },
                },
            },
        ),
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        on_or_before=f"{start_date}",
        return_expectations={
                "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
                "incidence": 0.75,
            },
        ),
    imd=patients.address_as_of(
        f"{start_date}",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "100": 0.1,
                        "200": 0.1,
                        "300": 0.1,
                        "400": 0.1,
                        "500": 0.1,
                        "600": 0.1,
                        "700": 0.1,
                        "800": 0.1,
                        "900": 0.1,
                        "1000": 0.1,
                    }
                },
            },
        ),
    hba1c_mmol_per_mol=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        on_or_before=f"{start_date}",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        on_or_before=f"{start_date}",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S' OR smoked_last_18_months",
            "E": """
                     (most_recent_smoking_code = 'E' OR (
                       most_recent_smoking_code = 'N' AND ever_smoked
                       )
                     ) AND NOT smoked_last_18_months
                """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "incidence": 1,
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}},
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            on_or_before=days_before(start_date, 1),
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before=days_before(start_date, 1),
        ),
        smoked_last_18_months=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S"]),
            between=[days_before(start_date, 548), start_date],
        ),
    ),
     bmi=patients.most_recent_bmi(
        on_or_before="2020-08-31",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.98,
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
        },
    ),
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    hypertension=patients.with_these_clinical_events(
        hypertension_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    chronic_respiratory_disease=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes,
            on_or_before=f"{start_date}",
            return_expectations={"incidence": 0.05},
    ),
        # cancer
    lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes, return_first_date_in_period=True, include_month=True,
    ),
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes, return_first_date_in_period=True, include_month=True,
    ),
    other_cancer=patients.with_these_clinical_events(
        other_cancer_codes, return_first_date_in_period=True, include_month=True,
    ),
    
    # immuno
    
    organ_transplant=patients.with_these_clinical_events(
        organ_transplant_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    dysplenia=patients.with_these_clinical_events(
        spleen_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    sickle_cell=patients.with_these_clinical_events(
        sickle_cell_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    aplastic_anaemia=patients.with_these_clinical_events(
        aplastic_codes, return_last_date_in_period=True, include_month=True,
    ),
    hiv=patients.with_these_clinical_events(
        hiv_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    permanent_immunodeficiency=patients.with_these_clinical_events(
        permanent_immune_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    temporary_immunodeficiency=patients.with_these_clinical_events(
        temp_immune_codes, return_last_date_in_period=True, include_month=True,
    ),
    
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    
    
    # neuro
    other_neuro=patients.with_these_clinical_events(
        other_neuro_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    dementia=patients.with_these_clinical_events(
        dementia_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),
    
    # gastro
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        on_or_before=f"{start_date}",
        return_expectations={"incidence": 0.05},
    ),


################
##### Treatments
################

metformin_3mths=patients.with_these_medications(
            metformin_med_codes,
            between=[days_before(start_date, 90), start_date],
            return_expectations={"incidence": 0.3},
    ),

dpp4=patients.with_these_medications(
        dpp4i_med_codes,
        between=[days_before(start_date, 90), start_date],
        return_expectations={"incidence": 0.3},
    ),

sglt2=patients.with_these_medications(
         sglt2i_med_codes,
        between=[days_before(start_date, 90), start_date],
        return_expectations={"incidence": 0.3},
     ),

sulfonylurea=patients.with_these_medications(
        sulfs_med_codes,
        between=[days_before(start_date, 90), start_date],
        return_expectations={"incidence": 0.3},
    ),

exposure=patients.categorised_as(
        {
            "DPP4i": """
                    dpp4
                    AND NOT sglt2
                    AND NOT sulfonylurea
                    """,
            "SGLT2i": """
                    sglt2
                    AND NOT dpp4
                    AND NOT sulfonylurea
                    """,
            "Sulfonylureas": """
                    sulfonylurea
                    AND NOT sglt2
                    AND NOT dpp4
                    """,
            "Three": """
                    (dpp4 AND sglt2) OR
                    (dpp4 AND sulfonylurea) OR
                    (sglt2 AND  sulfonylurea)
                    """ ,
             "Four": """
                    (dpp4 AND sglt2 AND sulfonylurea)
                    """ ,
                          
            "none": "DEFAULT",
        },
        return_expectations={
            "incidence": 1,
            "category": {
                "ratios": {
                    "DPP4i": 0.3,
                    "SGLT2i": 0.3,
                    "Sulfonylureas": 0.3,
                    "Three": 0.05,
                    "Four": 0.05,
                    "none": 0.0,
                }
            },
        },
    ),

insulin_meds_3mths=patients.with_these_medications(
            insulin_med_codes,
            between=[
                "2020-06-01",
                f"{start_date}"
            ],
            return_expectations={"incidence": 0.05},
        ),

##############
##### Outcomes
##############

hospitalised_covid=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codelist,
        on_or_after=f"{start_date}",
        return_expectations={"incidence": 0.2},
    ),
hospitalised_covid_date=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codelist,
        on_or_after=f"{start_date}",
        returning="date_admitted",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": start_date}},
    ),
died_covid=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        match_only_underlying_cause=False,
        on_or_after=f"{start_date}",
        return_expectations={"incidence": 0.2},
    ),
died_date_ons=patients.died_from_any_cause(
        on_or_after=f"{start_date}",
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": start_date}},
    ),
first_comm_covid =patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after = f"{start_date}",
        find_first_match_in_period=True,
        return_expectations={"incidence": 0.2},
    ),
first_comm_covid_date =patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after = f"{start_date}",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": start_date}},
    ),
)

