import pandas as pd
import glob
import os

state_fips = {
    "Alabama": ("AL", 1), "Alaska": ("AK", 2), "Arizona": ("AZ", 4), "Arkansas": ("AR", 5),
    "California": ("CA", 6), "Colorado": ("CO", 8), "Connecticut": ("CT", 9), "Delaware": ("DE", 10),
    "District of Columbia": ("DC", 11), "Florida": ("FL", 12), "Georgia": ("GA", 13), "Hawaii": ("HI", 15),
    "Idaho": ("ID", 16), "Illinois": ("IL", 17), "Indiana": ("IN", 18), "Iowa": ("IA", 19),
    "Kansas": ("KS", 20), "Kentucky": ("KY", 21), "Louisiana": ("LA", 22), "Maine": ("ME", 23),
    "Maryland": ("MD", 24), "Massachusetts": ("MA", 25), "Michigan": ("MI", 26), "Minnesota": ("MN", 27),
    "Mississippi": ("MS", 28), "Missouri": ("MO", 29), "Montana": ("MT", 30), "Nebraska": ("NE", 31),
    "Nevada": ("NV", 32), "New Hampshire": ("NH", 33), "New Jersey": ("NJ", 34), "New Mexico": ("NM", 35),
    "New York": ("NY", 36), "North Carolina": ("NC", 37), "North Dakota": ("ND", 38), "Ohio": ("OH", 39),
    "Oklahoma": ("OK", 40), "Oregon": ("OR", 41), "Pennsylvania": ("PA", 42), "Rhode Island": ("RI", 44),
    "South Carolina": ("SC", 45), "South Dakota": ("SD", 46), "Tennessee": ("TN", 47), "Texas": ("TX", 48),
    "Utah": ("UT", 49), "Vermont": ("VT", 50), "Virginia": ("VA", 51), "Washington": ("WA", 53),
    "West Virginia": ("WV", 54), "Wisconsin": ("WI", 55), "Wyoming": ("WY", 56)
}

folder = "/Users/okuran/Desktop/thesis/google_trend/raw_data_gt_single"
files = glob.glob(os.path.join(folder, "val_Chlamydia_*.csv"))

dfs = []
for file in files:
    df = pd.read_csv(file, skiprows=1)
    
    # eg. "Chlamydia: (Alaska)"
    value_col = df.columns[1]
    

    state_name = value_col.split("(")[-1].strip(")")
    state_abbr, fips = state_fips[state_name]
    
    df = df.rename(columns={df.columns[0]: "Date", df.columns[1]: "Index"})
    df["Date"] = pd.to_datetime(df["Date"], errors="coerce")
    df["State"] = state_abbr
    df["FIPS"] = fips
    
    dfs.append(df)


merged = pd.concat(dfs, ignore_index=True)
merged = merged.sort_values(by=["Date", "State"]).reset_index(drop=True)

merged.to_csv("merged_all_states.csv", index=False)

print(len(merged))
