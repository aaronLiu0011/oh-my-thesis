import requests
import pandas as pd

# ACS 2023 5-year DP02 (Social Characteristics)
# check variables' codes at: https://api.census.gov/data/2020/acs/acs5/profile/variables.json

url = "https://api.census.gov/data/2020/acs/acs5/profile"

variables = [
    "DP02_0067PE",  # High school graduate or higher
    "DP02_0068PE",  # Bachelor's degree or higher
    "DP02_0027PE",  # Now married (male, 15+)
    "DP02_0033PE",  # Now married (female, 15+)
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
df["share_married_15p"] = (df["DP02_0027PE"] + df["DP02_0033PE"]) / 2
df['fips'] = df['state'].astype(str).str.zfill(2)

df_out = df[["fips","NAME","DP02_0067PE","DP02_0068PE","share_married_15p"]].rename(
    columns={
        "DP02_0067PE": "share_hs_plus_25p",
        "DP02_0068PE": "share_ba_plus_25p"}
)

demo = pd.read_csv("/Users/okuran/Desktop/thesis/state_demographics_2020.csv")
demo["fips"] = demo["fips"].astype(str).str.zfill(2)

demo = demo.merge(df_out[['fips', 'share_married_15p', 'share_hs_plus_25p', 'share_ba_plus_25p']], on=['fips'], how='left')

demo.to_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_demographics_2020.csv", index=False)

print("✅ Saved")
print(demo.head())
