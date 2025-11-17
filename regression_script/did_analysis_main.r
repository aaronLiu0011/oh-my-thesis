# ================================
# Difference-in-Differences (DID) Main Analysis
# ================================
library(tidyverse)
library(fixest)
library(modelsummary)
library(broom)
library(glue)

# =========== config ==========
DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out"

if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

ms_stars <- c("*" = .10, "**" = .05, "***" = .01)
gof_omit <- "IC|Log|F|Within|R2 Adj|Std.Errors|RMSE"

panel_data <- read_csv(DATA_PATH, show_col_types = FALSE)

panel_data <- panel_data |> filter(year != 2020)  |>
  filter(cohort == 2022 | is.na(cohort)) # filtrate the late-adopted states

# =========== models ==========
fit_five_specs <- function(dep_var, pretty_name){
  # (1) no control
    m1 <- feols(as.formula(paste0(dep_var, " ~ did | fips + year")),
              data = panel_data, cluster = "fips")
  
  # (2) + Demo & Health
  m2 <- feols(as.formula(paste0(
    dep_var, " ~ did + share_age_15_44 + share_male + share_black +",
    "share_married_15p + uninsured_pct | fips + year"
  )), data = panel_data, cluster = "fips")
  
  # (3) + All Controls
  m3 <- feols(as.formula(paste0(
    dep_var, " ~ did + share_age_15_44 + share_male + share_black + ",
    "share_married_15p + share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + ",
    "log(income) | fips + year"
  )), data = panel_data, cluster = "fips")
  
  # (4) + State-Specific Linear Trends
  m4 <- feols(as.formula(paste0(
    dep_var, " ~ did + share_age_15_44 + share_male + share_black + ",
    "share_married_15p + share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + ",
    "log(income) | fips + year + fips[year]"
  )), data = panel_data, cluster = "fips")
  
  models <- list(
    "Baseline (No Controls)"        = m1,
    "Demographic Controls"          = m2,
    "Full Controls"                 = m3,
    "State-Specific Trends"         = m4
  )
  
# =========== output ==========
  html_file <- file.path(OUT_DIR, glue("did_{tolower(pretty_name)}.html"))
  modelsummary(
    models,
    stars      = ms_stars,
    coef_rename  = c(
      "did"                = "Post × Treated",
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
      "(4)" = "Yes"
    ),
    output     = html_file,
    title      = glue("DID Estimates — {pretty_name}"),
    notes      = "All models include state and year fixed effects; SE clustered at the state (fips) level; Model (5) adds State × Year linear trends via fips[year]; ATT is ‘Post × Treated’"
  )
  
  message(glue("✔ Exported: {html_file}"))
  invisible(models)
}

# =========== run ==========
fits_sy <- fit_five_specs("sy_index",  "Syphilis")
fits_go <- fit_five_specs("go_index",  "Gonorrhea")
fits_ch <- fit_five_specs("ch_index",  "Chlamydia")
fits_st <- fit_five_specs("std_index", "STDs_Composite")

# treatment effects
extract_att <- function(fits_list, disease){
  map_dfr(names(fits_list), function(nm){
    est <- broom::tidy(fits_list[[nm]], conf.int = TRUE) |>
      filter(term == "did") |>
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
