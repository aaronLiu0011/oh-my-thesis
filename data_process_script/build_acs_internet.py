import requests
import pandas as pd
import time

years = range(2018, 2025)
base_url = "https://api.census.gov/data/{year}/acs/acs1/profile"
url_2020 = "https://api.census.gov/data/2020/acs/acs5/profile"


def internet_var(year):
    if year == 2018:
        return "DP02_0152PE"
    elif year == 2019:
        return "DP02_0153PE"
    elif year >= 2020:
        return "DP02_0154PE"
    else:
        return None

def fetch_acs1(year):

    iv = internet_var(year)

    if year != 2020:
        url = base_url.format(year=year)
    else:
        url = url_2020

    params = {"get": f"NAME,{iv}", "for": "state:*"}
    r = requests.get(url, params=params)
    if r.status_code != 200:
        print(f"❌ Failed {year}, status code: {r.status_code}")
        return None

    data = r.json()
    df = pd.DataFrame(data[1:], columns=data[0])

    df["internet_use_pct"] = df[iv] if iv else pd.NA
    df["year"] = year

    df_out = df[[
        "year", "state", "internet_use_pct"
    ]]

    print(f"✅ {year}")
    return df_out


all_years = []
for y in years:
    d = fetch_acs1(y)
    if d is not None:
        all_years.append(d)
    time.sleep(0.4)

acs = pd.concat(all_years, ignore_index=True)
acs.to_csv("state_internet_2018_2024.csv", index=False)
print("✅ saved.")