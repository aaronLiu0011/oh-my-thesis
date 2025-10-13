library(data.table)
library(lubridate)

treat <- fread("/Users/okuran/Desktop/thesis/master_data/abortion_policies.csv")
setnames(treat, tolower(names(treat)))

treat[, treat_date := as.IDate(sprintf("%d-%02d-01", treated_year, treated_month))]
treat[, ever_treated := fifelse(binary_treatment == 1, 1, 0)]

month_seq <- seq(as.IDate("2018-01-01"), as.IDate("2025-12-01"), by = "month")

treatment_panel <- treat[
  , .(month = month_seq), by = .(state_fips, state, treat_date, ever_treated)
]

treatment_panel[, treated := fifelse(!is.na(treat_date) & month >= treat_date, 1, 0)]
treatment_panel[, treated := fifelse(is.na(treated), 0, treated)]

treatment_panel[, fips := sprintf("%02d", as.integer(state_fips))]
treatment_panel <- treatment_panel[, .(fips, state, month, treat_date, treated, ever_treated)]

fwrite(treatment_panel, "/Users/okuran/Desktop/thesis/master_data/state_treatment_treatment_panel.csv")


