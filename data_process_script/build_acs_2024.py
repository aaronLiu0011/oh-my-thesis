import requests
import pandas as pd

# check variables' codes at: https://api.census.gov/data/2024/acs/acs1/profile/variables.json

url = "https://api.census.gov/data/2024/acs/acs1/profile"

variables = [
    "DP05_0001E",   # Total population
    "DP05_0002PE",  # male population percentage
    "DP05_0008PE",  # 15 to 19 years
    "DP05_0009PE",  # 20 to 24 years
    "DP05_0010PE",  # 25 to 34 years
    "DP05_0011PE",  # 35 to 44 years
    "DP05_0045PE",  # Black or African American alone
    "DP02_0067PE",  # High school graduate or higher
    "DP02_0068PE",  # Bachelor's degree or higher
    "DP02_0027PE",  # Now married (male, 15+)
    "DP02_0033PE",  # Now married (female, 15+)
    "DP03_0128PE",  # Poverty rate
    "DP03_0099PE"   # Unininsured percentage
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



df["share_age_15_44"] = (df["DP05_0008PE"] + df["DP05_0009PE"] + df["DP05_0010PE"] + df["DP05_0011PE"])/100
df['share_male'] = df['DP05_0002PE']/100
df["share_black"] = df["DP05_0045PE"]/100
df["share_married_15p"] = (df["DP02_0027PE"] + df["DP02_0033PE"]) / 200
df["share_hs_plus_25p"] = df["DP02_0067PE"]/100
df["share_ba_plus_25p"] = df["DP02_0068PE"]/100
df["poverty_rate"] = df["DP03_0128PE"] /100
df["uninsured_rate"] = df["DP03_0099PE"] /100

df['fips'] = df['state'].astype(str).str.zfill(2)
df['year'] = 2024 
df['STATE'] = df['NAME']


df_out = df[["year","fips","STATE","share_age_15_44","share_male","share_black",
                "share_married_15p","share_hs_plus_25p","share_ba_plus_25p",
                "poverty_rate","uninsured_rate"]]


df_out.to_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_acs_2024.csv", index=False)

print("✅ Saved")
print(df_out.head())
