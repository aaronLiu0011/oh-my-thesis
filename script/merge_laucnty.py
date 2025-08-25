import pandas as pd
import glob, re, os

files = glob.glob("laucnty*.xlsx")

def read_laucnty(fp):
    # 1) 读成无表头，然后找到真正的表头行（包含 "LAUS Code"）
    tmp = pd.read_excel(fp, header=None, dtype=str, engine="openpyxl")
    header_row = tmp.apply(lambda row: row.astype(str).str.contains(r"^LAUS Code$", na=False)).any(axis=1).idxmax()
    df = pd.read_excel(fp, header=header_row, dtype=str, engine="openpyxl")

    # 2) 规范列名
    rename = {
        "LAUS Code": "laus_code",
        "State FIPS Code": "state_fips",
        "County FIPS Code": "county_fips3",
        "County Name/State Abbreviation": "county_state",
        "Year": "year",
        "Labor Force": "labor_force",
        "Employed": "employed",
        "Unemployed": "unemployed",
        "Unemployment Rate (%)": "unemp_rate_pct",
    }
    df = df.rename(columns=rename)

    # 3) 清洗
    # 年份：优先用列里的 Year；若缺失则从文件名 laucntyYY.xlsx 推断 20YY
    df["year"] = df["year"].str.extract(r"(\d{4})", expand=False)
    if df["year"].isna().all():
        m = re.search(r"laucnty(\d{2})", os.path.basename(fp))
        df["year"] = "20" + m.group(1) if m else pd.NA
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")

    # 州/县 FIPS：补零拼接成5位
    df["state_fips"] = df["state_fips"].str.replace(r"\D", "", regex=True).str.zfill(2)
    df["county_fips3"] = df["county_fips3"].str.replace(r"\D", "", regex=True).str.zfill(3)
    df["county_fips"] = (df["state_fips"] + df["county_fips3"]).where(df["state_fips"].notna() & df["county_fips3"].notna())

    # 县名与州简称分列
    county = df["county_state"].fillna("").str.strip()
    df["county_name"] = county.str.replace(r",\s*[A-Z]{2}$", "", regex=True)
    df["state_abbr"] = county.str.extract(r",\s*([A-Z]{2})$", expand=False)

    # 数值列去逗号 → 数值
    for c in ["labor_force", "employed", "unemployed"]:
        df[c] = pd.to_numeric(df[c].str.replace(",", "", regex=False), errors="coerce")

    # 失业率：去掉%并转成数值；如缺失则用 unemployed / labor_force * 100
    df["unemp_rate"] = pd.to_numeric(df["unemp_rate_pct"].astype(str).str.replace("%", "", regex=False), errors="coerce")
    need_fill = df["unemp_rate"].isna() & df["unemployed"].notna() & df["labor_force"].gt(0)
    df.loc[need_fill, "unemp_rate"] = (df.loc[need_fill, "unemployed"] / df.loc[need_fill, "labor_force"] * 100).round(2)

    # 输出所需列
    out = df.loc[:, ["year", "county_fips", "state_fips", "state_abbr", "county_name",
                     "labor_force", "employed", "unemployed", "unemp_rate"]].copy()

    # 基本过滤
    out = out.dropna(subset=["county_fips"]).drop_duplicates(subset=["year", "county_fips"])
    return out

frames = [read_laucnty(fp) for fp in files]
final = pd.concat(frames, ignore_index=True).sort_values(["year", "county_fips"])
final.to_csv("merged_laucnty_unemployment.csv", index=False)
print("已导出 merged_laucnty_unemployment.csv，形状：", final.shape)
