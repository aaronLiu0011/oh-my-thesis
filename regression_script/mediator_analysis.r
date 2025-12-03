library(data.table)
library(fixest)
library(dplyr)

data_dir <- "/Users/okuran/Desktop/thesis/master_data/"

panel <- fread(file.path(data_dir, "state_panel_2010_2023.csv"))

panel <- panel |> filter(year != 2020)  |>
  filter(cohort == 2022 | is.na(cohort))

shock_calculation <- panel %>%
  filter(year %in% c(2021, 2023)) %>%
  select(fips, year, distance) %>%
  # 转换为宽数据：每个县一行，有 dist_2021 和 dist_2023 两列
  pivot_wider(
    names_from = year, 
    values_from = distance, 
    names_prefix = "dist_"
  ) %>%
  # 2. 计算差值 (Delta)
  mutate(
    # 核心计算：禁令后距离 - 禁令前距离
    change_in_dist = dist_2023 - dist_2021,
    change_in_dist = ifelse(is.na(change_in_dist), 0, change_in_dist)
  )

summary(shock_calculation$change_in_dist)

shock_bins <- shock_calculation %>%
  mutate(
    # 逻辑处理：如果不增反减，视为受冲击为 0（没有变坏）
    final_shock = ifelse(change_in_dist < 0, 0, change_in_dist),
    
    # 切分 Bins 
    dist_bin = cut(final_shock, 
                   breaks = c(-Inf, 25, 100, Inf), 
                   labels = c("0-25", "25-100", "100+"),
                   right = FALSE)
  ) %>%
  select(fips, dist_bin)

final_regression_data <- panel %>%
  left_join(shock_bins, by = "fips")


run_shock_reg <- function(panel, outcome_var) {
  
  fml <- as.formula(
    paste0(
      outcome_var,
      " ~ i(dist_bin, did, ref = '0-25') + share_male + share_black + share_married_15p + 
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
