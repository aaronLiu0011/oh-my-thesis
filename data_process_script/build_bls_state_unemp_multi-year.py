import requests
import pandas as pd

API_KEY = "YOUR_BLS_API"
url = "https://api.bls.gov/publicAPI/v2/timeseries/data/"
headers = {"Content-type": "application/json"}

state_fips = [f"{i:02d}" for i in range(1, 57) if i not in [3, 7, 14, 43, 52]]
series_ids = [f"LASST{fips}0000000000003" for fips in state_fips]

def fetch_series(series_batch):
    data = {
        "seriesid": series_batch,
        "startyear": "2010",
        "endyear": "2024",
        "registrationkey": API_KEY
    }
    return requests.post(url, json=data, headers=headers).json()

all_rows = []
for i in range(0, len(series_ids), 50):
    batch = series_ids[i:i+50]
    resp = fetch_series(batch)
    for s in resp["Results"]["series"]:
        sid = s["seriesID"]
        fips = sid[5:7]
        for item in s["data"]:
            if item["period"].startswith("M"):
                all_rows.append({
                    "seriesID": sid,
                    "state_fips": fips,
                    "year": int(item["year"]),
                    "month": int(item["period"][1:]),
                    "urate": float(item["value"])
                })

df = pd.DataFrame(all_rows)
df["date"] = pd.to_datetime(df[["year", "month"]].assign(day=1))
df = df.sort_values(["state_fips", "date"])

df.to_csv("state_unemployment_2010_2024_yearly.csv", index=False)
print("✅ Saved state_unemployment_2010_2024_yearly.csv")
print(df.head())
