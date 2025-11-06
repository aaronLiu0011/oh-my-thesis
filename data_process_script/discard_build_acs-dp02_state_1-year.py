import requests
import pandas as pd
import time

# ACS DP02 (Social Characteristics)
# check variables' codes at: https://api.census.gov/data/2023/acs/acs1/profile/variables.json

years = range(2010, 2025)
variables_base = [
    "DP02_0067PE",  # High school graduate or higher
    "DP02_0068PE",  # Bachelor's degree or higher
    "DP02_0027PE",  # Now married (male, 15+)
    "DP02_0033PE",  # Now married (female, 15+)
    "DP02_0026PE",  # Never married (male, 15+)
    "DP02_0032PE"  # Never married (female, 15+)
]

internet_var_1 = "DP02_0152PE"  # Internet use (only available from 2013 onwards) 
internet_var_2 = "DP02_0153PE"  # code changed in 2021

base_url = "https://api.census.gov/data/{year}/acs/acs1/profile"

def fetch_acs1(year):
    if 2013 <= year <= 2019:
        internet_var = internet_var_1
    elif year >= 2020:
        internet_var = internet_var_2
    else:
        internet_var = None

    vars_use = variables_base + ([internet_var] if internet_var else [])
    url = base_url.format(year=year)
    params = {"get": "NAME," + ",".join(vars_use), "for": "state:*"}
    r = requests.get(url, params=params)
    if r.status_code != 200:
        print(f"❌ Failed {year}")
        return None
    data = r.json()
    df = pd.DataFrame(data[1:], columns=data[0])
    for v in vars_use:
        df[v] = pd.to_numeric(df[v], errors="coerce")
    df["married_pct"] = (df["DP02_0027PE"] + df["DP02_0033PE"]) / 2
    df["never_married_pct"] = (df["DP02_0026PE"] + df["DP02_0032PE"]) / 2
    df["unmarried_birth_pct"] = df["DP02_0038PE"].mask(df["DP02_0038PE"] < -100000000, pd.NA)
    df["year"] = year
    df["internet_use_pct"] = df[internet_var] if internet_var else pd.NA
    df_out = df[[
        "year", "state", "NAME",
        "DP02_0067PE", "DP02_0068PE",
        "married_pct", "never_married_pct", "unmarried_birth_pct",
        "internet_use_pct"
    ]].rename(columns={
        "DP02_0067PE": "educ_hs_or_higher_pct",
        "DP02_0068PE": "educ_ba_or_higher_pct"})
    print(f"✅ {year} fetched")
    return df_out

all_years = []
for y in years:
    d = fetch_acs1(y)
    if d is not None:
        all_years.append(d)
    time.sleep(0.5)

acs = pd.concat(all_years, ignore_index=True)
acs.to_csv("state_social_char_2010_2024.csv", index=False)
print("✅ Saved state_social_char_2010_2024.csv")
