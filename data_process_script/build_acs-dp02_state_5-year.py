import requests
import pandas as pd

# ACS 2023 5-year DP02 (Social Characteristics)
# check variables' codes at: https://api.census.gov/data/2023/acs/acs5/profile/variables.json

url = "https://api.census.gov/data/2023/acs/acs5/profile"

variables = [
    "DP02_0067PE",  # High school graduate or higher
    "DP02_0068PE",  # Bachelor's degree or higher
    "DP02_0027PE",  # Now married (male, 15+)
    "DP02_0033PE",  # Now married (female, 15+)
    "DP02_0026PE",  # Never married (male, 15+)
    "DP02_0032PE",  # Never married (female, 15+)
    "DP02_0038PE"   # Unmarried women 15-50 with a birth in past 12 months
]

params = {
    "get": "NAME," + ",".join(variables),
    "for": "state:*"
}

resp = requests.get(url, params=params)
data = resp.json()
df = pd.DataFrame(data[1:], columns=data[0])

for v in variables:
    df[v] = pd.to_numeric(df[v], errors="coerce")

# simple average
df["married_pct"] = (df["DP02_0027PE"] + df["DP02_0033PE"]) / 2
df["never_married_pct"] = (df["DP02_0026PE"] + df["DP02_0032PE"]) / 2

df_out = df[["state","NAME","DP02_0067PE","DP02_0068PE","married_pct","never_married_pct","DP02_0038PE"]].rename(
    columns={
        "DP02_0067PE": "educ_hs_or_higher_pct",
        "DP02_0068PE": "educ_ba_or_higher_pct",
        "DP02_0038PE": "unmarried_birth_pct"}
)

df_out.to_csv("state_acs2023_social_char.csv", index=False)

print("✅ Saved state_acs2023_social_char.csv")
print(df_out.head())
