library(tidyverse)
library(modelsummary)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
panel <- read_csv(DATA_PATH, show_col_types = FALSE)

panel <- panel |> filter(year != 2020)  |> filter(cohort == 2022 | is.na(cohort))

#=======================

desc_vars <- panel |>
  filter(year == 2019) |>           # baseline year
  select(
    sy_index, go_index, ch_index,
    share_age_15_44, share_male, share_black, share_married_15p,
    share_hs_plus_25p, uninsured_pct, unrate, poverty_rate, income,
    distance, treated
  )

compute_stats <- function(data, var) {
  
  x0 <- data |> filter(treated == 0) |> pull({{var}})
  x1 <- data |> filter(treated == 1) |> pull({{var}})
  
  tibble(
    Variable     = var,
    
    Mean_0       = mean(x0, na.rm = TRUE),
    SD_0         = sd(x0, na.rm = TRUE),
    Min_0        = min(x0, na.rm = TRUE),
    Max_0        = max(x0, na.rm = TRUE),
    Obs_0        = sum(!is.na(x0)),
    
    Mean_1       = mean(x1, na.rm = TRUE),
    SD_1         = sd(x1, na.rm = TRUE),
    Min_1        = min(x1, na.rm = TRUE),
    Max_1        = max(x1, na.rm = TRUE),
    Obs_1        = sum(!is.na(x1)),
    
    Diff         = mean(x1, na.rm = TRUE) - mean(x0, na.rm = TRUE),
    p_value      = t.test(x1, x0)$p.value
  )
}

vars <- c(
  "sy_index", "go_index", "ch_index",
  "share_age_15_44", "share_male", "share_black", "share_married_15p",
  "share_hs_plus_25p", "uninsured_pct", "unrate", "poverty_rate",
  "income", "distance"
)

desc_table <- map_dfr(vars, ~ compute_stats(desc_vars, .x))

desc_table <- desc_table |>
  mutate(Variable = recode(Variable,
                           sy_index = "Syphilis incidence (per 100k)",
                           go_index = "Gonorrhea incidence (per 100k)",
                           ch_index = "Chlamydia incidence (per 100k)",
                           share_age_15_44 = "Share aged 15–44",
                           share_male = "Share male",
                           share_black = "Share Black",
                           share_married_15p = "Share married (15+)",
                           share_hs_plus_25p = "Share high-school+ (25+)",
                           uninsured_pct = "Uninsured share",
                           unrate = "Unemployment rate",
                           poverty_rate = "Poverty rate",
                           income = "Income per capita",
                           distance = "Population-weighted distance to abortion services"
  ))

datasummary_df(
  desc_table,
  output = "/Users/okuran/Desktop/thesis/out/desc_stats/desc_stats_treat_vs_control_2019.html",
  title = "Descriptive Statistics by Treatment Status",
  fmt = 3
)


#============ all sample difference===========

desc_vars <- panel |>
  select(
    sy_index, go_index, ch_index,
    share_age_15_44, share_male, share_black, share_married_15p,
    share_hs_plus_25p, uninsured_pct, unrate, poverty_rate, income,
    distance, treated
  )

compute_stats <- function(data, var) {
  
  x0 <- data |> filter(treated == 0) |> pull({{var}})
  x1 <- data |> filter(treated == 1) |> pull({{var}})
  
  tibble(
    Variable     = var,
    
    Mean_0       = mean(x0, na.rm = TRUE),
    SD_0         = sd(x0, na.rm = TRUE),
    Min_0        = min(x0, na.rm = TRUE),
    Max_0        = max(x0, na.rm = TRUE),
    Obs_0        = sum(!is.na(x0)),
    
    Mean_1       = mean(x1, na.rm = TRUE),
    SD_1         = sd(x1, na.rm = TRUE),
    Min_1        = min(x1, na.rm = TRUE),
    Max_1        = max(x1, na.rm = TRUE),
    Obs_1        = sum(!is.na(x1)),
    
    Diff         = mean(x1, na.rm = TRUE) - mean(x0, na.rm = TRUE),
    p_value      = t.test(x1, x0)$p.value
  )
}

vars <- c(
  "sy_index", "go_index", "ch_index",
  "share_age_15_44", "share_male", "share_black", "share_married_15p",
  "share_hs_plus_25p", "uninsured_pct", "unrate", "poverty_rate",
  "income", "distance"
)

desc_table <- map_dfr(vars, ~ compute_stats(desc_vars, .x))

desc_table <- desc_table |>
  mutate(Variable = recode(Variable,
                           sy_index = "Syphilis incidence (per 100k)",
                           go_index = "Gonorrhea incidence (per 100k)",
                           ch_index = "Chlamydia incidence (per 100k)",
                           share_age_15_44 = "Share aged 15–44",
                           share_male = "Share male",
                           share_black = "Share Black",
                           share_married_15p = "Share married (15+)",
                           share_hs_plus_25p = "Share high-school+ (25+)",
                           uninsured_pct = "Uninsured share",
                           unrate = "Unemployment rate",
                           poverty_rate = "Poverty rate",
                           income = "Income per capita",
                           distance = "Population-weighted distance to abortion services"
  ))

datasummary_df(
  desc_table,
  output = "/Users/okuran/Desktop/thesis/out/desc_stats/desc_stats_treat_vs_control_all.html",
  title = "Descriptive Statistics by Treatment Status",
  fmt = 3
)
