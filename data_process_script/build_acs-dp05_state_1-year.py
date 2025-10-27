import requests
import pandas as pd
import time

# ACS 2023 5-year DP05 (demographic and housing characteristics)
# check variables' codes at: https://api.census.gov/data/2023/acs/acs5/profile/variables.json

"""
DP05_0001E: Total population
DP05_0008PE: 15 to 19 years
DP05_0009PE: 20 to 24 years
DP05_0010PE: 25 to 34 years
DP05_0011PE: 35 to 44 years
DP05_0038PE: Black or African American alone
DP05_0076PE: HISPANIC OR LATINO AND RACE
"""

years = [2021, 2022, 2023, 2024]
variables = [
    "DP05_0001E",
    "DP05_0008PE",
    "DP05_0009PE",
    "DP05_0010PE",
    "DP05_0011PE",
    "DP05_0038PE",
    "DP05_0076PE",
]
base_url = "https://api.census.gov/data/{year}/acs/acs1/profile"

def fetch_acs1(year):
    url = base_url.format(year=year)
    params = {"get": "NAME," + ",".join(variables), "for": "state:*"}
    resp = requests.get(url, params=params)
    if resp.status_code != 200:
        print(f"❌ Failed for {year}: {resp.status_code}")
        return None
    data = resp.json()
    df = pd.DataFrame(data[1:], columns=data[0])
    for c in variables:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    df["age_15_44"] = df["DP05_0008PE"] + df["DP05_0009PE"] + df["DP05_0010PE"] + df["DP05_0011PE"]
    df["black_share"] = df["DP05_0038PE"]
    df["hispanic_share"] = df["DP05_0076PE"]
    df["year"] = year
    df_out = df[["year", "state", "NAME", "age_15_44", "black_share", "hispanic_share"]]
    print(f"✅ Fetched {year}: {len(df_out)} states")
    return df_out

all_years = []
for y in years:
    d = fetch_acs1(y)
    if d is not None:
        all_years.append(d)
    time.sleep(1)

acs_panel = pd.concat(all_years, ignore_index=True)
acs_panel.to_csv("state_demographics_2021_2024.csv", index=False)

print("✅ All years saved to state_demographics_2021_2024.csv")
print(acs_panel.head())
