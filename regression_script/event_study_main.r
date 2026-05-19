# ===============================
# Event Study Analysis
# ===============================
library(tidyverse)
library(fixest)
library(ggplot2)
library(broom)
library(data.table)
library(stringr)
library(knitr)
library(kableExtra)

# ===============================
# Load data
# ===============================
panel_data <- read_csv(
  "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
)

# Drop COVID year
panel_data <- panel_data |>
  filter(year != 2020)

# ===============================
# Event study function
# ===============================
run_event_study <- function(dep_var, title_text) {
  
  # ---------------------------
  # Model specification
  # ---------------------------
  formula <- as.formula(
    paste0(
      dep_var,
      " ~ i(event_time, treated, ref = -1) + ",
      "share_age_15_44 + share_male + share_black + ",
      "share_married_15p + share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + ",
      "log(income) | fips + year"
    )
  )
  
  model <- feols(
    formula,
    data = panel_data,
    cluster = ~fips
  )
  
  # ---------------------------
  # Extract coefficients
  # ---------------------------
  coefs <- coef(model)
  ses   <- se(model)
  
  event_vars <- grep("event_time::", names(coefs), value = TRUE)
  times <- as.numeric(
    gsub(".*event_time::(-?[0-9]+).*", "\\1", event_vars)
  )
  
  coef_tbl <- tibble(
    outcome    = dep_var,
    event_time = times,
    estimate   = coefs[event_vars],
    se         = ses[event_vars]
  ) |>
    mutate(
      ci_lower = estimate - 1.96 * se,
      ci_upper = estimate + 1.96 * se
    ) |>
    arrange(event_time)
  
  # ---------------------------
  # Prepare data for plot
  # ---------------------------
  plot_data <- bind_rows(
    coef_tbl,
    tibble(
      outcome    = dep_var,
      event_time = -1,
      estimate   = 0,
      se         = 0,
      ci_lower   = 0,
      ci_upper   = 0
    )
  ) |>
    arrange(event_time)
  
  # ---------------------------
  # Plot
  # ---------------------------
  p <- ggplot(plot_data, aes(x = event_time, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey", size = 0.7) +
    geom_vline(xintercept = -1, color = "grey", size = 0.7) +
    geom_line(aes(y = ci_upper), linetype = "dashed") +
    geom_line(aes(y = ci_lower), linetype = "dashed") +
    geom_line(size = 1) +
    scale_x_continuous(
      breaks = seq(min(plot_data$event_time),
                   max(plot_data$event_time),
                   by = 1)
    ) +
    labs(
      x = "Periods relative to treatment",
      y = "Coefficient"
    ) +
    theme_classic(base_size = 14)
  
  ggsave(
    filename = paste0(
      "/Users/okuran/Desktop/thesis/out/event_study/event_study_plot_",
      title_text, ".png"
    ),
    plot = p,
    width = 6, height = 4, dpi = 300
  )
  
  # ---------------------------
  # Parallel trends test
  # ---------------------------
  pre_coefs <- grep("event_time::-[2-9]", names(coef(model)), value = TRUE)
  
  if (length(pre_coefs) > 0) {
    test <- wald(model, pre_coefs)
    
    cat("\n=== Parallel Trend Test:", dep_var, "===\n")
    cat("F statistic:", test$stat, "\n")
    cat("P value:", test$p, "\n")
  }
  
  return(coef_tbl)
}

# ===============================
# Run for all outcomes
# ===============================
es_sy  <- run_event_study("sy_index",  "Syphilis")
es_go  <- run_event_study("go_index",  "Gonorrhea")
es_ch  <- run_event_study("ch_index",  "Chlamydia")
es_std <- run_event_study("std_index", "STDs")
es_distance <- run_event_study("distance", "Distance")

# ===============================
# Combine all coefficients
# ===============================
event_study_coefs <- bind_rows(
  es_sy,
  es_go,
  es_ch,
  es_std,
  es_distance
)

# ===============================
# Save CSV (archive)
# ===============================
write_csv(
  event_study_coefs,
  "/Users/okuran/Desktop/thesis/out/event_study/event_study_coefficients.csv"
)

# ===============================
# Create HTML table for Appendix
# ===============================
event_study_html <- event_study_coefs |>
  mutate(
    Estimate = sprintf("%.3f", estimate),
    SE       = sprintf("(%.3f)", se)
  ) |>
  select(Outcome = outcome, EventTime = event_time, Estimate, SE) |>
  arrange(Outcome, EventTime)

html_table <- kable(
  event_study_html,
  format  = "html",
  caption = "Event Study Coefficients by Outcome",
  align   = "lccc"
) |>
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE,
    position = "left"
  )

save_kable(
  html_table,
  file = "/Users/okuran/Desktop/thesis/out/event_study/event_study_coefficients.html"
)
