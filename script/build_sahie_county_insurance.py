import requests
import pandas as pd
import time

print("=== SAHIE county insured/uninsured, 2010–2023 ===")

BASE = "https://api.census.gov/data/timeseries/healthins/sahie"
YEARS = range(2010, 2023 + 1)

def fetch_year(y: int) -> pd.DataFrame:
    params = {
        "YEAR": str(y),           # request by YEAR to avoid potential 'time' format issues
        "for": "county:*",
        "AGECAT": "0",
        "SEXCAT": "0",
        "RACECAT": "0",
        "IPRCAT": "0",
        "get": "NAME,STATE,COUNTY,YEAR,PCTIC_PT,PCTUI_PT",
    }

    r = requests.get(BASE, params=params, timeout=120)
    if r.status_code != 200:
        raise RuntimeError(f"{y} failed {r.status_code}: {r.text[:200]}")

    js = r.json()
    if not js or len(js) < 2:
        raise RuntimeError(f"{y} got empty payload")

    df = pd.DataFrame(js[1:], columns=js[0])

    # drop duplicated columns (defensive against rare API quirks)
    df = df.loc[:, ~df.columns.duplicated()].copy()

    # parse year column (prefer 'YEAR'; fall back to 'time' if needed)
    year_col = "YEAR" if "YEAR" in df.columns else ("time" if "time" in df.columns else None)
    if year_col is None:
        raise RuntimeError(f"{y} missing YEAR/time column; cols={list(df.columns)}")

    # in very rare cases the YEAR selection might yield a DataFrame; fallback to the first subcolumn
    col_obj = df[year_col]
    if isinstance(col_obj, pd.DataFrame):
        col_obj = col_obj.iloc[:, 0]

    df["year"] = pd.to_numeric(col_obj, errors="coerce")

    # convert numeric targets; if a column is missing in a given year, fill with NA to avoid breaking the pipeline
    for c in ("PCTIC_PT", "PCTUI_PT"):
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")
        else:
            df[c] = pd.NA

    # construct county FIPS as provided (STATE + COUNTY); keep behavior unchanged
    if not {"STATE", "COUNTY"}.issubset(df.columns):
        raise RuntimeError(f"{y} missing STATE/COUNTY columns; cols={list(df.columns)}")
    df["fips"] = df["STATE"] + df["COUNTY"]

    out = df[["year", "fips", "STATE", "COUNTY", "NAME", "PCTIC_PT", "PCTUI_PT"]].copy()
    # drop rows where year failed to parse
    out = out.dropna(subset=["year"])
    out["year"] = out["year"].astype("Int64")
    return out

all_parts = []
for y in YEARS:
    print(f"[{y}] fetching...", end=" ")
    try:
        part = fetch_year(y)
        all_parts.append(part)
        print(f"OK ({len(part)} rows)")
    except Exception as e:
        print(f"❌ {e}")
    time.sleep(0.3)

if not all_parts:
    raise SystemExit("No data was successfully fetched for any year.")

out = pd.concat(all_parts, ignore_index=True).sort_values(["year", "fips"])
out.to_csv("sahie_county_insured_uninsured_2010_2023.csv", index=False)
print("Saved: sahie_county_insured_uninsured_2010_2023.csv")