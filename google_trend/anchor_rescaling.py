import os
import pandas as pd
import matplotlib.pyplot as plt
from glob import glob


ROOT_DIR = "/Users/okuran/Desktop/thesis/google_trend/raw_data_gt_group/10-5-2025_Syphilis"
OUTPUT_PATH = "processed_Syphilis_CA_anchor_scaled.csv"
ANCHOR_STATE = "California"

state_fips = {
    "Alabama": "01", "Alaska": "02", "Arizona": "04", "Arkansas": "05", "California": "06", "Colorado": "08",
    "Connecticut": "09", "Delaware": "10", "Florida": "12", "Georgia": "13", "Hawaii": "15", "Idaho": "16",
    "Illinois": "17", "Indiana": "18", "Iowa": "19", "Kansas": "20", "Kentucky": "21", "Louisiana": "22",
    "Maine": "23", "Maryland": "24", "Massachusetts": "25", "Michigan": "26", "Minnesota": "27",
    "Mississippi": "28", "Missouri": "29", "Montana": "30", "Nebraska": "31", "Nevada": "32",
    "New Hampshire": "33", "New Jersey": "34", "New Mexico": "35", "New York": "36", "North Carolina": "37",
    "North Dakota": "38", "Ohio": "39", "Oklahoma": "40", "Oregon": "41", "Pennsylvania": "42",
    "Rhode Island": "44", "South Carolina": "45", "South Dakota": "46", "Tennessee": "47", "Texas": "48",
    "Utah": "49", "Vermont": "50", "Virginia": "51", "Washington": "53", "West Virginia": "54",
    "Wisconsin": "55", "Wyoming": "56"
}

# === Step 1: Read all group files ===
csv_files = sorted(glob(os.path.join(ROOT_DIR, "*.csv")))
print(f"Found {len(csv_files)} CSV files.")

dfs = []
for file in csv_files:
    df = pd.read_csv(file, skiprows=1)
    df.columns = [c.strip() for c in df.columns]

    # Melt the wide file into long format
    long_df = df.melt(id_vars=["Month"], var_name="State", value_name="value")

    # Clean state names (extract text inside parentheses)
    long_df["State"] = long_df["State"].str.extract(r"\((.*?)\)").iloc[:, 0].str.strip()

    # Add FIPS
    long_df["FIPS"] = long_df["State"].map(state_fips)

    # Extract Group name from filename
    group_name = os.path.basename(file).split("_")[1]
    long_df["Group"] = group_name

    dfs.append(long_df)

# === Step 2: Combine all groups ===
data = pd.concat(dfs, ignore_index=True)
data["Month"] = pd.to_datetime(data["Month"], format="%Y-%m")

# === Step 3: Calculate California mean per group ===
california_means = (
    data[data["State"] == ANCHOR_STATE]
    .groupby("Group")["value"]
    .mean()
    .to_dict()
)

if "Group1" not in california_means:
    raise ValueError("Group1 must contain California data as the anchor reference.")

anchor_mean = california_means["Group1"]

# === Step 4: Compute scaling ratios relative to Group1 ===
scaling_factor = {g: v / anchor_mean for g, v in california_means.items()}
print("\nScaling ratios (California as anchor):")
for g, r in scaling_factor.items():
    print(f"{g}: {r:.3f}")

# === Step 5: Apply scaling ratios to all values ===
data["value_scaled"] = data.apply(lambda row: row["value"] / scaling_factor[row["Group"]], axis=1)
# Keep only Group1 for California
data = data[~((data["State"] == ANCHOR_STATE) & (data["Group"] != "Group1"))]

# === Step 6: Save output ===
data = data[["Month", "State", "FIPS", "value", "value_scaled"]]
data.to_csv(OUTPUT_PATH, index=False)

print(f"\n✅ Scaled dataset saved to: {OUTPUT_PATH}")

