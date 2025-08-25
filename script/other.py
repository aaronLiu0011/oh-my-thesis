# 处理merged_laucnty_unemployment.csv
import pandas as pd
df_un = pd.read_csv("/Users/okuran/Desktop/thesis/processed_data/merged_laucnty_unemployment.csv")
df_un['fips'] = df_un['fips'].astype(str).str.zfill(5)
df_un['state_fips'] = df_un['state_fips'].astype(str).str.zfill(2)


df_un = df_un.rename(columns={"county_name": "NAME"})
df_un['county_fips'] = df_un['fips'].astype(str).str[2:].str.zfill(3)

cols = list(df_un.columns)
new_order = ['year', 'fips', 'state_fips', 'county_fips'] + [c for c in cols if c not in ['year', 'fips', 'state_fips', 'county_fips']]
df_un = df_un[new_order]

output_path = "/Users/okuran/Desktop/thesis/processed_data/merged_laucnty_unemployment.csv"
df_un.to_csv(output_path, index=False)