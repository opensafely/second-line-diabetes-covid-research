
from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
)
from codelists import *

start_date  = "2020-09-01"

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.7,
    },
    index_date="2019-02-01",
    # This line defines the study population
    population=patients.satisfying(
        """
        has_follow_up
        AND t2dm = 1      
        AND (age >=18 AND age <= 110)

        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 1 year", "index_date"
        ),
        age=patients.age_as_of(
            "index_date",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),


        t1dm_gp=patients.with_these_clinical_events(
            diabetes_t1_codes,
            on_or_before="index_date",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
        t2dm_gp=patients.with_these_clinical_events(
            diabetes_t2_codes,
            on_or_before="index_date",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
        unknown_diabetes_gp=patients.with_these_clinical_events(
            diabetes_unknown_codes,
            on_or_before="index_date",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
        t1dm_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=diabetes_t1_codes_hospital,
            on_or_before="index_date",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
        t2dm_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=diabetes_t1_codes_hospital,
            on_or_before="index_date",
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.05},
        ),
        oad_lastyear_meds=patients.with_these_medications(
            oad_med_codes,
            between=[
               "index_date - 1 year",
                "index_date"
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
        ),
        ),
################
##### Treatments
################

dpp4=patients.with_these_medications(
        dpp4i_med_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.3},
    ),

sglt2=patients.with_these_medications(
         sglt2i_med_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.3},
     ),

sulfonylurea=patients.with_these_medications(
        sulfs_med_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.3},
    ),

    died=patients.died_from_any_cause(
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.1},
    ),
)

measures = [
    Measure(
        id="died_rate",
        numerator="died",
        denominator="population",
    ),
    Measure(
        id="sglt2i_rate",
        numerator="sglt2",
        denominator="population",
    ),
    Measure(
        id="dpp4i_rate",
        numerator="dpp4",
        denominator="population",
       
    ),
    Measure(
        id="sulf_rate",
        numerator="sulfonylurea",
        denominator="population",

    ),
]