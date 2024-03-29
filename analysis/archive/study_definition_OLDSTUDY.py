from datetime import datetime, timedelta
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist,
    codelist_from_csv,
    filter_codes_by_category,
)
from codelists import *

start_date = "2020-02-01"
four_months_before_start = "2019-10-01"


def days_before(s, days):
    date = datetime.strptime(s, "%Y-%m-%d")
    modified_date = date - timedelta(days=days)
    return datetime.strftime(modified_date, "%Y-%m-%d")


study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5,
    },
    # This line defines the study population
    population=patients.satisfying(
        """
            metformin_treatment
        AND NOT exposure = "none"
        AND NOT insulin
        AND (age >=18 AND age <= 110)
        AND has_follow_up
        AND (sex = "M" OR sex = "F")
        AND imd > 0
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2019-02-01", start_date
        ),
        insulin=patients.with_these_medications(
            insulin_codes,
            on_or_before=start_date,
        ),
    ),
    age=patients.age_as_of(
        "2020-02-01",
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
    diabetes_ever=patients.with_these_clinical_events(
        type_2_diabetes_codes,
        on_or_before=start_date,
        return_expectations={"incidence": 0.05},
    ),
    metformin_treatment=patients.satisfying(
        """
        metformin_count >= 2
        """,
        metformin_count=patients.with_these_medications(
            placeholder_med_codelist,
            returning="number_of_matches_in_period",
            between=[days_before(start_date, 180), start_date],
        ),
        return_expectations={"incidence": 0.1},
    ),
    any_dpp4=patients.with_these_medications(
        placeholder_med_codelist,
        between=[days_before(start_date, 180), start_date],
        return_expectations={"incidence": 0.3},
    ),
    any_sglt2=patients.with_these_medications(
        placeholder_med_codelist,
        between=[days_before(start_date, 180), start_date],
        return_expectations={"incidence": 0.3},
    ),
    any_sulfonylurea=patients.with_these_medications(
        placeholder_med_codelist,
        between=[days_before(start_date, 180), start_date],
        return_expectations={"incidence": 0.3},
    ),
    exposure=patients.categorised_as(
        {
            "DPP4i": """
                    any_dpp4
                    AND NOT any_sglt2
                    AND NOT any_sulfonylurea
                    """,
            "SGLT2i": """
                    any_sglt2
                    AND NOT any_dpp4
                    AND NOT any_sulfonylurea
                    """,
            "Sulfonylureas": """
                    any_sulfonylurea
                    AND NOT any_sglt2
                    AND NOT any_dpp4
                    """,
            "none": "DEFAULT",
        },
        return_expectations={
            "incidence": 1,
            "category": {
                "ratios": {
                    "DPP4i": 0.4,
                    "SGLT2i": 0.3,
                    "Sulfonylureas": 0.3,
                    "none": 0.0,
                }
            },
        },
    ),
    hospitalised_covid=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codelist,
        on_or_after=start_date,
        return_expectations={"incidence": 0.2},
    ),
    hospitalised_covid_date=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codelist,
        on_or_after=start_date,
        returning="date_admitted",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": start_date}, "incidence": 0.2},
    ),
    died_covid=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        match_only_underlying_cause=False,
        on_or_after=start_date,
        return_expectations={"incidence": 0.2},
    ),
    died_date_ons=patients.died_from_any_cause(
        on_or_after=start_date,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": start_date}},
    ),
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        on_or_before=days_before(start_date, 1),
        return_expectations={
            "category": {"ratios": {"1": 0.6, "2": 0.1, "3": 0.1, "4": 0.1, "5": 0.1}},
            "incidence": 0.75,
        },
    ),
    hba1c_mmol_per_mol_1=patients.with_these_clinical_events(
        hba1c_new_codes,
        returning="numeric_value",
        find_last_match_in_period=True,
        between=[days_before(start_date, 730), start_date],
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage=patients.with_these_clinical_events(
        hba1c_old_codes,
        returning="numeric_value",
        find_last_match_in_period=True,
        between=[days_before(start_date, 730), start_date],
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    imd=patients.address_as_of(
        start_date,
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
    bmi=patients.most_recent_bmi(
        between=[days_before(start_date, 36525), start_date],
        minimum_age_at_measurement=16,
        return_expectations={
            "incidence": 0.9,
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
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
    creatinine=patients.with_these_clinical_events(
        creatinine_codes,
        returning="numeric_value",
        between=[days_before(start_date, 30 * 5), start_date],
        find_last_match_in_period=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 150.0, "stddev": 200.0},
            "incidence": 0.95,
        },
    ),
    esrf=patients.with_these_clinical_events(
        esrf_codes,
        on_or_before=start_date,
        return_expectations={"incidence": 0.05},
    ),
    retinopathy=patients.with_these_clinical_events(
        placeholder_codelist,
        on_or_before=start_date,
        return_expectations={"incidence": 0.05},
    ),
    neuropathy=patients.with_these_clinical_events(
        placeholder_codelist,
        on_or_before=start_date,
        return_expectations={"incidence": 0.05},
    ),
    cvd=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        on_or_before=start_date,
        return_expectations={"incidence": 0.05},
    ),
    region=patients.registered_practice_as_of(
        start_date,
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
    stp=patients.registered_practice_as_of(
        start_date,
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),
    practice_id=patients.registered_practice_as_of(
        start_date,
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
            "incidence": 1,
        },
    ),
)
