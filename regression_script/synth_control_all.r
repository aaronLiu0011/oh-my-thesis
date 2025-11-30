# ============================================
# Synthetic Control (All Treated States + Aggregated Effect)
# ============================================
library(Synth)
library(tidyverse)
library(glue)
library(ggplot2)
library(broom)
library(stringr)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out/scm_synth_all"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

# ---- Load panel ----
panel <- read_csv(DATA_PATH, show_col_types = FALSE) |>
  mutate(fips = as.numeric(fips),
         year = as.numeric(year),
         treated = as.integer(cohort == 2022))

# ---- Define time windows ----
pre_period  <- 2010:2021
post_period <- 2022:2023
plot_period <- 2010:2023

# ---- Identify treated states ----
treated_states <- panel |>
  filter(cohort == 2022) |>
  distinct(fips) |>
  pull(fips)

# ---- Donor pool (never treated) ----
donor_pool_all <- panel |>
  group_by(fips) |>
  summarise(ever_treated = if (all(is.na(cohort))) 0 else max(cohort == 2022, na.rm = TRUE)) |>
  filter(ever_treated == 0) |>
  pull(fips)

# ---- Predictor variables ----
Yvar <- "sy_index"
predictors <- c("share_age_15_44", "share_male", "share_black",
                "income", "poverty_rate", "unrate",
                "share_married_15p", "share_hs_plus_25p")

# ============================================================
# Unified Plotting Style (ggplot) — same as Event Study style
# ============================================================

plot_synth_level <- function(yrs, Y1, Y_synth, treated_fips, outcome_label, out_png){
  
  df <- tibble(
    year = yrs,
    actual = Y1,
    synthetic = Y_synth
  )
  
  p <- ggplot(df, aes(x = year)) +
    geom_line(aes(y = actual), color = "black", size = 1) +
    geom_line(aes(y = synthetic), color = "black", size = 1, linetype = "dashed") +
    geom_vline(xintercept = 2022, color = "grey40", size = 0.7) +
    labs(
      title = glue("FIPS {treated_fips}: Actual vs Synthetic"),
      x = "Year",
      y = outcome_label
    ) +
    theme_classic(base_size = 14) +
    theme(
      axis.line = element_line(color = "grey50"),
      plot.title = element_text(size = 13, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      axis.title.x = element_text(margin = margin(t = 10)),
      axis.title.y = element_text(margin = margin(r = 10))
    )
  
  ggsave(out_png, p, width = 8, height = 6, dpi = 300)
}


plot_synth_gap <- function(yrs, Y1, Y_synth, treated_fips, out_png){
  
  df <- tibble(
    year = yrs,
    gap = Y1 - Y_synth
  )
  
  p <- ggplot(df, aes(x = year, y = gap)) +
    geom_hline(yintercept = 0, size = 0.7, color = "grey50") +
    geom_line(color = "black", size = 1) +
    geom_vline(xintercept = 2022, color = "grey40", size = 0.7) +
    labs(
      title = glue("FIPS {treated_fips}: Gap (Actual − Synthetic)"),
      x = "Year",
      y = "Gap"
    ) +
    theme_classic(base_size = 14) +
    theme(
      axis.line = element_line(color = "grey50"),
      plot.title = element_text(size = 13, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      axis.title.x = element_text(margin = margin(t = 10)),
      axis.title.y = element_text(margin = margin(r = 10))
    )
  
  ggsave(out_png, p, width = 8, height = 6, dpi = 300)
}


# ---- Hold results ----
results_tbl <- tibble()
all_gaps <- tibble()

# ============================================
# Loop SCM for all treated states
# ============================================
for (treated_fips in treated_states) {
  
  message(glue("Running SCM for FIPS {treated_fips}..."))
  
  donor_pool <- donor_pool_all
  valid_donors <- panel |>
    filter(year %in% pre_period) |>
    group_by(fips) |>
    summarise(missing_y = any(is.na(sy_index))) |>
    filter(!missing_y) |>
    pull(fips)
  donor_pool <- donor_pool[donor_pool %in% valid_donors]
  
  if (length(donor_pool) < 3) {
    message(glue("Skip {treated_fips}: donor pool too small"))
    next
  }
  
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
    error = function(e){
      message(glue("Error in {treated_fips}: {e$message}"))
      return(NULL)
    }
  )
  
  if (is.null(synth.out) || is.null(synth.out$solution.w)) {
    message(glue("Skipping FIPS {treated_fips}: no valid solution"))
    next
  }
  
  Y1 <- as.numeric(dataprep.out$Y1plot)
  Y0 <- as.matrix(dataprep.out$Y0plot)
  W  <- synth.out$solution.w
  Y_synth <- as.numeric(Y0 %*% W)
  yrs <- dataprep.out$tag$time.plot
  
  idx_pre <- which(yrs < 2022 & !is.na(Y1) & !is.na(Y_synth))
  pre_mspe <- if (length(idx_pre) > 0) mean((Y1[idx_pre] - Y_synth[idx_pre])^2) else NA_real_
  
  gap_df <- tibble(fips = treated_fips, year = yrs, gap = Y1 - Y_synth)
  all_gaps <- bind_rows(all_gaps, gap_df)
  
  # ---- Level & Gap Plots (Unified Style) ----
  plot_synth_level(
    yrs, Y1, Y_synth, treated_fips,
    outcome_label = "sy_index",
    out_png = file.path(OUT_DIR, glue("synth_{treated_fips}_level.png"))
  )
  
  plot_synth_gap(
    yrs, Y1, Y_synth, treated_fips,
    out_png = file.path(OUT_DIR, glue("synth_{treated_fips}_gap.png"))
  )
  
  # ---- Export weights ----
  synth.tables <- synth.tab(dataprep.res = dataprep.out, synth.res = synth.out)
  write_csv(as.data.frame(synth.tables$tab.w),   file.path(OUT_DIR, glue("{treated_fips}_weights.csv")))
  write_csv(as.data.frame(synth.tables$tab.pred),file.path(OUT_DIR, glue("{treated_fips}_predictors.csv")))
  
  results_tbl <- bind_rows(results_tbl,
                           tibble(fips = treated_fips,
                                  pre_mspe = pre_mspe,
                                  n_donors = length(donor_pool)))
}

write_csv(results_tbl, file.path(OUT_DIR, "scm_mspe_summary.csv"))
message("=== SCM finished for all treated states ===")

# ============================================
# Aggregated Average Treatment Effect (Unified style)
# ============================================

gap_summary <- all_gaps |>
  group_by(year) |>
  summarise(
    avg_gap = mean(gap, na.rm = TRUE),
    se_gap  = sd(gap, na.rm = TRUE) / sqrt(sum(!is.na(gap))),
    n = sum(!is.na(gap))
  ) |>
  mutate(
    ci_low  = avg_gap - 1.96 * se_gap,
    ci_high = avg_gap + 1.96 * se_gap
  )

avg_effect <- gap_summary |>
  filter(year >= 2022) |>
  summarise(
    mean_post_gap = mean(avg_gap, na.rm = TRUE),
    mean_post_se  = mean(se_gap, na.rm = TRUE)
  )

write_csv(gap_summary, file.path(OUT_DIR, "average_gap_summary.csv"))
write_csv(avg_effect,  file.path(OUT_DIR, "average_policy_effect.csv"))

# ---- Aggregated Plot (Event-Study Style) ----

p <- ggplot(gap_summary, aes(x = year, y = avg_gap)) +
  geom_hline(yintercept = 0, size = 0.7, color = "grey50") +
  geom_line(aes(y = ci_high), linetype = "dashed", color = "black") +
  geom_line(aes(y = ci_low), linetype = "dashed", color = "black") +
  geom_line(color = "black", size = 1) +
  geom_vline(xintercept = 2022, color = "grey40", size = 0.7) +
  labs(
    title = "Average Synthetic Control Gap (Actual − Synthetic)",
    x = "Year",
    y = "Average Gap"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.line = element_line(color = "grey50"),
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10))
  )

ggsave(file.path(OUT_DIR, "average_gap_plot.png"), p, width = 8, height = 6, dpi = 300)

message("=== Aggregated effect figure saved ===")
