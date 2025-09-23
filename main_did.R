library(data.table)
library(dplyr)
library(fixest)
library(ggplot2)
library(stringr)

#==========tool============
data_dir <- file.path(getwd(), "processed_data")

norm_fips <- function(x) {
  x <- as.character(x)
  x <- gsub("\\D", "", x)
  ifelse(nchar(x)==5, x, str_pad(x, 5, pad="0"))
}

to_int <- function(x) suppressWarnings(as.integer(as.character(x)))
NA_STR <- c("Data not available","Data suppressed","Suppressed","NA","")

#===========data============

# y_1: Syphilis
sy <- fread(file.path(data_dir, "Primary_Secondary_Syphilis_2010_2023.csv"),
            na.strings = NA_STR)
sy <- sy |>
  transmute(
    fips = norm_fips(fips),
    year = to_int(Year),
    rate_syphilis = as.numeric(rate_per_100000)
  )

# y_2: Gonorrhea
go <- fread(file.path(data_dir, "Gonorrhea_2010_2023.csv"),
            na.strings = NA_STR)
go <- go |>
  transmute(
    fips = norm_fips(fips),
    year = to_int(Year),
    rate_gon = as.numeric(rate_per_100000)
  )

# x_1: Unemployment rate
ue <- fread(file.path(data_dir, "merged_laucnty_unemployment.csv"))
ue <- ue |>
  transmute(
    fips = norm_fips(fips),
    year = to_int(year),
    unemp_rate = as.numeric(unemp_rate)
  )

# x_2: Uninsured rate
ui <- fread(file.path(data_dir, "sahie_county_insured_uninsured_2010_2023.csv"))
ui <- ui |>
  transmute(
    fips = norm_fips(fips),
    year = to_int(year),
    uninsured_rate = as.numeric(PCTUI_PT)
  )

# x_3: Median Household Income (2023USD)
mhi <- fread(file.path(data_dir, "saipe_county_mhi_2010_2023_real2023usd.csv"))
mhi <- mhi |>
  transmute(
    fips = norm_fips(fips),
    year = to_int(year),
    mhi_real2023 = as.numeric(mhi_real_2023usd)
  )

# x_4: Poverty rate
pov <- fread(file.path(data_dir, "saipe_county_poverty_2010_2023.csv"))
pov <- pov |>
  transmute(
    fips = norm_fips(fips),
    year = to_int(year),
    poverty_rate = as.numeric(poverty_rate)
  )

# x_5: Demographics
demo <- fread(file.path(data_dir, "acs_county_demographics_2010_2023.csv"))
demo <- demo |>
  transmute(
    fips = norm_fips(fips),
    year = to_int(year),
    pop_total   = as.numeric(pop_total),
    pop_15_44   = as.numeric(pop_15_44),
    pct_15_44   = as.numeric(pct_15_44),
    pct_black   = as.numeric(pct_black),
    pct_hispanic= as.numeric(pct_hispanic)
  )

# D: Treatment
pol <- fread(file.path(data_dir, "abortion_policies_2022.csv")) 
pol <- pol |>
  transmute(
    state_fips = str_pad(gsub("\\D","", state_fips), 2, pad="0"),
    treated  = as.integer(treated),
    treated_year = to_int(treated_year)
  ) |>
  mutate(
    cohort = ifelse(treated == 1 & !is.na(treated_year), treated_year, NA_integer_)
  ) |>
  select(state_fips, cohort) |>
  distinct()

#===========panel==========
panel <- sy |>
  mutate(state_fips = substr(fips,1,2)) |>
  left_join(go, by = c("fips","year")) |>
  left_join(ue, by = c("fips","year")) |>
  left_join(ui, by = c("fips","year")) |>
  left_join(mhi, by = c("fips","year")) |>
  left_join(pov, by = c("fips","year")) |>
  left_join(demo, by = c("fips","year")) |>
  left_join(pol, by = "state_fips") |>
  mutate(
    treat  = as.integer(!is.na(cohort)),
    rel_y  = year - cohort,
    post = as.integer(!is.na(cohort) & year >= cohort),
    did  = post * treat
  ) |>
  select(year, state_fips, fips, did, everything())

panel <- panel |> filter(!is.na(rate_syphilis) & !is.na(rate_gon), year >= 2010, year <= 2023)

panel <- panel |>
  filter(!state_fips %in% c("12", "18", "19", "31", "37", "45")) ## remove states whose law went effect after 2022

#===========DID(TWFE)=============
library(fixest)

fml_did_syp <- rate_syphilis ~ did + unemp_rate + uninsured_rate + 
  mhi_real2023 + poverty_rate + 
  pct_15_44 + pct_black + pct_hispanic | 
  fips + year

fml_did_gon <- rate_gon ~ did + unemp_rate + uninsured_rate + 
  mhi_real2023 + poverty_rate + 
  pct_15_44 + pct_black + pct_hispanic | 
  fips + year

est_did_syp <- feols(fml_did_syp, data = panel, cluster = ~ state_fips)
summary(est_did_syp)

est_did_gon <- feols(fml_did_gon, data = panel, cluster = ~ state_fips)
summary(est_did_gon)

#===========event study==========
es_fit_syp <- feols(
  rate_syphilis ~ i(year, treat, ref = 2021) + # reference year: 2021
    unemp_rate + uninsured_rate + mhi_real2023 +
    poverty_rate + pct_15_44 + pct_black + pct_hispanic |
    fips + year,
  data = panel,
  cluster = ~ state_fips
)

iplot(es_fit_syp,
      ylab = "Effect on syphilis rate (per 100k)",
      main = "Event Study")

es_fit_gon <- feols(
  rate_gon ~ i(year, treat, ref = 2021) + # reference year: 2021
    unemp_rate + uninsured_rate + mhi_real2023 +
    poverty_rate + pct_15_44 + pct_black + pct_hispanic |
    fips + year,
  data = panel,
  cluster = ~ state_fips
)

iplot(es_fit_gon,
      ylab = "Effect on gonorrhea rate (per 100k)",
      main = "Event Study")



