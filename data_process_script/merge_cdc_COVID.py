import pandas as pd

file_path = "/Users/okuran/Desktop/thesis/raw_data/Weekly_United_States_COVID-19_Cases_and_Deaths_by_State_-_ARCHIVED_20251114.csv"
df = pd.read_csv(file_path)

df['start_date'] = pd.to_datetime(df['start_date'])
df['end_date'] = pd.to_datetime(df['end_date'])


df['new_cases'] = (
    df['new_cases']
        .astype(str)
        .str.replace(",", "")
        .astype(float)
)

df['year'] = df['end_date'].dt.year
df['month'] = df['end_date'].dt.month

state_fips = {
    "AL": 1,  "AK": 2,  "AZ": 4,  "AR": 5,  "CA": 6,  "CO": 8,
    "CT": 9,  "DE": 10, "FL": 12, "GA": 13, "HI": 15, "ID": 16,
    "IL": 17, "IN": 18, "IA": 19, "KS": 20, "KY": 21, "LA": 22,
    "ME": 23, "MD": 24, "MA": 25, "MI": 26, "MN": 27, "MS": 28,
    "MO": 29, "MT": 30, "NE": 31, "NV": 32, "NH": 33, "NJ": 34,
    "NM": 35, "NY": 36, "NC": 37, "ND": 38, "OH": 39, "OK": 40,
    "OR": 41, "PA": 42, "RI": 44, "SC": 45, "SD": 46, "TN": 47,
    "TX": 48, "UT": 49, "VT": 50, "VA": 51, "WA": 53, "WV": 54,
    "WI": 55, "WY": 56, "DC": 11
}

df['fips'] = df['state'].map(state_fips)

monthly = (
    df.groupby(['state', 'fips', 'year', 'month'], as_index=False).agg(new_cases_monthly=('new_cases', 'sum'))
)

pop = pd.read_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_population_2010_2023.csv")

pop.rename(columns={'total_population': 'population', 'YEAR': 'year'}, inplace=True)

df = monthly.merge(pop[['fips', 'year', 'population']],
                    on=['fips', 'year'],
                    how='left')

df['covid_cases_per_100k'] = df['new_cases_monthly'] / df['population'] * 100000

df = df.sort_values(["state", "year", "month"])

df.to_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_covid_cases_2020_2023.csv", index=False)

df.head()

