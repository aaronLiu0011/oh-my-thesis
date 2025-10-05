import requests
import pandas as pd

BASE = "https://api.census.gov/data/timeseries/poverty/saipe"

params = {
    "get": "NAME,SAEPOVRTALL_PT,SAEPOVRTALL_MOE,SAEPOVALL_PT,SAEPOVALL_MOE",
    "for": "county:*",
    "in": "state:*",
    "time": "from 2010 to 2023"
}

resp = requests.get(BASE, params=params, timeout=60)
if resp.status_code != 200:
    raise RuntimeError(f"❌ Request ERROR: {resp.status_code}\nURL={resp.url}\n{resp.text}")

data = resp.json()
df = pd.DataFrame(data[1:], columns=data[0])

df["year"] = pd.to_numeric(df["time"], errors="coerce")

df["poverty_rate"]  = pd.to_numeric(df["SAEPOVRTALL_PT"], errors="coerce")  # 百分比
df["poverty_count"] = pd.to_numeric(df["SAEPOVALL_PT"], errors="coerce")    # 人数

df["fips"] = df["state"] + df["county"]

out = df[[
    "fips","NAME","year",
    "poverty_rate","SAEPOVRTALL_MOE",
    "poverty_count","SAEPOVALL_MOE"
]].rename(columns={
    "SAEPOVRTALL_MOE":"poverty_rate_moe",
    "SAEPOVALL_MOE":"poverty_count_moe"
}).sort_values(["fips","year"])

print(out.head(10))
out.to_csv("saipe_county_poverty_2010_2023.csv", index=False)
print("✅ Saved: saipe_county_poverty_2010_2023.csv")
