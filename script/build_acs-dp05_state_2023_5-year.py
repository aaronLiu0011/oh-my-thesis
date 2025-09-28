import requests
import pandas as pd

# ACS 2023 5-year DP05 (demographic and housing characteristics)
# check variables' codes at: https://api.census.gov/data/2023/acs/acs5/profile/variables.json

url = "https://api.census.gov/data/2023/acs/acs5/profile"
"""
DP05_0001E: Total population
DP05_0008PE: 15 to 19 years
DP05_0009PE: 20 to 24 years
DP05_0010PE: 25 to 34 years
DP05_0011PE: 35 to 44 years
DP05_0038PE: Black or African American alone
DP05_0076PE: HISPANIC OR LATINO AND RACE
"""

params = {
    "get": "NAME,DP05_0001E,DP05_0008PE,DP05_0009PE,DP05_0010PE,DP05_0011PE,DP05_0038PE,DP05_0076PE",
    "for": "state:*"
}
resp = requests.get(url, params=params)
data = resp.json()

df = pd.DataFrame(data[1:], columns=data[0])

cols = [c for c in df.columns if c not in ["NAME","state"]]
for c in cols:
    df[c] = pd.to_numeric(df[c], errors="coerce")


df["age_15_44"] = df["DP05_0008PE"] + df["DP05_0009PE"] + df["DP05_0010PE"] + df["DP05_0011PE"]
df["black_share"] = df["DP05_0038PE"]
df["hispanic_share"] = df["DP05_0076PE"]

df_out = df[["state","NAME","age_15_44","black_share","hispanic_share"]]
df_out.to_csv("state_acs2023_demographics.csv", index=False)

print("✅ Saved state_acs2023_demographics.csv")
print(df_out.head())
