import requests, pandas as pd

# ---- 1) 拉 SAIPE 州级名义中位收入 2010–2023 ----
url_state = (
    "https://api.census.gov/data/timeseries/poverty/saipe"
    "?get=NAME,SAEMHI_PT,STATE&for=state:*&time=from+2010+to+2023"
)
data_state = requests.get(url_state).json()
state_df = pd.DataFrame(data_state[1:], columns=data_state[0])
state_df["year"] = state_df["time"].str.extract(r"(\\d{4})").astype(int)
state_df["STATE"] = state_df["state"]
state_df["SAEMHI_PT"] = pd.to_numeric(state_df["SAEMHI_PT"], errors="coerce")
state_df = state_df[["year", "STATE", "NAME", "SAEMHI_PT"]]

# ---- 2) 读入 CPI 年均平减系数（基期 2023=100）----
cpi_y = pd.read_csv("cpi_deflators_2010_2023_base2023.csv")
# ---- 3) 合并并生成 2023 不变价 ----
out = state_df.merge(cpi_y[["year","deflator"]], on="year", how="left")
out["mhi_real_2023usd"] = out["SAEMHI_PT"] * out["deflator"]

out.to_csv("saipe_state_mhi_2010_2023_real2023usd.csv", index=False)
print("Saved: saipe_state_mhi_2010_2023_real2023usd.csv")