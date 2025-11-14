import requests
import pandas as pd

# ACS 2023 5-year DP05 (demographic and housing characteristics)
# check variables' codes at: https://api.census.gov/data/2020/acs/acs5/profile/variables.json

url = "https://api.census.gov/data/2020/acs/acs5/profile"
"""
DP05_0001E: Total population
DP05_0002PE: male population percentage
DP05_0008PE: 15 to 19 years
DP05_0009PE: 20 to 24 years
DP05_0010PE: 25 to 34 years
DP05_0011PE: 35 to 44 years
DP05_0038PE: Black or African American alone
"""

params = {
    "get": "NAME,DP05_0001E,DP05_0002PE,DP05_0008PE,DP05_0009PE,DP05_0010PE,DP05_0011PE,DP05_0038PE",
    "for": "state:*"
}
resp = requests.get(url, params=params)
data = resp.json()

df = pd.DataFrame(data[1:], columns=data[0])

cols = [c for c in df.columns if c not in ["NAME","state"]]
for c in cols:
    df[c] = pd.to_numeric(df[c], errors="coerce")


df["share_age_15_44"] = df["DP05_0008PE"] + df["DP05_0009PE"] + df["DP05_0010PE"] + df["DP05_0011PE"]
df['share_male'] = df['DP05_0002PE']
df["share_black"] = df["DP05_0038PE"]
df['year'] = 2020
df['fips'] = df['state'].astype(str).str.zfill(2)
df['STATE'] = df['NAME']

df_out = df[["year","fips","STATE","share_age_15_44","share_male","share_black"]]
df_out.to_csv("state_demographics_2020.csv", index=False)

pop = pd.read_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_population_2010_2023.csv")
pop['fips'] = pop['fips'].astype(str).str.zfill(2)

df_pop = df[["fips","NAME", "DP05_0001E"]].rename(columns={"DP05_0001E": "total_population",
                                                    "NAME": "STATE"})
df_pop['YEAR'] = 2020

pop = pd.concat([pop, df_pop[['YEAR', 'STATE', 'fips', 'total_population']]], ignore_index=True)

pop.to_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_population_2010_2023.csv", index=False)

print("✅ Saved")
print(df_out.head())
print(pop.head())
