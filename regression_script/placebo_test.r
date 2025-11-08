# ================================
# Placebo Test: Pretend Treatment in 2018
# ================================
library(tidyverse)
library(fixest)
library(modelsummary)

data <- read_csv("/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv")

placebo_year <- 2016

panel_data_placebo <- data %>%
  mutate(
    treated_placebo = if_else(cohort == 2022, 1, 0, missing = 0), # 原始 treated 州不变
    time_to_treat_placebo = year - placebo_year
  )

# Event-study DID with placebo treatment timing
placebo_model <- feols(
  sy_index ~ i(time_to_treat_placebo, treated_placebo, ref = -1) +
    share_age_15_44 + share_male + share_black + log(income) + unrate + poverty_rate +
    share_married_15p + share_hs_plus_25p + titlex_rate |
    fips + year,
  cluster = ~fips,
  data = panel_data_placebo
)

# 输出结果表
etable(placebo_model,
       title = "Placebo Test: Pretend Treatment in 2016",
       fitstat = ~n + r2,
       digits = 3)

# 可视化安慰剂效应
iplot(placebo_model,
      main = "Placebo Event-Study (Fake Treatment in 2018)",
      xlab = "Years relative to placebo treatment",
      ylab = "Coefficient (β)",
      col = "gray40",
      ref.line = 0)
