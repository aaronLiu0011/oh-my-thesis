import requests
import pandas as pd
import time

api_key = ""  # acquire from https://api.data.gov/signup/
BASE_URL = "https://api.usa.gov/crime/fbi/sapi/api"

state_fips = [
    "01","02","04","05","06","08","09","10","11","12",
    "13","15","16","17","18","19","20","21","22","23",
    "24","25","26","27","28","29","30","31","32","33",
    "34","35","36","37","38","39","40","41","42","44",
    "45","46","47","48","49","50","51","53","54","55","56"
]

records = []

for st in state_fips:
    url = f"{BASE_URL}/data/nibrs/violent-crime/offense/states/{st}/rate"
    params = {"from": 2018, "to": 2024, "API_KEY": api_key}
    
    resp = requests.get(url, params=params)
    if resp.status_code != 200:
        print(f"❌ Failed for {st}, status {resp.status_code}")
        continue
    
    data = resp.json().get("results", [])
    for d in data:
        records.append({
            "state": st,
            "year": d["data_year"],
            "violent_crime_rate": d["rate"]  # per 100k population
        })
    
    time.sleep(0.5)  

df = pd.DataFrame(records)

df.to_csv("state_violent_crime_rate_2018_2024.csv", index=False)
print("✅ Saved state_violent_crime_rate_2018_2024.csv")
print(df.head())
