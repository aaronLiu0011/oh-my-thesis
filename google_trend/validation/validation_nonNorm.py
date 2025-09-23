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
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    data_lines = [line.strip() for line in lines if "," in line and not line.startswith("Month")]

    data = [line.split(",") for line in data_lines]

    df = pd.DataFrame(data, columns=["Month", "gt_index"])

    df["Month"] = pd.to_datetime(df["Month"], format="%Y-%m")
    df["gt_index"] = pd.to_numeric(df["gt_index"], errors="coerce")

    df["Year"] = df["Month"].dt.year
    annual = df.groupby("Year")["gt_index"].mean().reset_index()

    state_abbr = os.path.basename(file_path).split("_")[-1].split(".")[0]
    annual["state_abbr"] = state_abbr
    annual["FIPS"] = state_fips[state_abbr]

    return annual

def load_cdc(file_path):
    df = pd.read_csv(file_path)
    df = df.rename(columns={"Rate per 100000": "cdc_rate"})
    df = df[["Year", "FIPS", "cdc_rate"]]
    return df

def merge_and_test(gt_data, cdc_data):
    merged = pd.merge(
        gt_data, 
        cdc_data, 
        on=["Year", "FIPS"], how="inner" # inner join to keep only matching records
    )

    merged["gt_index"] = pd.to_numeric(merged["gt_index"], errors="coerce")
    merged["cdc_rate"] = pd.to_numeric(merged["cdc_rate"], errors="coerce")

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
    folder = "/Users/okuran/Desktop/thesis/google_trend/validation"
    files_sy = glob.glob(os.path.join(folder, "val_Syphilis_*.csv"))
    files_go = glob.glob(os.path.join(folder, "val_Gonorrhea_*.csv"))
    files_ch = glob.glob(os.path.join(folder, "val_Chlamydia_*.csv"))
    file_all = glob.glob(os.path.join(folder, "val_STD_Testing_*.csv"))

    gt_data_sy = pd.concat([process_gt_file(f) for f in files_sy], ignore_index=True)
    gt_data_go = pd.concat([process_gt_file(f) for f in files_go], ignore_index=True)
    gt_data_ch = pd.concat([process_gt_file(f) for f in files_ch], ignore_index=True)
    gt_data_all = pd.concat([process_gt_file(f) for f in file_all], ignore_index=True)


    cdc_data_sy = load_cdc("google_trend/CDC/Syphilis_state_2018_2023.csv")
    cdc_data_go = load_cdc("google_trend/CDC/Gonorrhea_state_2018_2023.csv")
    cdc_data_ch = load_cdc("google_trend/CDC/Chlamydia_state_2018_2023.csv")
    cdc_data_all = load_cdc("google_trend/CDC/All_STDs_state_2018_2023_with_total.csv")


    merged_sy, state_corr_sy, overall_corr_sy = merge_and_test(gt_data_sy, cdc_data_sy)

    print("Syphilis Validation Results")
    print("Correlation by State:")
    print(state_corr_sy)
    print("\nOverall Correlation:")
    print("r =", overall_corr_sy[0], "p =", overall_corr_sy[1])

    merged_go, state_corr_go, overall_corr_go = merge_and_test(gt_data_go, cdc_data_go)

    print("\nGonorrhea Validation Results")
    print("\nCorrelation by State:")
    print(state_corr_go)
    print("\nOverall Correlation:")
    print("r =", overall_corr_go[0], "p =", overall_corr_go[1])

    merged_ch, state_corr_ch, overall_corr_ch = merge_and_test(gt_data_ch, cdc_data_ch)

    print("\nChlamydia Validation Results")
    print("\nCorrelation by State:")
    print(state_corr_ch)
    print("\nOverall Correlation:")
    print("r =", overall_corr_ch[0], "p =", overall_corr_ch[1])

    merged_all, state_corr_all, overall_corr_all = merge_and_test(gt_data_all, cdc_data_all)
    
    print("\nAll STDs Validation Results")
    print("\nCorrelation by State:")
    print(state_corr_all)
    print("\nOverall Correlation:")
    print("r =", overall_corr_all[0], "p =", overall_corr_all[1])
