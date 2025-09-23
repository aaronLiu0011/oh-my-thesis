import pandas as pd
import glob
import os
from scipy.stats import pearsonr

state_fips = {
    "CA": 6,
    "TX": 48,
    "FL": 12,
    "IL": 17,
    "WA": 53,
    "WY": 56,
    "NY": 36
}

def process_gt_file(file_path):
    df = pd.read_csv(file_path)
    state_abbr = os.path.basename(file_path).split("_")[-1].split(".")[0]
    gt_col = df.columns[-1]
    df = df.rename(columns={gt_col: "gt_index"})
    df["Month"] = pd.to_datetime(df["Month"], format="%Y-%m")
    df["Year"] = df["Month"].dt.year
    annual = df.groupby("Year")["gt_index"].mean().reset_index()
    annual["state_abbr"] = state_abbr
    annual["FIPS"] = state_fips[state_abbr]
    return annual

def load_all_gt(folder, pattern="val_Syphilis_*.csv"):
    files = glob.glob(os.path.join(folder, pattern))
    all_data = pd.concat([process_gt_file(f) for f in files], ignore_index=True)
    return all_data

def load_cdc(file_path):
    df = pd.read_csv(file_path)
    df = df.rename(columns={"Rate per 100000": "cdc_rate"})
    df = df[["Year", "FIPS", "cdc_rate"]]
    return df

def merge_and_test(gt_data, cdc_data):
    merged = pd.merge(
        gt_data, 
        cdc_data, 
        on=["Year", "FIPS"], how="inner"
    )

    # correlation by FIPS
    results = []
    for f in merged["FIPS"].unique():
        sub = merged[merged["FIPS"] == f]
        if len(sub) > 2:
            from scipy.stats import pearsonr
            r, p = pearsonr(sub["gt_index"], sub["cdc_rate"])
            results.append({"FIPS": f, "r": r, "p": p})
    results = pd.DataFrame(results)

    # correlation overall
    r_all, p_all = pearsonr(merged["gt_index"], merged["cdc_rate"])

    return merged, results, (r_all, p_all)

if __name__ == "__main__":
    folder = "thesis/google_trend/validation"
    files = glob.glob(os.path.join(folder, "val_Syphilis_*.csv"))

    gt_data = pd.concat([process_gt_file(f) for f in files], ignore_index=True)

    cdc_data = load_cdc("google_trend/CDC/Syphilis_state_2018_2023.csv")

    merged, state_corr, overall_corr = merge_and_test(gt_data, cdc_data)

    print("逐州相关性：")
    print(state_corr)

    print("\n总体相关性：")
    print("r =", overall_corr[0], "p =", overall_corr[1])

    merged.to_csv("merged_syphilis_gt_cdc_fips.csv", index=False)

