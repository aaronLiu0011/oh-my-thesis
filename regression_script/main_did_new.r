library(tidyverse)
library(fixest)      
library(did)        
library(lfe)         
library(ggplot2)
library(broom)
library(data.table)
library(dplyr)
library(stringr)
library(plm)

data <- read_csv("/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv")

panel_data <- data %>%
  mutate(
    treated = if_else(cohort == 2022, 1, 0, missing = 0),
    time_to_treat = year - 2022
  )

model <- feols(
  sy_index ~ i(time_to_treat, treated, ref = -1) +  # ref = -1 表示以t=-1为参考
    share_age_15_44 + share_male + share_black + log(income) + urate + prate + share_married_15p + share_hs_plus_25p + titlex_rate| 
    fips + year,  # 州和年份固定效应
  data = panel_data,
  cluster = ~fips  # 聚类标准误
)

coefs <- coef(model)
ses <- se(model)
event_vars <- grep("time_to_treat::", names(coefs), value = TRUE)
times <- as.numeric(gsub(".*time_to_treat::(-?[0-9]+).*", "\\1", event_vars))

plot_data <- tibble(
  time = c(times, -1),  # 添加参考期
  estimate = c(coefs[event_vars], 0),
  se = c(ses[event_vars], 0)
) %>%
  mutate(
    ci_lower = estimate - 1.96 * se,
    ci_upper = estimate + 1.96 * se
  ) %>%
  arrange(time)

ggplot(plot_data, aes(x = time, y = estimate)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2) +
  geom_point(size = 3, color = "steelblue") +
  geom_line(color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red") +
  labs(
    title = "Event Study: Effect of Abortion Ban on Syphilis",
    x = "Years Relative to Treatment (2022)",
    y = "Coefficient Estimate"
  ) +
  theme_minimal()



# ============================================================================
# 平行趋势检验
# ============================================================================

pre_coefs <- grep("time_to_treat::-[2-9]", names(coef(model)), value = TRUE)
test <- wald(model, pre_coefs)

cat("\n=== 平行趋势检验 ===\n")
cat("F统计量:", test$stat, "\n")
cat("P值:", test$p, "\n")
if(test$p > 0.05) {
  cat("结论: 不能拒绝平行趋势假设 ✓\n")
} else {
  cat("结论: 可能违反平行趋势假设 ✗\n")
}

