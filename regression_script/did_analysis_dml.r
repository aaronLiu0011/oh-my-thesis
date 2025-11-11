# ================================
# Difference-in-Differences (DML version)
# ================================
library(tidyverse)
library(DoubleML)
library(mlr3learners)
library(modelsummary)
library(broom)
library(glue)
library(data.table)


# =========== config ==========
DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out"

if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

ms_stars <- c("*" = .10, "**" = .05, "***" = .01)
gof_omit <- "df|t|p|conf|method"

# =========== data load ==========
panel_data <- read_csv(DATA_PATH, show_col_types = FALSE)

# 创建 DML 用的基本变量
panel_data <- panel_data |>
  mutate(
    D = if_else(did == 1, 1, 0)   # treatment indicator
  )

# =========== helper function ==========
fit_dml_spec <- function(dep_var, pretty_name){
  
  y <- dep_var
  d <- "D"
  x <- c(
    "share_age_15_44", "share_male", "share_black",
    "share_married_15p", "share_hs_plus_25p",
    "unrate", "poverty_rate", "uninsured_pct", "income"
  )
  
  # 构造 DoubleML 数据对象
  data_ml <- panel_data |>
    select(all_of(c(y, d, x))) |>
    drop_na() |>
    as.data.table()
  
  dml_data <- DoubleMLData$new(data_ml, y_col = y, d_cols = d)
  
  # 随机森林作为 ML learner
  ml_l <- lrn("regr.ranger", num.trees = 2000)
  ml_m <- lrn("classif.ranger", num.trees = 2000, predict_type = "prob")
  
  # 估计 PLR 模型（适合连续因变量的DID主效应）
  dml_plr <- DoubleMLPLR$new(dml_data, ml_l, ml_m)
  dml_plr$fit()
  
  # 提取结果
  res <- tibble(
    outcome   = pretty_name,
    estimate  = dml_plr$coef,
    std.error = dml_plr$se,
    conf.low  = dml_plr$coef - 1.96 * dml_plr$se,
    conf.high = dml_plr$coef + 1.96 * dml_plr$se,
    p.value   = 2 * (1 - pnorm(abs(dml_plr$t_stat)))
  )
  
  # 输出到 HTML
  html_file <- file.path(OUT_DIR, glue("dml_did_{tolower(pretty_name)}.html"))
  
  datasummary_df(
    data = res,
    title = glue("DoubleML DID Estimate — {pretty_name}"),
    output = html_file
  )
  
  message(glue("✔ Exported: {html_file}"))
  return(res)
}

# =========== run ==========
res_sy <- fit_dml_spec("sy_index",  "Syphilis")
res_go <- fit_dml_spec("go_index",  "Gonorrhea")
res_ch <- fit_dml_spec("ch_index",  "Chlamydia")
res_st <- fit_dml_spec("std_index", "STDs_Composite")

att_table <- bind_rows(res_sy, res_go, res_ch, res_st)
print(att_table)
