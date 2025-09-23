import os, requests, pandas as pd

BASE = "https://api.census.gov/data"
DATASET = "acs/acs5/subject"
YEARS = range(2010, 2023+1)
API_KEY = os.getenv("CENSUS_KEY")  # optional

# S1501 percent estimates (25+):
HS_VAR = "S1501_C02_015"  # High school graduate or higher (%)
BA_VAR = "S1501_C02_016"  # Bachelor's degree or higher (%)

rows = []
for y in YEARS:
    params = {
        "get": f"NAME,{HS_VAR},{BA_VAR}",
        "for": "county:*",
        "in": "state:*",
    }
    if API_KEY: params["key"] = API_KEY
    url = f"{BASE}/{y}/{DATASET}"
    r = requests.get(url, params=params, timeout=60)
    if r.status_code != 200:
        print(f"skip {y}: {r.status_code}")
        continue
    data = r.json()
    df = pd.DataFrame(data[1:], columns=data[0])
    df[HS_VAR] = pd.to_numeric(df[HS_VAR], errors="coerce")
    df[BA_VAR] = pd.to_numeric(df[BA_VAR], errors="coerce")
    df["fips"] = df["state"] + df["county"]
    df["year"] = y
    rows.append(df[["fips","NAME","year",HS_VAR,BA_VAR]])

out = pd.concat(rows, ignore_index=True).rename(columns={
    HS_VAR: "educ_hs_or_higher_pct",
    BA_VAR: "educ_ba_or_higher_pct",
}).sort_values(["fips","year"])

out.to_csv("acs5_education_S1501_county_2010_2023.csv", index=False)
print("saved acs5_education_S1501_county_2010_2023.csv")
print(out.head())
