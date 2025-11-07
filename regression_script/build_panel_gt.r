library(data.table)
library(dplyr)
library(fixest)
library(ggplot2)
library(stringr)

#==========tool============
data_dir <- file.path(getwd(), "master_data")
ctrlVar_dir <- file.path(getwd(), "master_data/ctrl_var_state_2018_2025")

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
sy <- fread(file.path(data_dir, "10-5_processed_Syphilis_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
sy <- sy |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    Year = as.integer(format(date, "%Y")),
    Month = as.integer(format(date, "%m")),
    sy_index = as.numeric(value_scaled)
  )

### y_2: Gonorrhea
go <- fread(file.path(data_dir, "10-5_processed_Gonorrhea_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
go <- go |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    Year = as.integer(format(date, "%Y")),
    Month = as.integer(format(date, "%m")),
    go_index = as.numeric(value_scaled)
  )

### y_3: Chlamydia
ch <- fread(file.path(data_dir, "10-5_processed_Chlamydia_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
ch <- ch |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    Year = as.integer(format(date, "%Y")),
    Month = as.integer(format(date, "%m")),
    ch_index = as.numeric(value_scaled)
  )

#-------------
## treatment Variables
treatment <- fread(file.path(data_dir, "state_treatment_treatment_panel.csv"))

treatment <- treatment |>
  transmute(
    fips = norm_fips(fips),
    date = as.Date(month),
    treatment_date = as.Date(treat_date),
    Year = as.integer(format(date, "%Y")),
    Month = as.integer(format(date, "%m")),
    treat_year = format(treatment_date, "%Y"),
    treat_month = format(treatment_date, "%m"), 
    treated = treated,
    ever_treated = ever_treated
  )

#-------------
## Control Variables

### congregation
congregation <- fread(file.path(ctrlVar_dir, "state_congregation_2020.csv"))
congregation <- congregation |>
  transmute(
    fips = norm_fips(`State Code`),
    Cong_per_100000 = as.numeric(`Congregations per 100,000 Population`)
  )

### demographics
demo <- fread(file.path(ctrlVar_dir, "state_demographics_2023-5-year.csv"))
demo <- demo |>
  transmute(
    fips = norm_fips(state),
    age_15_44 = as.numeric(age_15_44),
    black_share = as.numeric(black_share),
    hispanic_share = as.numeric(hispanic_share)
  )

### insurance
uninsured <- fread(file.path(ctrlVar_dir, "state_insurance_2018.csv"))
uninsured <- uninsured |>
  transmute(
    fips = norm_fips(state),
    uninsured_pct = as.numeric(uninsured_pct)
  )

### income
income <- fread(file.path(ctrlVar_dir, "state_income_monthly_long.csv"))
income <- income |>
  transmute(
    fips = norm_fips(fips),
    date = as.Date(month),
    Year = as.integer(format(date, "%Y")),
    Month = as.integer(format(date, "%m")),
    percapita_income = as.numeric(income)
  )

### physician rate
physician <- fread(file.path(ctrlVar_dir, "state_physician_rate_2019.csv"))
physician <- physician |>
  transmute(
    fips = norm_fips(FIPS),
    physician_rate = as.numeric(`Rate (per 100,000 population)`)
  )

### social char
social <- fread(file.path(ctrlVar_dir, "state_social_char_2023-5-year.csv"))
social <- social |>
  transmute(
    fips = norm_fips(state),
    highschool = as.numeric(educ_hs_or_higher_pct),
    bachelor = as.numeric(educ_ba_or_higher_pct),
    married = as.numeric(married_pct),
    never_married = as.numeric(never_married_pct),
    unmarried_birth = as.numeric(unmarried_birth_pct)
  )

### temperature
temperture <- fread(file.path(ctrlVar_dir, "state_temperature_monthly_2018_2025.csv"))
temperture <- temperture |>
  transmute(
    fips = norm_fips(fips),
    Year = as.integer(year),
    Month = as.integer(month_num),
    temp = as.numeric(temp)
  )

### unemployment
unemp <- fread(file.path(ctrlVar_dir, "state_unemployment_monthly_2018_2025.csv"))
unemp <- unemp |>
  transmute(
    fips = norm_fips(state_fips),
    Year = year,
    Month = month,
    urate = as.numeric(urate)
  )


#==========Merge Panel=========
library(purrr)

y_panel <- reduce(
  list(sy, go, ch),
  full_join,
  by = c("fips", "date", "Year", "Month")
)

y_panel <- left_join(y_panel, treatment,
                     by = c("fips", "date", "Year", "Month"))

# time-variant controls
ctrl_monthly <- reduce(
  list(income, temperture, unemp),
  full_join,
  by = c("fips", "Year", "Month")
)

# time-invariant controls
ctrl_static <- reduce(
  list(congregation, demo, uninsured, social, physician),
  full_join,
  by = "fips"
)

panel <- y_panel |>
  left_join(ctrl_monthly, by = c("fips", "Year", "Month")) |>
  left_join(ctrl_static, by = "fips")

panel <- panel |> select(-date.x, -date.y)

base_year  <- 2018
base_month <- 1

panel[, time_id := (Year - base_year) * 12 + (Month - base_month)]

panel[, treat_time := ifelse(
  is.na(treat_year) | is.na(treat_month),
  0,
  (as.numeric(treat_year) - base_year) * 12 + (as.numeric(treat_month) - base_month)
)]

write.csv(panel, "panel.csv")


