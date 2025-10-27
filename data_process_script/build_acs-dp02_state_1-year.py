import requests
import pandas as pd
import time

years = [2021, 2022, 2023, 2024]
variables = [
    "DP02_0067PE",
    "DP02_0068PE",
    "DP02_0027PE",
    "DP02_0033PE",
    "DP02_0026PE",
    "DP02_0032PE",
    "DP02_0038PE"
]
base_url = "https://api.census.gov/data/{year}/acs/acs1/profile"

def fetch_acs1(year):
    url = base_url.format(year=year)
    params = {"get": "NAME," + ",".join(variables), "for": "state:*"}
    r = requests.get(url, params=params)
    if r.status_code != 200:
        print(f"❌ Failed for {year}")
        return None
    data = r.json()
    df = pd.DataFrame(data[1:], columns=data[0])
    for v in variables:
        df[v] = pd.to_numeric(df[v], errors="coerce")
    df["married_pct"] = (df["DP02_0027PE"] + df["DP02_0033PE"]) / 2
    df["never_married_pct"] = (df["DP02_0026PE"] + df["DP02_0032PE"]) / 2
    df["year"] = year
    df_out = df[[
        "year", "state", "NAME",
        "DP02_0067PE", "DP02_0068PE",
        "married_pct", "never_married_pct", "DP02_0038PE"
    ]].rename(columns={
        "DP02_0067PE": "educ_hs_or_higher_pct",
        "DP02_0068PE": "educ_ba_or_higher_pct",
        "DP02_0038PE": "unmarried_birth_pct"
    })
    print(f"✅ Fetched {year}: {len(df_out)} states")
    return df_out

all_years = []
for y in years:
    d = fetch_acs1(y)
    if d is not None:
        all_years.append(d)
    time.sleep(1)

acs = pd.concat(all_years, ignore_index=True)
acs.to_csv("state_social_char_2021_2024.csv", index=False)
print("✅ Saved state_social_char_2021_2024.csv")
print(acs.head())
