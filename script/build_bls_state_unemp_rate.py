import requests
import pandas as pd

# BLS API Document: https://www.bls.gov/help/hlpforma.htm#LAUS

API_KEY = "YOUR_API_KEY"  # Required, get your own free key at https://www.bls.gov/developers/home.htm
url = "https://api.bls.gov/publicAPI/v2/timeseries/data/"
headers = {"Content-type": "application/json"}

state_fips = [f"{i:02d}" for i in range(1, 57) if i not in [3, 7, 14, 43, 52]]

series_ids = [f"LASST{fips}0000000000003" for fips in state_fips]

def fetch_series(series_batch):
    data = {
        "seriesid": series_batch,
        "startyear": "2018",
        "endyear": "2025",
        "registrationkey": API_KEY
    }
    resp = requests.post(url, json=data, headers=headers).json()
    return resp

all_rows = []
for i in range(0, len(series_ids), 50):  # BLS API limit: max 50 series per request
    batch = series_ids[i:i+50]
    resp_json = fetch_series(batch)

    for s in resp_json["Results"]["series"]:
        sid = s["seriesID"]
        state_fips = sid[5:7]
        for item in s["data"]:
            if item["period"].startswith("M"):  # M01..M12
                all_rows.append({
                    "seriesID": sid,
                    "state_fips": state_fips,
                    "year": int(item["year"]),
                    "month": int(item["period"][1:]),
                    "urate": float(item["value"])
                })

df = pd.DataFrame(all_rows)

if df.empty:
    raise RuntimeError("❌ No data retrieved. Check API key or series IDs.")

df["date"] = pd.to_datetime(df[["year", "month"]].assign(day=1))
df = df.sort_values(["state_fips", "date"])

df.to_csv("state_monthly_unemployment_2018_2025.csv", index=False)
print("✅ Saved state_monthly_unemployment_2018_2025.csv")
print(df.head())
