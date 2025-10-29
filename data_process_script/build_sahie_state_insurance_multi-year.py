import requests
import pandas as pd

url = "https://api.census.gov/data/timeseries/healthins/sahie"
frames = []

for year in range(2010, 2025):
    params = {
        "get": "NAME,PCTIC_PT,PCTUI_PT",
        "for": "state:*",
        "time": str(year),
        "AGECAT": "2",
        "IPRCAT": "0"
    }
    r = requests.get(url, params=params)
    if r.ok and r.text.strip().startswith('['):
        data = r.json()
        df = pd.DataFrame(data[1:], columns=data[0])
        df["year"] = year
        frames.append(df)
        print(f"{year} ok")
    else:
        print(f"{year} skipped")

df = pd.concat(frames, ignore_index=True)
df["PCTIC_PT"] = pd.to_numeric(df["PCTIC_PT"], errors="coerce")
df["PCTUI_PT"] = pd.to_numeric(df["PCTUI_PT"], errors="coerce")

df_out = df.rename(columns={
    "NAME": "state_name",
    "PCTIC_PT": "insured_pct",
    "PCTUI_PT": "uninsured_pct"
})[["year", "state", "state_name", "insured_pct", "uninsured_pct"]]

df_out.to_csv("state_sahie_insurance.csv", index=False)
print("✅ Saved state_sahie_insurance.csv")
print(df_out.head())