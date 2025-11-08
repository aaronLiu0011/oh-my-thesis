# ================================
# Difference-in-Differences (DID) Main Analysis
# ================================
library(tidyverse)
library(fixest)
library(modelsummary)
library(broom)
library(glue)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

ms_stars <- c("*" = .10, "**" = .05, "***" = .01)
gof_omit <- "IC|Log|F|Within|R2 Adj|Std.Errors|RMSE"

# ---------- 1. Load your data ----------
data <- read_csv(DATA_PATH, show_col_types = FALSE)
panel_data <- data  # 保留变量名一致性

# ---------- 2. Function for five specifications ----------
fit_five_specs <- function(dep_var, pretty_name){
  # (1) 无控制变量
  m1 <- feols(as.formula(paste0(dep_var, " ~ did | fips + year")),
              data = panel_data, cluster = "fips")
  
  # (2) + Title X
  m2 <- feols(as.formula(paste0(dep_var, " ~ did + titlex_rate | fips + year")),
              data = panel_data, cluster = "fips")
  
  # (3) + Demo & Health
  m3 <- feols(as.formula(paste0(
    dep_var, " ~ did + share_age_15_44 + share_male + share_black + titlex_rate +",
    "share_married_15p + uninsured_pct | fips + year"
  )), data = panel_data, cluster = "fips")
  
  # (4) + All Controls
  m4 <- feols(as.formula(paste0(
    dep_var, " ~ did + share_age_15_44 + share_male + share_black + ",
    "share_married_15p + share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + ",
    "log(income) + titlex_rate | fips + year"
  )), data = panel_data, cluster = "fips")
  
  # (5) + State-Specific Linear Trends
  m5 <- feols(as.formula(paste0(
    dep_var, " ~ did + share_age_15_44 + share_male + share_black + ",
    "share_married_15p + share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + ",
    "log(income) + titlex_rate | fips + year + fips[year]"
  )), data = panel_data, cluster = "fips")
  
  models <- list(
    "(1)" = m1,
    "(2)" = m2,
    "(3)" = m3,
    "(4)" = m4,
    "(5)" = m5
  )
  
  # 输出 HTML 表格
  html_file <- file.path(OUT_DIR, glue("did_{tolower(pretty_name)}.html"))
  modelsummary(
    models,
    stars      = ms_stars,
    coef_rename  = c(
      "did"                = "Post × Treated",
      "titlex_rate"        = "Title X user rate per 1000",
      "share_age_15_44"    = "Share Age 15–44",
      "share_male"         = "Share Male",
      "share_black"        = "Share Black",
      "share_married_15p"  = "Share Married (15+)",
      "share_hs_plus_25p"  = "Share ≥ High School (25+)",
      "unrate"             = "Unemployment Rate",
      "poverty_rate"       = "Poverty Rate",
      "uninsured_pct"      = "Uninsured Rate",
      "log(income)"        = "Log(Income per Capita)"),
    gof_omit   = gof_omit,
    statistic    = "({std.error})",
    add_rows     = data.frame(
      term = "State-Specific Trends",
      "(1)" = "No",
      "(2)" = "No",
      "(3)" = "No",
      "(4)" = "No",
      "(5)" = "Yes"
    ),
    output     = html_file,
    title      = glue("DID Estimates — {pretty_name}"),
    notes      = "All models include state and year fixed effects; SE clustered at the state (fips) level; Model (5) adds State × Year linear trends via fips[year]; ATT is ‘Post × Treated’"
  )
  
  message(glue("✔ Exported: {html_file}"))
  invisible(models)
}

# ---------- 3. Run models ----------
fits_sy <- fit_five_specs("sy_index",  "Syphilis")
fits_go <- fit_five_specs("go_index",  "Gonorrhea")
fits_ch <- fit_five_specs("ch_index",  "Chlamydia")
fits_st <- fit_five_specs("std_index", "STDs_Composite")

# ---------- 4. Extract treatment effects ----------
extract_att <- function(fits_list, disease){
  map_dfr(names(fits_list), function(nm){
    est <- broom::tidy(fits_list[[nm]], conf.int = TRUE) %>% 
      filter(term == "did") %>%
      transmute(
        disease = disease,
        spec    = nm,
        estimate, conf.low, conf.high, std.error, p.value
      )
  })
}

att_table <- bind_rows(
  extract_att(fits_sy, "Syphilis"),
  extract_att(fits_go, "Gonorrhea"),
  extract_att(fits_ch, "Chlamydia"),
  extract_att(fits_st, "STDs (Composite)")
)

print(att_table)
