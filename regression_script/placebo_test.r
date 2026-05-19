# ================================
# Placebo Event Study for ch/go/std
# ================================
library(tidyverse)
library(fixest)
library(modelsummary)
library(broom)
library(stringr)
library(ggplot2)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out/out_placebo"

if(!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

data <- read_csv(DATA_PATH, show_col_types = FALSE)

placebo_year <- 2016

# ------------------------------------
# Create placebo treatment variables
# ------------------------------------
panel_data_placebo <- data %>%
  mutate(
    treated_placebo = if_else(cohort == 2022, 1, 0, missing = 0),
    time_to_treat_placebo = year - placebo_year
  )

# --------------------------------------------------------
# Function: Plot using your preferred ggplot style
# --------------------------------------------------------
plot_event_study <- function(model, title_text, out_png){
  
  est <- tidy(model, conf.int = TRUE)
  
  est_clean <- est %>%
    filter(str_detect(term, "time_to_treat_placebo::")) %>%
    mutate(
      time = as.numeric(str_extract(term, "-?\\d+")),
      estimate = estimate,
      ci_lower = conf.low,
      ci_upper = conf.high
    ) %>%
    arrange(time)
  
  p <- ggplot(est_clean, aes(x = time, y = estimate)) +
    geom_hline(yintercept = 0, size = 0.7, linetype = "solid", color = "grey") +
    geom_vline(xintercept = -1, size = 0.7, linetype = "solid", color = "grey") +
    geom_line(aes(y = ci_upper), linetype = "dashed", color = "black") +
    geom_line(aes(y = ci_lower), linetype = "dashed", color = "black") +
    geom_line(size = 1, color = "black") +
    scale_x_continuous(breaks = seq(min(est_clean$time), max(est_clean$time), 1)) +
    labs(
      x = "Periods relative to treatment",
      y = "Coefficient"
    ) +
    theme_classic(base_size = 14) +
    theme(
      axis.line = element_line(color = "grey"),
      plot.title = element_text(
        size = 13,
        face = "bold",
        hjust = 0.5,
        margin = margin(b = 10)
      ),
      axis.title.x = element_text(margin = margin(t = 10)),
      axis.title.y = element_text(margin = margin(r = 10))
    )
  
  ggsave(out_png, p, width = 6, height = 4, dpi = 300)
  message("✔ Saved plot: ", out_png)
  
  return(p)
}

# --------------------------------------------------------
# Function: Run Placebo Event Study
# --------------------------------------------------------
run_placebo <- function(dep_var){
  
  model <- feols(
    as.formula(
      paste0(
        dep_var,
        " ~ i(time_to_treat_placebo, treated_placebo, ref = -1) + ",
        "share_age_15_44 + share_male + share_black + share_married_15p + ",
        "share_hs_plus_25p + unrate + poverty_rate + uninsured_pct + log(income) ",
        "| fips + year"
      )
    ),
    data    = panel_data_placebo,
    cluster = ~fips
  )
  
  # =====================
  # Save table (LaTeX)
  # =====================
  out_tex <- file.path(
    OUT_DIR,
    paste0("placebo_", dep_var, "_2016.tex")
  )
  
  etable(
    model,
    title   = paste("Placebo Test:", dep_var, "(Fake Treatment = 2016)"),
    fitstat = ~n + r2,
    digits  = 3,
    file    = out_tex
  )
  
  # =====================
  # Save plot (ggplot)
  # =====================
  out_png <- file.path(
    OUT_DIR,
    paste0("placebo_event_study_", dep_var, "_2016.png")
  )
  
  plot_event_study(
    model,
    title_text = paste("Placebo Event-Study:", dep_var, "(Fake=2016)"),
    out_png = out_png
  )
  
  message("✔ Completed Placebo for ", dep_var)
  invisible(model)
}

# ------------------------------------
# Run for ch_index, go_index, std_index
# ------------------------------------
dep_var_list <- c("ch_index", "go_index", "sy_index")

placebo_results <- lapply(dep_var_list, run_placebo)
