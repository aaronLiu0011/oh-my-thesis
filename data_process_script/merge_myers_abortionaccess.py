import pandas as pd
import numpy as np

# ----------- Paths -----------
INPUT = "./raw_data/myers/2025.07.01_abortionaccess_countyxmonth.csv"
OUTPUT = "./master_data/ctrl_var_state/state_abortion_access_2010_2023.csv"

# ----------- Load -----------
df = pd.read_csv(INPUT, dtype={"origin_fips_code": str})

# ----------- Basic cleaning -----------
df["origin_fips_code"] = df["origin_fips_code"].str.zfill(5)
df["state"] = df["origin_fips_code"].str[:2]

# keep only required years
df = df[(df["year"] >= 2010) & (df["year"] <= 2023)]

# ensure numeric
df["origin_population"] = df["origin_population"].astype(float)
df["distance_origintodest"] = df["distance_origintodest"].astype(float)
df["dest_asp"] = df["dest_asp"].astype(float)

# ----------- Weighted state-year aggregates -----------
def wavg(g, col):
    return np.average(g[col], weights=g["origin_population"])

state_year = (
    df.groupby(["state", "year"])
      .apply(lambda g: pd.Series({
          "pop_weighted_distance": wavg(g, "distance_origintodest"),
          "pop_weighted_asp": wavg(g, "dest_asp"),
          "total_pop_15_44": g["origin_population"].sum()
      }))
      .reset_index()
)

# ----------- Transformations -----------
state_year["log_distance"] = np.log1p(state_year["pop_weighted_distance"])

bins = [0, 25, 50, 100, np.inf]
labels = ["0-25", "25-50", "50-100", "100+"]
state_year["distance_bin"] = pd.cut(
    state_year["pop_weighted_distance"],
    bins=bins, labels=labels, right=False
)

# ----------- Save -----------
state_year.to_csv(OUTPUT, index=False)
print("Saved:", OUTPUT)
print(state_year.head())
