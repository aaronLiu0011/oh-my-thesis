import requests
import pandas as pd

# https://apps.bea.gov/api/_pdf/bea_web_service_api_user_guide.pdf

API_KEY = "YOUR_API_KEY"  # Required, get your own free key at https://www.bea.gov/resources/for-developers
BASE_URL = "https://apps.bea.gov/api/data/"

def fetch_bea(years, linecode=3, geo="STATE", freq="Q"):

    params = {
        "UserID": API_KEY,
        "method": "GetData",
        "datasetname": "Regional",
        "TableName": "SQINC",  # State Quarterly Personal Income
        "LineCode": linecode,
        "GeoFIPS": geo,
        "Year": ",".join(map(str, years)),
        "Frequency": freq,
        "ResultFormat": "json"
    }

    resp = requests.get(BASE_URL, params=params)
    resp_json = resp.json()

    results = resp_json.get("BEAAPI", {}).get("Results", {})
    if "Error" in results:
        print("❌ BEA API Error:", results["Error"])
        return pd.DataFrame()

    data = results.get("Data", [])
    df = pd.DataFrame(data)
    if df.empty:
        return df

    df["DataValue"] = pd.to_numeric(df["DataValue"].str.replace(",", ""), errors="coerce")
    df = df.rename(columns={
        "GeoFips": "fips",
        "GeoName": "state",
        "TimePeriod": "quarter",
        "DataValue": "per_capita_income"
    })
    df = df[["state", "fips", "quarter", "per_capita_income"]]

    return df


if __name__ == "__main__":
    df_2018_2024 = fetch_bea(list(range(2018, 2025)))

    df_2025 = fetch_bea([2025])
    if not df_2025.empty:
        df_2025 = df_2025[df_2025["quarter"].isin(["2025Q1", "2025Q2"])]

    df_all = pd.concat([df_2018_2024, df_2025], ignore_index=True)

    df_all.to_csv("bea_state_percapita_income_2018_2025.csv", index=False)
    print("✅ Saved bea_state_percapita_income_2018_2025.csv")
    print(df_all.head())