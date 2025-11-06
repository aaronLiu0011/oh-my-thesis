import requests
import pandas as pd
import time

years = range(2010, 2025)
base_url = "https://api.census.gov/data/{year}/acs/acs1/profile"

def hs_var(year):
    return "DP02_0066PE" if year <= 2018 else "DP02_0067PE"

def ba_var(year):
    return "DP02_0067PE" if year <= 2018 else "DP02_0068PE"

def internet_var(year):
    if 2013 <= year <= 2019:
        return "DP02_0152PE"
    elif year >= 2020:
        return "DP02_0153PE"
    else:
        return None

def marriage_vars(year):
    if year <= 2011:
        return {
            "married": ["DP02_0026PE"],
            "never": ["DP02_0025PE"]
        }
    elif 2012 <= year <= 2017:
        return {
            "married": ["DP02_0026PE", "DP02_0032PE"],
            "never": ["DP02_0025PE", "DP02_0031PE"]
        }
    else: # 2018+
        return {
            "married": ["DP02_0027PE", "DP02_0033PE"],
            "never": ["DP02_0026PE", "DP02_0032PE"]
        }

def fetch_acs1(year):
    hv = hs_var(year)
    bv = ba_var(year)
    iv = internet_var(year)
    mv = marriage_vars(year)

    vars_use = [hv, bv] + mv["married"] + mv["never"]
    if iv:
        vars_use.append(iv)

    url = base_url.format(year=year)
    params = {"get": "NAME," + ",".join(vars_use), "for": "state:*"}
    r = requests.get(url, params=params)
    if r.status_code != 200:
        print(f"❌ Failed {year}")
        return None

    data = r.json()
    df = pd.DataFrame(data[1:], columns=data[0])

    for v in vars_use:
        df[v] = pd.to_numeric(df[v], errors="coerce")

    # aggregation
    df["married_pct"] = df[mv["married"]].mean(axis=1)
    df["never_married_pct"] = df[mv["never"]].mean(axis=1)
    df["internet_use_pct"] = df[iv] if iv else pd.NA
    df["year"] = year

    df_out = df[[
        "year", "state", "NAME", hv, bv,
        "married_pct", "never_married_pct", "internet_use_pct"
    ]].rename(columns={hv: "educ_hs_or_higher_pct",
                        bv: "educ_ba_or_higher_pct"})

    print(f"✅ {year}")
    return df_out


all_years = []
for y in years:
    d = fetch_acs1(y)
    if d is not None:
        all_years.append(d)
    time.sleep(0.4)

acs = pd.concat(all_years, ignore_index=True)
acs.to_csv("state_social_char_2010_2024.csv", index=False)
print("✅ saved.")