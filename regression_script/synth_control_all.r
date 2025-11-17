# ============================================
# Synthetic Control (All Treated States + Aggregated Effect)
# ============================================
library(Synth)
library(tidyverse)
library(glue)
library(ggplot2)

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

# ---- Variable selection ----
Yvar <- "sy_index"
predictors <- c("share_age_15_44", "share_male", "share_black",
                "income", "poverty_rate", "unrate",
                "share_married_15p", "share_hs_plus_25p")



# ---- Initialize result holders ----
results_tbl <- tibble()
all_gaps <- tibble()

# ============================================
# Loop over treated states
# ============================================
for (treated_fips in treated_states) {
  message(glue("Running SCM for FIPS {treated_fips}..."))
  
  # donor pool
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
  
  # dataprep
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
  
  # synth
  synth.out <- tryCatch(
    synth(dataprep.out, nested = TRUE),
    error = function(e) {
      message(glue("Error in {treated_fips}: {e$message}"))
      return(NULL)
    }
  )
  
  if (is.null(synth.out) || is.null(synth.out$solution.w)) {
    message(glue("Skipping FIPS {treated_fips}: no valid solution"))
    next
  }
  
  # ---- Compute pre-period MSPE & gaps ----
  Y1 <- as.numeric(dataprep.out$Y1plot)
  Y0 <- as.matrix(dataprep.out$Y0plot)
  W  <- synth.out$solution.w
  Y_synth <- as.numeric(Y0 %*% W)
  yrs <- dataprep.out$tag$time.plot
  
  idx_pre <- which(yrs < 2022 & !is.na(Y1) & !is.na(Y_synth))
  if (length(idx_pre) > 0) {
    pre_mspe <- mean((Y1[idx_pre] - Y_synth[idx_pre])^2)
  } else {
    pre_mspe <- NA_real_
  }
  
  gap_df <- tibble(fips = treated_fips, year = yrs, gap = Y1 - Y_synth)
  all_gaps <- bind_rows(all_gaps, gap_df)
  
  # ---- Plot results ----
  path_level <- file.path(OUT_DIR, glue("synth_{treated_fips}_level.png"))
  png(path_level, width = 700, height = 500)
  plot(yrs, Y1, type = "l", col = "black", lwd = 2, ylim = range(c(Y1, Y_synth), na.rm=TRUE),
       xlab = "Year", ylab = "sy_index", main = glue("FIPS {treated_fips}: Actual vs Synthetic"))
  lines(yrs, Y_synth, col = "red", lwd = 2)
  abline(v = 2022, lty = 2, col = "gray40")
  legend("bottomright", legend = c("Actual", "Synthetic"), col = c("black", "red"), lwd = 2)
  dev.off()
  
  path_gap <- file.path(OUT_DIR, glue("synth_{treated_fips}_gap.png"))
  png(path_gap, width = 700, height = 500)
  plot(yrs, Y1 - Y_synth, type = "l", col = "steelblue", lwd = 2,
       xlab = "Year", ylab = "Gap (Actual - Synthetic)",
       main = glue("FIPS {treated_fips}: Gap Plot"))
  abline(h = 0, lty = 2)
  abline(v = 2022, lty = 2, col = "red")
  dev.off()
  
  # ---- Export weights ----
  synth.tables <- synth.tab(dataprep.res = dataprep.out, synth.res = synth.out)
  write_csv(as.data.frame(synth.tables$tab.w), file.path(OUT_DIR, glue("{treated_fips}_weights.csv")))
  write_csv(as.data.frame(synth.tables$tab.pred), file.path(OUT_DIR, glue("{treated_fips}_predictors.csv")))
  
  # ---- Store summary ----
  results_tbl <- bind_rows(results_tbl,
                           tibble(fips = treated_fips,
                                  pre_mspe = pre_mspe,
                                  n_donors = length(donor_pool)))
}

# ---- Save summary table ----
write_csv(results_tbl, file.path(OUT_DIR, "scm_mspe_summary.csv"))
message("=== SCM for all treated states completed ===")

# ============================================
# Aggregate Average Policy Effect
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

# ---- Average effect after 2022 ----
avg_effect <- gap_summary |>
  filter(year >= 2022) |>
  summarise(
    mean_post_gap = mean(avg_gap, na.rm = TRUE),
    mean_post_se  = mean(se_gap, na.rm = TRUE)
  )

write_csv(gap_summary, file.path(OUT_DIR, "average_gap_summary.csv"))
write_csv(avg_effect,  file.path(OUT_DIR, "average_policy_effect.csv"))

# ---- Plot aggregated effect ----
p <- ggplot(gap_summary, aes(x = year, y = avg_gap)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), fill = "grey", alpha = 0.3) +
  geom_line(color = "black", size = 1.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = 2022, color = "red", linetype = "dotted") +
  labs(
    title = "Average Treatment Effect across 2022 Abortion Ban States",
    subtitle = "Average Gap (Actual − Synthetic) in STI Index",
    x = "Year", y = "Average Gap"
  ) +
  theme_minimal(base_size = 14)

ggsave(file.path(OUT_DIR, "average_gap_plot.png"), p, width = 7, height = 5, dpi = 300)

message("=== Aggregated average effect plot and tables saved ===")
