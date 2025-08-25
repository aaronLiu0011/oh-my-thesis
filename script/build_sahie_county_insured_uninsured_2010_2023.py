import requests
import pandas as pd
import time

print("=== SAHIE county insured/uninsured, 2010–2023 ===")

BASE = "https://api.census.gov/data/timeseries/healthins/sahie"
YEARS = range(2010, 2023 + 1)
API_KEY = None  # 可填你的 Census API key，提高稳定性

def fetch_year(y: int) -> pd.DataFrame:
    params = {
        "YEAR": str(y),           # 按年取，避免 time 参数格式问题
        "for": "county:*",
        "AGECAT": "0",
        "SEXCAT": "0",
        "RACECAT": "0",
        "IPRCAT": "0",
        "get": "NAME,STATE,COUNTY,YEAR,PCTIC_PT,PCTUI_PT",
    }
    if API_KEY:
        params["key"] = API_KEY

    r = requests.get(BASE, params=params, timeout=120)
    if r.status_code != 200:
        raise RuntimeError(f"{y} failed {r.status_code}: {r.text[:200]}")

    js = r.json()
    if not js or len(js) < 2:
        raise RuntimeError(f"{y} got empty payload")

    df = pd.DataFrame(js[1:], columns=js[0])

    # 1) 去重列（有时会出现重复 YEAR 等）
    df = df.loc[:, ~df.columns.duplicated()].copy()

    # 2) 解析年份列（YEAR 或 time）
    year_col = "YEAR" if "YEAR" in df.columns else ("time" if "time" in df.columns else None)
    if year_col is None:
        raise RuntimeError(f"{y} missing YEAR/time column; cols={list(df.columns)}")

    # 有极少数情况下 YEAR 列被重复返回，这里再兜底：若选择到 DataFrame，取第一列
    col_obj = df[year_col]
    if isinstance(col_obj, pd.DataFrame):
        col_obj = col_obj.iloc[:, 0]

    df["year"] = pd.to_numeric(col_obj, errors="coerce")

    # 转数值
    for c in ("PCTIC_PT", "PCTUI_PT"):
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")
        else:
            # 某年缺列就补 NA，避免中断
            df[c] = pd.NA

    # 构造 FIPS
    if not {"STATE", "COUNTY"}.issubset(df.columns):
        raise RuntimeError(f"{y} missing STATE/COUNTY columns; cols={list(df.columns)}")
    df["fips"] = df["STATE"] + df["COUNTY"]

    out = df[["year", "fips", "STATE", "COUNTY", "NAME", "PCTIC_PT", "PCTUI_PT"]].copy()
    # 丢掉 year 解析失败的
    out = out.dropna(subset=["year"])
    out["year"] = out["year"].astype("Int64")
    return out

all_parts = []
for y in YEARS:
    print(f"[{y}] 拉取中…", end=" ")
    try:
        part = fetch_year(y)
        all_parts.append(part)
        print(f"OK ({len(part)} 行)")
    except Exception as e:
        print(f"❌ {e}")
    time.sleep(0.3)

if not all_parts:
    raise SystemExit("没有成功获取任何年份的数据。")

out = pd.concat(all_parts, ignore_index=True).sort_values(["year", "fips"])
out.to_csv("sahie_county_insured_uninsured_2010_2023.csv", index=False)
print("✅ Saved: sahie_county_insured_uninsured_2010_2023.csv")
