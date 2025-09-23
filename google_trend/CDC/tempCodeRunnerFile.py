import pandas as pd
import numpy as np

file_chlamydia = "/Users/okuran/Desktop/thesis/google_trend/CDC/Chlamydia_state_2018_2023.csv"
file_gonorrhea = "/Users/okuran/Desktop/thesis/google_trend/CDC/Gonorrhea_state_2018_2023.csv"
file_syphilis = "/Users/okuran/Desktop/thesis/google_trend/CDC/Syphilis_state_2018_2023.csv"

na_values = ["Data Suppressed"]

df_chlamydia = pd.read_csv(file_chlamydia, na_values=na_values)
df_gonorrhea = pd.read_csv(file_gonorrhea, na_values=na_values)
df_syphilis = pd.read_csv(file_syphilis, na_values=na_values)

use_cols = ["Indicator", "Year", "FIPS", "Rate per 100000"]

df_chlamydia = df_chlamydia[use_cols]
df_gonorrhea = df_gonorrhea[use_cols]
df_syphilis = df_syphilis[use_cols]

df_all = pd.concat([df_chlamydia, df_gonorrhea, df_syphilis], ignore_index=True)

df_all = df_all.rename(columns={"Rate per 100000": "cdc_rate"})

df_all["cdc_rate"] = pd.to_numeric(df_all["cdc_rate"], errors="coerce")

df_wide = df_all.pivot_table(
    index=["Year", "FIPS"],
    columns="Indicator",
    values="cdc_rate",
    aggfunc="first"
).reset_index()

df_wide = df_wide.rename_axis(None, axis=1)

# total_rate
df_wide["total_rate"] = (
    df_wide["Chlamydia"].fillna(0) +
    df_wide["Gonorrhea"].fillna(0) +
    df_wide["Primary and Secondary Syphilis"].fillna(0)
)

df_wide = df_wide.round(2)

output_file = "All_STDs_state_2018_2023_with_total.csv"
df_wide.to_csv(output_file, index=False)

print("Saved:", output_file)
print(df_wide.head(10))
