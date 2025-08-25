library(tidycensus)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)

# census_api_key("YOUR_KEY_HERE", install = TRUE)
# readRenviron("~/.Renviron")

dir <- "/Users/okuran/Desktop/thesis/processed_data"

# ================================
# variable code
# ================================
# B01001: Sex by Age
age_codes_m <- c("B01001_007","B01001_008","B01001_009","B01001_010",
                 "B01001_011","B01001_012","B01001_013","B01001_014","B01001_015")
age_codes_f <- c("B01001_031","B01001_032","B01001_033","B01001_034",
                 "B01001_035","B01001_036","B01001_037","B01001_038","B01001_039")

vars_age   <- c("B01001_001", age_codes_m, age_codes_f)   # total + 15–44
vars_black <- c("B02001_001","B02001_003")                # total, Black
vars_hisp  <- c("B03003_001","B03003_003")                # total, Hispanic

years <- 2010:2023

# ================================
# encapsulation
# ================================
get_demog_one_year <- function(yr){
  # ---- age ----
  age_df <- get_acs(
    geography = "county",
    variables = vars_age,
    year = yr, survey = "acs5",
    cache_table = TRUE, geometry = FALSE
  ) |>
    select(GEOID, variable, estimate) |>
    pivot_wider(names_from = variable, values_from = estimate)
  
  age_df <- age_df |>
    mutate(
      pop_total = B01001_001,
      pop_15_44 = rowSums(across(all_of(c(age_codes_m, age_codes_f))), na.rm = TRUE),
      pct_15_44 = if_else(pop_total > 0, 100 * pop_15_44 / pop_total, NA_real_)
    ) |>
    select(GEOID, pop_total, pop_15_44, pct_15_44)
  
  # ---- Black ----
  blk_df <- get_acs(
    geography = "county",
    variables = vars_black,
    year = yr, survey = "acs5",
    cache_table = TRUE, geometry = FALSE
  ) |>
    select(GEOID, variable, estimate) |>
    pivot_wider(names_from = variable, values_from = estimate) |>
    mutate(
      pct_black = if_else(B02001_001 > 0, 100 * B02001_003 / B02001_001, NA_real_)
    ) |>
    select(GEOID, pct_black)
  
  # ---- Hispanic ----
  hisp_df <- get_acs(
    geography = "county",
    variables = vars_hisp,
    year = yr, survey = "acs5",
    cache_table = TRUE, geometry = FALSE
  ) |>
    select(GEOID, variable, estimate) |>
    pivot_wider(names_from = variable, values_from = estimate) |>
    mutate(
      pct_hispanic = if_else(B03003_001 > 0, 100 * B03003_003 / B03003_001, NA_real_)
    ) |>
    select(GEOID, pct_hispanic)
  
  # ---- join ----
  out <- age_df |>
    left_join(blk_df,  by = "GEOID") |>
    left_join(hisp_df, by = "GEOID") |>
    mutate(
      year = yr,
      fips = GEOID
    ) |>
    select(fips, year, pop_total, pop_15_44, pct_15_44, pct_black, pct_hispanic)
  
  out
}

acs_demog <- map_dfr(years, get_demog_one_year)

outfile <- file.path(dir, "acs_county_demographics_2010_2023.csv")
write_csv(acs_demog, outfile)
message("Saved: ", outfile)

# ================================
# regression
# ================================
panel2 <- panel |>
  left_join(acs_demog, by = c("fips","year"))

library(fixest)

did_w <- feols(
  y_syphilis ~ did + PCTUI_PT + unemp_rate + mhi_real_2023usd +
    pct_15_44 + pct_black + pct_hispanic | fips + year,
  data = panel2,
  weights = ~ pop_total,    # or ~ pop_15_44
  cluster = ~ state_fips
)

etable(did_w, se = "cluster")

# ===============
es_fit <- feols(
  y_syphilis ~ sunab(treated_year, year) + PCTUI_PT + unemp_rate + mhi_real_2023usd + pct_15_44 + pct_black + pct_hispanic | fips + year,
  data = panel2,
  cluster = ~ state_fips
)

iplot(es_fit, ref.line = 0, xlab = "Event time (years)", ylab = "Effect on syphilis rate",
      main = "Event study")

