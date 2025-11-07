import pandas as pd
import re
from glob import glob
from pathlib import Path

base = Path("/Users/okuran/Desktop/thesis/raw_data/nhgis0001_csv")
csv_files = sorted(glob(str(base / "*_state.csv")))
codebooks = sorted(glob(str(base / "*_codebook.txt")))

def parse_codebook(path):
    """从codebook提取 NHGIS code → 描述"""
    mapping = {}
    code = None
    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = re.search(r"NHGIS code:\s+([A-Z0-9]+)", line)
            if m:
                code = m.group(1)
            t = re.search(r"Table\s+\d+:\s+(.*)", line)
            if t and code:
                mapping[code] = t.group(1).strip()
                code = None
    return mapping

all_dfs = []

for csv_path, cb_path in zip(csv_files, codebooks):
    year_match = re.search(r"(\d{4})", csv_path)
    year = int(year_match.group(1)) if year_match else None
    prefix_map = parse_codebook(cb_path)
    df = pd.read_csv(csv_path, low_memory=False)

    keep = [c for c in df.columns if c.upper() in ["YEAR", "STATE", "STATEA"]]
    rename = {}

    for col in df.columns:
        m = re.match(r"^([A-Z0-9]{3,5})E\d{3}$", col)  # 匹配3-5位前缀+E+3位数字
        if m:
            prefix = m.group(1)
            if prefix in prefix_map:
                name = re.sub(r"[^a-z0-9]+", "_", prefix_map[prefix].lower()).strip("_")
                rename[col] = name
                keep.append(col)

    df = df[keep].rename(columns=rename)
    all_dfs.append(df)

panel = pd.concat(all_dfs, ignore_index=True)
panel.to_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_population_2010_2023.csv", index=False)
print("✅ Saved")
