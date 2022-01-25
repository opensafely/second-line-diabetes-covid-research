import os
import pandas as pd
from study_definition_measures import measures


def report(text_to_write, erase=False):
    if (m.numerator == "died") and os.path.isfile(report_path):
        os.remove(report_path)
    with open(report_path, "a") as txt:
        txt.write(f"{text_to_write}\n")


for m in measures:
    df = pd.read_csv(
        f"released_output/table_{m.id}.csv",
        index_col=[0],
        header=[0, 1],
        parse_dates=[0],
    ).fillna(0)
    apr_2019 = df.loc["2019-04-01"]
    apr_2020 = df.loc["2020-04-01"]
    difference = apr_2020 - apr_2019
    change = round(((difference) / apr_2019) * 100, 1)
    total_difference = round(difference[f"total_{m.numerator}"]["Unnamed: 7_level_1"])
    total_percent = change[f"total_{m.numerator}"]["Unnamed: 7_level_1"]
    covid_prop = round(
        (
            (apr_2020[m.numerator]["COVID-19 hospitalised"])
            / apr_2020[f"total_{m.numerator}"]["Unnamed: 7_level_1"]
        )
        * 100,
        1,
    )
    gen_difference = round(difference[m.numerator]["General population"])
    gen_percent = change[m.numerator]["General population"]
    report_path = "output/table.txt"
    report(
        f"{m.numerator}\t{total_difference} ({total_percent})\t{gen_difference} ({gen_percent})\t{covid_prop}"
    )
