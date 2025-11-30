# ================================
# Difference-in-Differences with Heterogeneity (Interaction)
# ================================

library(tidyverse)
library(fixest)
library(modelsummary)
library(broom)
library(glue)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out/out_hetero"

if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

panel_data <- read_csv(DATA_PATH, show_col_types = FALSE)

# centering
panel_data <- panel_data |>
  mutate(
    c_share_black      = share_black      - mean(share_black, na.rm = TRUE),
    c_log_income       = log(income)      - mean(log(income), na.rm = TRUE),
    c_share_male       = share_male       - mean(share_male, na.rm = TRUE),
    c_share_age_15_44  = share_age_15_44  - mean(share_age_15_44, na.rm = TRUE)
  )

ms_stars <- c("*" = .10, "**" = .05, "***" = .01)
gof_omit <- "IC|Log|F|Within|R2 Adj|Std.Errors|RMSE"


# =========== function ==========
fit_heterogeneity <- function(dep_var, pretty_name, het_var, het_label){
  m1 <- feols(
    as.formula(paste0(
      dep_var, " ~ did * ", het_var, " + share_age_15_44 + share_male + share_black + ",
      "share_married_15p + share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + log(income) | fips + year"
    )),
    data = panel_data, cluster = "fips"
  )
  
  html_file <- file.path(OUT_DIR, glue("did_heterogeneity_{tolower(pretty_name)}_{het_var}.html"))
  
  coef_map_list <- c("did" = "Post × Treated")
  coef_map_list[paste0("did:", het_var)] <- glue("Post × Treated × {het_label}")
  
  modelsummary(
    list("(1)" = m1),
    stars      = ms_stars,
    coef_map   = coef_map_list,
    gof_omit   = gof_omit,
    statistic  = "({std.error})",
    output     = html_file,
    title      = glue("DID with Heterogeneity — {pretty_name} × {het_label}"),
    notes      = glue("All regressions include full controls (not reported), 
                    and state and year fixed effects. 
                    Standard errors clustered at the state level.")
  )
  
  message(glue("✔ Exported: {html_file}"))
  invisible(m1)
}

# =========== run ==========
fits_sy_het <- fit_heterogeneity("sy_index",  "Syphilis",  "c_share_black", "Share black")
fits_go_het <- fit_heterogeneity("go_index",  "Gonorrhea", "c_share_black", "Share black")
fits_ch_het <- fit_heterogeneity("ch_index",  "Chlamydia", "c_share_black", "Share black")
fits_st_het <- fit_heterogeneity("std_index", "STDs_Composite", "c_share_black", "Share black")

fits_sy_het <- fit_heterogeneity("sy_index",  "Syphilis",  "c_log_income", "log(income)")
fits_go_het <- fit_heterogeneity("go_index",  "Gonorrhea", "c_log_income", "log(income)")
fits_ch_het <- fit_heterogeneity("ch_index",  "Chlamydia", "c_log_income", "log(income)")
fits_st_het <- fit_heterogeneity("std_index", "STDs_Composite", "c_log_income", "log(income)")

fits_sy_het <- fit_heterogeneity("sy_index",  "Syphilis",  "c_share_male", "Share male")
fits_go_het <- fit_heterogeneity("go_index",  "Gonorrhea", "c_share_male", "Share male")
fits_ch_het <- fit_heterogeneity("ch_index",  "Chlamydia", "c_share_male", "Share male")
fits_st_het <- fit_heterogeneity("std_index", "STDs_Composite", "c_share_male", "Share male")

fits_sy_het <- fit_heterogeneity("sy_index",  "Syphilis",  "c_share_age_15_44", "Share young")
fits_go_het <- fit_heterogeneity("go_index",  "Gonorrhea", "c_share_age_15_44", "Share young")
fits_ch_het <- fit_heterogeneity("ch_index",  "Chlamydia", "c_share_age_15_44", "Share young")
fits_st_het <- fit_heterogeneity("std_index", "STDs_Composite", "c_share_age_15_44", "Share young")
