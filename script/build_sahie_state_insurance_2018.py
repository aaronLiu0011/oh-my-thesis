import requests
import pandas as pd

# SAHIE API
url = "https://api.census.gov/data/timeseries/healthins/sahie"

# 参数：
# - AGECAT=2: 18-64 years
# - IPRCAT=0: all income levels
# - PCTIC_PT = insured rate, PCTUI_PT = uninsured rate
params = {
    "get": "NAME,PCTIC_PT,PCTUI_PT",
    "for": "state:*",
    "time": "2018",
    "AGECAT": "2",
    "IPRCAT": "0"
}

resp = requests.get(url, params=params)
data = resp.json()

df = pd.DataFrame(data[1:], columns=data[0])

df["PCTIC_PT"] = pd.to_numeric(df["PCTIC_PT"], errors="coerce")  # insured %
df["PCTUI_PT"] = pd.to_numeric(df["PCTUI_PT"], errors="coerce")  # uninsured %

df_out = df.rename(columns={
    "NAME": "state_name",
    "PCTIC_PT": "insured_pct",
    "PCTUI_PT": "uninsured_pct"
})[["state", "state_name", "insured_pct", "uninsured_pct"]]

df_out.to_csv("state_sahie2018_insurance.csv", index=False)

print("✅ Saved state_sahie2018_insurance.csv")
print(df_out.head())
