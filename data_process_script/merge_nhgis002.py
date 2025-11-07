import pandas as pd
import re
from glob import glob
from pathlib import Path

base = Path("/Users/okuran/Desktop/thesis/raw_data/nhgis0002_csv")
csvs = sorted(glob(str(base / "*_state.csv")))
codebooks = sorted(glob(str(base / "*_codebook.txt")))


# 取某表的 NHGIS 前缀（如 B01001 -> 'IG4' 或 'LII'）
def get_prefix(cb_path, source_code):
    p_src = re.compile(r"Source code:\s*([A-Z0-9]+)")
    p_nhg = re.compile(r"NHGIS code:\s*([A-Z0-9]+)")
    last_src = None
    with open(cb_path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            m1 = p_src.search(line);  m2 = p_nhg.search(line)
            if m1: last_src = m1.group(1)
            if m2 and last_src == source_code:
                return m2.group(1)
    raise ValueError(f"Prefix for {source_code} not found in {cb_path}")

def col(pref, suf):  # 组列名
    return f"{pref}E{suf:03d}"

all_df = []
for csv_path, cb_path in zip(csvs, codebooks):
    year = int(re.search(r"(\d{4})", csv_path).group(1))
    df = pd.read_csv(csv_path, low_memory=False)

    # 前缀
    p_age = get_prefix(cb_path, "B01001")   # Sex by Age
    p_race = get_prefix(cb_path, "B02001")  # Race
    p_marr = get_prefix(cb_path, "B12001")  # Marital Status 15+
    p_edu = get_prefix(cb_path, "B15003")   # Education 25+
    p_pov = get_prefix(cb_path, "B17002")   # Poverty ratio

    # 安全：缺列填 0
    def g(c): return df[c] if c in df.columns else 0

    total = g(col(p_age, 1))  # B01001 Total
    male  = g(col(p_age, 2))

    male_15_44 = sum(g(col(p_age, k)) for k in [6,7,8,9,10,11,12,13,14])
    fem_15_44  = sum(g(col(p_age, k)) for k in [30,31,32,33,34,35,36,37,38])

    black = g(col(p_race, 3))
    race_tot = g(col(p_race, 1))

    marr_tot = g(col(p_marr, 1))
    marr_now = g(col(p_marr, 4)) + g(col(p_marr, 13))

    edu_tot = g(col(p_edu, 1))
    hs_plus = sum(g(col(p_edu, k)) for k in range(17, 26))
    ba_plus = sum(g(col(p_edu, k)) for k in range(22, 26))

    pov_tot = g(col(p_pov, 1))
    pov_num = g(col(p_pov, 2)) + g(col(p_pov, 3)) + g(col(p_pov, 4))

    out = pd.DataFrame({
        "YEAR": df["YEAR"],
        "STATE": df["STATE"],
        "STATEA": df["STATEA"],
        "share_age_15_44": (male_15_44 + fem_15_44) / total,
        "share_male": male / total,
        "share_black": black / race_tot,
        "share_married_15p": marr_now / marr_tot,
        "share_hs_plus_25p": hs_plus / edu_tot,
        "share_ba_plus_25p": ba_plus / edu_tot,
        "poverty_rate": pov_num / pov_tot,
    })
    all_df.append(out)

panel = pd.concat(all_df, ignore_index=True)
panel.to_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_acs_2010_2023.csv", index=False)
print("✅ Saved")
