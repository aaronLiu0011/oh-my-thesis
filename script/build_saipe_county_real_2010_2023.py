import requests
import pandas as pd

print("=== Step 1: 请求 SAIPE API，获取 2010–2023 县级名义中位收入 ===")
url_county = (
    "https://api.census.gov/data/timeseries/poverty/saipe"
    "?get=NAME,SAEMHI_PT,STATE,COUNTY&for=county:*&time=from+2010+to+2023"
)
resp = requests.get(url_county)
print(f"SAIPE API 状态码: {resp.status_code}")
if resp.status_code != 200:
    raise RuntimeError("❌ 无法从 SAIPE API 获取数据，请检查网络连接")

data = resp.json()
print(f"数据行数（含表头）: {len(data)}")

print("=== Step 2: 转为 DataFrame 并清洗 ===")
df = pd.DataFrame(data[1:], columns=data[0])

# 方式 A：最直接——把 'time' 转为数值（推荐）
df["year"] = pd.to_numeric(df["time"], errors="coerce")

# 方式 B：若你坚持用正则，也务必用 r'(\\d{4})' 的正确形式：r'(\\d{4})' -> 错的
# df["year"] = df["time"].str.extract(r"(\d{4})")

bad = df["year"].isna().sum()
if bad > 0:
    print(f"警告：有 {bad} 条记录的年份解析失败，将被丢弃")
    df = df.dropna(subset=["year"])

# 用可空整型避免 astype(int) 因 NaN 报错
df["year"] = df["year"].astype("Int64")

df["SAEMHI_PT"] = pd.to_numeric(df["SAEMHI_PT"], errors="coerce")
df["fips"] = df["STATE"] + df["COUNTY"]
df = df[["year", "fips", "STATE", "COUNTY", "NAME", "SAEMHI_PT"]]
print(f"已整理 {len(df)} 条记录")

print("=== Step 3: 读取 CPI 平减（cpi_deflators_2010_2023_base2023.csv） ===")
cpi = pd.read_csv("cpi_deflators_2010_2023_base2023.csv")
print(f"CPI 年份范围: {cpi['year'].min()}–{cpi['year'].max()}")

print("=== Step 4: 合并 & 计算 2023 不变价 ===")
out = df.merge(cpi[["year", "deflator"]], on="year", how="left")
missing_def = out["deflator"].isna().sum()
if missing_def:
    print(f"警告：有 {missing_def} 条记录缺少平减系数（年份不在 2010–2023？）")
out["mhi_real_2023usd"] = out["SAEMHI_PT"] * out["deflator"]

print("=== Step 5: 保存结果 ===")
out.to_csv("saipe_county_mhi_2010_2023_real2023usd.csv", index=False)
print("✅ 已保存: saipe_county_mhi_2010_2023_real2023usd.csv")
