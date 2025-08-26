import requests
import pandas as pd

url_county = (
    "https://api.census.gov/data/timeseries/poverty/saipe"
    "?get=NAME,SAEMHI_PT,STATE,COUNTY&for=county:*&time=from+2010+to+2023"
)
resp = requests.get(url_county)
print(f"SAIPE API status code: {resp.status_code}")
if resp.status_code != 200:
    raise RuntimeError("❌ Failed to fetch data from SAIPE API. Please check your network connection.")

data = resp.json()
print(f"Number of rows (including header): {len(data)}")

df = pd.DataFrame(data[1:], columns=data[0])

df["year"] = pd.to_numeric(df["time"], errors="coerce")

bad = df["year"].isna().sum()
if bad > 0:
    print(f"Warning: {bad} records failed to parse year and will be dropped")
    df = df.dropna(subset=["year"])

df["year"] = df["year"].astype("Int64")

df["SAEMHI_PT"] = pd.to_numeric(df["SAEMHI_PT"], errors="coerce")
df["fips"] = df["STATE"] + df["COUNTY"]
df = df[["year", "fips", "STATE", "COUNTY", "NAME", "SAEMHI_PT"]]
print(f"Cleaned {len(df)} records")

cpi = pd.read_csv("cpi_deflators_2010_2023_base2023.csv")
print(f"CPI year range: {cpi['year'].min()}–{cpi['year'].max()}")

out = df.merge(cpi[["year", "deflator"]], on="year", how="left")
missing_def = out["deflator"].isna().sum()
if missing_def:
    print(f"Warning: {missing_def} records missing deflator (year outside 2010–2023?)")
out["mhi_real_2023usd"] = out["SAEMHI_PT"] * out["deflator"]

out.to_csv("saipe_county_mhi_2010_2023_real2023usd.csv", index=False)
print("Saved: saipe_county_mhi_2010_2023_real2023usd.csv")
