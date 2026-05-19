library(data.table)
library(fixest)
library(dplyr)
library(tidyr)
library(ggplot2)


data_dir <- "/Users/okuran/Desktop/thesis/master_data/"

panel <- fread(file.path(data_dir, "state_panel_2010_2023.csv"))

panel <- panel |> filter(year != 2020)  |>
  filter(cohort == 2022 | is.na(cohort))

shock_calculation <- panel |>
  filter(year %in% c(2021, 2023)) |>
  select(fips, year, distance) |>
  pivot_wider(
    names_from = year, 
    values_from = distance, 
    names_prefix = "dist_"
  ) |>
  mutate(
    change_in_dist = dist_2023 - dist_2021,
    change_in_dist = ifelse(is.na(change_in_dist), 0, change_in_dist)
  )

summary(shock_calculation$change_in_dist)
quantile(shock_calculation$change_in_dist)

shock_plot_data <- shock_calculation |>
  left_join(panel |> select(fips, cohort) |> distinct(fips, .keep_all = TRUE),
            by = "fips") |>
  mutate(
    treat = ifelse(cohort == 2022, "Treated", "Control")
  ) |>
  distinct(fips, .keep_all = TRUE)

#===========================

shock_bins <- shock_calculation |>
  mutate(
    dist_bin = case_when(
      change_in_dist < 100 ~ "~100",
      change_in_dist >= 100 ~ "100~"
    ),
    
    dist_bin = factor(dist_bin, levels = c("~100", "100~"))
  ) |>
  select(fips, dist_bin)


final_regression_data <- panel |>
  left_join(shock_bins, by = "fips")


run_shock_reg <- function(panel, outcome_var) {
  
  fml <- as.formula(
    paste0(
      outcome_var,
      " ~ i(dist_bin, did) + share_male + share_black + share_married_15p + 
       share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + log(income) | fips + year"
    )
  )
  
  feols(
    fml,
    data = panel,
    cluster = ~ fips
  )
}

res_ch <- run_shock_reg(final_regression_data, "ch_index")
res_go <- run_shock_reg(final_regression_data, "go_index")
res_sy <- run_shock_reg(final_regression_data, "sy_index")

shock_results <- list(
  Chlamydia = res_ch,
  Gonorrhea = res_go,
  Syphilis  = res_sy
)

library(modelsummary)

modelsummary(
  shock_results,
  stars = c('*' = .1, '**' = .05, '***' = .01),
  gof_omit = "IC|Log|Adj",
  output = "/Users/okuran/Desktop/thesis/out/shock_bins_results.html"
)
