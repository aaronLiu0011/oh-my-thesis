# ============================================
# Synthetic Control (Average Actual vs Synthetic)
# Two-function structure: compute + plot
# ============================================

library(Synth)
library(tidyverse)
library(glue)
library(ggplot2)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out/scm_avg_level"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

# ---- Load panel ----
panel <- read_csv(DATA_PATH, show_col_types = FALSE) |>
  mutate(
    fips = as.numeric(fips),
    year = as.numeric(year),
    treated = as.integer(cohort == 2022)
  )

pre_period  <- 2010:2021
post_period <- 2022:2023
plot_period <- 2010:2023

treated_states <- panel |>
  filter(cohort == 2022) |>
  distinct(fips) |>
  pull(fips)

donor_pool_all <- panel |>
  group_by(fips) |>
  summarise(ever_treated = if (all(is.na(cohort))) 0 else max(cohort == 2022, na.rm = TRUE)) |>
  filter(ever_treated == 0) |>
  pull(fips)

predictors <- c(
  "share_age_15_44", "share_male", "share_black",
  "income", "poverty_rate", "unrate",
  "share_married_15p", "share_hs_plus_25p"
)

# ============================================================
# (1) Function: compute SCM average actual vs synthetic
# ============================================================

compute_scm_avg <- function(Yvar){
  
  message(glue(">>> Computing SCM for outcome: {Yvar}"))
  
  all_estimates <- tibble()
  
  for (treated_fips in treated_states) {
    
    donor_pool <- donor_pool_all
    
    valid_donors <- panel |>
      filter(year %in% pre_period) |>
      group_by(fips) |>
      summarise(missing_y = any(is.na(.data[[Yvar]]))) |>
      filter(!missing_y) |>
      pull(fips)
    
    donor_pool <- donor_pool[donor_pool %in% valid_donors]
    if (length(donor_pool) < 3) next
    
    dataprep.out <- dataprep(
      foo = as.data.frame(panel),
      predictors = predictors,
      predictors.op = "mean",
      dependent = Yvar,
      unit.variable = "fips",
      time.variable = "year",
      treatment.identifier = treated_fips,
      controls.identifier = donor_pool,
      time.predictors.prior = pre_period,
      time.optimize.ssr = pre_period,
      time.plot = plot_period
    )
    
    synth.out <- tryCatch(
      synth(dataprep.out, nested = TRUE),
      error = function(e) NULL
    )
    if (is.null(synth.out)) next
    
    Y1 <- as.numeric(dataprep.out$Y1plot)
    Y0 <- as.matrix(dataprep.out$Y0plot)
    W  <- synth.out$solution.w
    Y_synth <- as.numeric(Y0 %*% W)
    yrs <- dataprep.out$tag$time.plot
    
    df <- tibble(
      fips = treated_fips,
      year = yrs,
      actual = Y1,
      synthetic = Y_synth
    )
    
    all_estimates <- bind_rows(all_estimates, df)
  }
  
  avg_series <- all_estimates |>
    group_by(year) |>
    summarise(
      avg_actual = mean(actual, na.rm = TRUE),
      avg_synthetic = mean(synthetic, na.rm = TRUE)
    )
  
  list(
    all_states = all_estimates,
    avg = avg_series
  )
}

# ============================================================
# (2) Function: plot SCM average actual vs synthetic
# ============================================================

plot_scm_avg <- function(avg_df, Yvar){
  
  p <- ggplot(avg_df, aes(x = year)) +
    geom_line(aes(y = avg_actual), color = "black", size = 1.2) +
    geom_line(aes(y = avg_synthetic), color = "black",
              linetype = "dashed", size = 1.2) +
    geom_vline(xintercept = 2022, color = "grey40", size = 0.7) +
    labs(
      title = glue("Average Actual vs Synthetic: {Yvar}"),
      x = "Year",
      y = "Outcome Level"
    ) +
    theme_classic(base_size = 14) +
    theme(
      axis.line = element_line(color = "grey50"),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  ggsave(
    file.path(OUT_DIR, glue("{Yvar}_avg_level_plot.png")),
    p, width = 8, height = 6, dpi = 300
  )
  
  return(p)
}

# ============================================================
# (3) Run for SY / CH / GO
# ============================================================

outcomes <- c("sy_index", "ch_index", "go_index")

for (Yvar in outcomes) {
  res  <- compute_scm_avg(Yvar)
  plot <- plot_scm_avg(res$avg, Yvar)
  write_csv(res$avg,
            file.path(OUT_DIR, glue("{Yvar}_avg_series.csv")))
}

