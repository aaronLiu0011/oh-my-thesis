# ================================
# Double Machine Learning (DML) Analysis & Visualization
# ================================
library(tidyverse)
library(DoubleML)
library(mlr3learners)
library(modelsummary)
library(data.table)
library(ggplot2)
library(glue)

# =========== config ==========

set.seed(42)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out/out_dml"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)


# =========== read data ==========
panel_data <- read_csv(DATA_PATH, show_col_types = FALSE) |>
  mutate(D = if_else(did == 1, 1, 0))   # treatment indicator

# =========== helper function ==========
fit_dml_spec <- function(dep_var, pretty_name){
  
  y <- dep_var
  d <- "D"
  x <- c(
    "share_age_15_44", "share_male", "share_black",
    "share_married_15p", "share_hs_plus_25p",
    "unrate", "poverty_rate", "uninsured_pct", "income"
  )
  
  data_ml <- panel_data |>
    select(all_of(c(y, d, x))) |>
    drop_na() |>
    as.data.table()
  
  dml_data <- DoubleMLData$new(data_ml, y_col = y, d_cols = d)
  
  ml_l <- lrn("regr.ranger", num.trees = 2000)
  ml_m <- lrn("classif.ranger", num.trees = 2000, predict_type = "prob")
  
  dml_plr <- DoubleMLPLR$new(dml_data, ml_l, ml_m)
  dml_plr$fit()
  
  res <- tibble(
    outcome   = pretty_name,
    learner   = "Random Forest (ranger)",
    n         = nrow(data_ml),
    estimate  = round(dml_plr$coef, 2),
    std.error = round(dml_plr$se, 2),
    conf.low  = round(dml_plr$coef - 1.96 * dml_plr$se, 2),
    conf.high = round(dml_plr$coef + 1.96 * dml_plr$se, 2),
    p.value   = round(2 * (1 - pnorm(abs(dml_plr$t_stat))), 3)
  )
  
  html_file <- file.path(OUT_DIR, glue("dml_did_{tolower(pretty_name)}.html"))
  datasummary_df(
    data = res,
    title = glue("DoubleML DID Estimate — {pretty_name}"),
    output = html_file
  )
  message(glue("✔ Exported: {html_file}"))
  return(res)
}

# =========== run models ==========
res_sy <- fit_dml_spec("sy_index",  "Syphilis")
res_go <- fit_dml_spec("go_index",  "Gonorrhea")
res_ch <- fit_dml_spec("ch_index",  "Chlamydia")
res_st <- fit_dml_spec("std_index", "STDs_Composite")

# combine all results
att_table <- bind_rows(res_sy, res_go, res_ch, res_st)

# =========== summary HTML ==========
summary_file <- file.path(OUT_DIR, "dml_summary.html")
datasummary_df(
  data = att_table,
  title = "Summary of DML DID Estimates (Random Forest Learners)",
  output = summary_file
)
message(glue("✔ Exported summary table: {summary_file}"))

# =========== coefficient plot ==========
coef_plot <- ggplot(att_table, aes(x = outcome, y = estimate)) +
  geom_point(size = 3, color = "black") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.15) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(
    title = "DML Estimates with 95% Confidence Intervals",
    subtitle = "Estimated ATT (Post × Treated)",
    x = "Outcome", y = "Estimated Effect"
  ) +
  theme_minimal(base_size = 14)

ggsave(file.path(OUT_DIR, "dml_coef_plot.png"), coef_plot, width = 6, height = 4, dpi = 300)
message(glue("✔ Saved: dml_coef_plot.png"))

# =========== optional: CATE visualization ==========
# Uncomment if you run DoubleMLIRM or causal forest later
# dml_irm <- DoubleMLIRM$new(dml_data, ml_l, ml_m)
# dml_irm$fit()
# cate <- dml_irm$compute_cate()
# cate_df <- data.frame(cate = cate)
# 
# cate_plot <- ggplot(cate_df, aes(x = cate)) +
#   geom_histogram(bins = 30, fill = "steelblue", alpha = 0.6) +
#   geom_vline(xintercept = mean(cate), linetype = "dashed") +
#   labs(title = "Distribution of Estimated CATE (DoubleMLIRM)",
#        x = "CATE", y = "Frequency") +
#   theme_minimal(base_size = 14)
# 
# ggsave(file.path(OUT_DIR, "dml_cate_hist.png"), cate_plot, width = 6, height = 4, dpi = 300)
# message(glue("✔ Saved: dml_cate_hist.png"))
