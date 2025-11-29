library(data.table)
library(dplyr)
library(fixest)
library(ggplot2)
library(stringr)

#==========tool============
data_dir <- file.path(getwd(), "master_data")
outcome_dir <- file.path(getwd(), "master_data/STDs_state_gt")
ctrlVar_dir <- file.path(getwd(), "master_data/ctrl_var_state")

norm_fips <- function(x) {
  x <- as.character(x)
  x <- gsub("\\D", "", x)
  ifelse(nchar(x)==2, x, str_pad(x, 2, pad="0"))
}

to_int <- function(x) suppressWarnings(as.integer(as.character(x)))
NA_STR <- c("Data not available","Data suppressed","Suppressed","NA","")

#==========Load Data=========
#----------
# data type
# - fips: character
# - Year/Month: integer
#----------

## Outcome (Google Trends)

### y_1: Syphilis
sy <- fread(file.path(outcome_dir, "processed_Syphilis_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
sy <- sy |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m")),
    sy_index = as.numeric(value_scaled)
  )

### y_2: Gonorrhea
go <- fread(file.path(outcome_dir, "processed_Gonorrhea_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
go <- go |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m")),
    go_index = as.numeric(value_scaled)
  )

### y_3: Chlamydia
ch <- fread(file.path(outcome_dir, "processed_Chlamydia_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
ch <- ch |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m")),
    ch_index = as.numeric(value_scaled)
  )

#-------------
## treatment Variables
treatment <- fread(file.path(data_dir, "state_treatment_panel.csv"))

treatment <- treatment |>
  transmute(
    fips = norm_fips(fips),
    date = as.Date(month),
    treatment_date = as.Date(treat_date),
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m")),
    treat_year = format(treatment_date, "%Y"),
    treat_month = format(treatment_date, "%m"), 
    treated = treated,
    ever_treated = ever_treated
  )

#-------------
## Control Variables

### demographics
demo <- fread(file.path(ctrlVar_dir, "state_demographics_2010_2023.csv"))
demo <- demo |>
  transmute(
    year = as.numeric(YEAR),
    fips = norm_fips(STATEA),
    share_age_15_44 = as.numeric(share_age_15_44),
    share_male = as.numeric(share_male),
    share_black = as.numeric(share_black),
    share_married_15p = as.numeric(share_married_15p),
    share_ba_plus_25p = as.numeric(share_ba_plus_25p),
    share_hs_plus_25p = as.numeric(share_hs_plus_25p),
    poverty_rate = as.numeric(poverty_rate)
  )

### insurance
uninsured <- fread(file.path(ctrlVar_dir, "state_insurance_2010_2023.csv"))
uninsured <- uninsured |>
  transmute(
    fips = norm_fips(state),
    year = as.integer(year),
    uninsured_rate = as.numeric(uninsured_pct)/100
  )

acs <- left_join(demo, uninsured, by = c("year", "fips"))

acs2020 <- fread(file.path(ctrlVar_dir, "state_acs_2020.csv"))
acs2020 <- acs2020 |>
  transmute(
    year = as.numeric(year),
    fips = norm_fips(fips),
    share_age_15_44 = as.numeric(share_age_15_44),
    share_male = as.numeric(share_male),
    share_black = as.numeric(share_black),
    share_married_15p = as.numeric(share_married_15p),
    share_ba_plus_25p = as.numeric(share_ba_plus_25p),
    share_hs_plus_25p = as.numeric(share_hs_plus_25p),
    poverty_rate = as.numeric(poverty_rate),
    uninsured_rate = as.numeric(uninsured_rate)
  )

acs2024 <- fread(file.path(ctrlVar_dir, "state_acs_2024.csv"))
acs2024 <- acs2024 |>
  transmute(
    year = as.numeric(year),
    fips = norm_fips(fips),
    share_age_15_44 = as.numeric(share_age_15_44),
    share_male = as.numeric(share_male),
    share_black = as.numeric(share_black),
    share_married_15p = as.numeric(share_married_15p),
    share_ba_plus_25p = as.numeric(share_ba_plus_25p),
    share_hs_plus_25p = as.numeric(share_hs_plus_25p),
    poverty_rate = as.numeric(poverty_rate),
    uninsured_rate = as.numeric(uninsured_rate)
  )

acs <- bind_rows(acs,acs2020,acs2024)


### income
income <- fread(file.path(ctrlVar_dir, "state_percapita-income_2010_2025.csv"))
income <- income |>
  transmute(
    fips = norm_fips(fips),
    date = as.Date(month),
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m")),
    income_log = log(as.numeric(income))
  )


### temperature
temperture <- fread(file.path(ctrlVar_dir, "state_temperature_monthly_2018_2025.csv"))
temperture <- temperture |>
  transmute(
    fips = norm_fips(fips),
    year = as.integer(year),
    month = as.integer(month_num),
    temp = as.numeric(temp)
  )

### unemployment
unemp <- fread(file.path(ctrlVar_dir, "state_unemployment_2010_2024.csv"))
unemp <- unemp |>
  transmute(
    fips = norm_fips(state_fips),
    year = as.integer(year),
    month = month,
    unrate = as.numeric(urate)/100
  )

### internet use
internet <- fread(file.path(ctrlVar_dir, "state_internet_2018_2024.csv"))
internet <- internet |> 
  transmute(
    fips = norm_fips(state),
    year = as.integer(year),
    internet_use_pct = as.numeric(internet_use_pct)
  )

### COVID case
covid_case <- fread(file.path(ctrlVar_dir, "state_covid_cases_2020_2023.csv"))
covid_case <- covid_case |>
  transmute(
    fips = norm_fips(fips),
    year = as.integer(year),
    month = as.integer(month),
    covid_cases_per_100k = as.numeric(covid_cases_per_100k)) 


#==========Merge Panel=========
library(purrr)

y_panel <- reduce(
  list(sy, go, ch),
  full_join,
  by = c("fips", "date", "year", "month")
)

y_panel <- left_join(y_panel, treatment,
                     by = c("fips", "date", "year", "month"))

ctrl_monthly <- reduce(
  list(income, unemp, temperture, covid_case),
  full_join,
  by = c("fips", "year", "month")) |>
  left_join(acs, by = c("fips", "year")) |>
  left_join(internet, by = c("fips", "year")) |>
  mutate(covid_cases_per_100k = replace_na(covid_cases_per_100k, 0)) |>
  filter(year >= 2018) |>
  filter(fips != "00")

panel_gt <- left_join(y_panel, ctrl_monthly,
                      by = c("fips", "date", "year", "month"))

panel_gt <- panel_gt |> filter(year <= 2024) |> select(-date, -treatment_date)



# ========= generate time id ===========
base_year  <- 2018
base_month <- 1

panel_gt[, time_id := (year - base_year) * 12 + (month - base_month)]

panel_gt[, treat_time := ifelse(
  is.na(treat_year) | is.na(treat_month),
  0,
  (as.numeric(treat_year) - base_year) * 12 + (as.numeric(treat_month) - base_month)
)]

write.csv(panel_gt, "/Users/okuran/Desktop/thesis/master_data/state_panel_2018_2024.csv")


