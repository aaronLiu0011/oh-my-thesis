# ============================================
# Synthetic Control (using Synth package)
# ============================================
library(Synth)
library(tidyverse)
library(glue)


DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out/scm_synth"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

# ---- Load panel ----
panel <- read_csv(DATA_PATH, show_col_types = FALSE) |>
  mutate(fips = as.numeric(fips),
         year = as.numeric(year),
         treated = as.integer(cohort == 2022))


# ---- Set treated unit ----
treated_fips <- 48   # Texas

# ---- Define time windows ----
pre_period  <- setdiff(2010:2021, 2020) 
post_period <- 2022:2023
plot_period <- setdiff(2010:2023, 2020)

# ---- Build donor pool (never treated, not neighbor) ----
donor_pool <- panel |>
  group_by(fips) |>
  summarize(ever_treated = if (all(is.na(cohort))) 0 else max(cohort == 2022, na.rm = TRUE)) |>
  filter(ever_treated == 0) |>
  pull(fips)

valid_donors <- panel |>
  filter(year %in% pre_period) |>
  group_by(fips) |>
  summarise(missing_y = any(is.na(sy_index))) |>
  filter(!missing_y) |>
  pull(fips)

donor_pool <- donor_pool[donor_pool %in% valid_donors]

# ---- Variable selection ----
Yvar <- "sy_index"
predictors <- c("share_age_15_44", "share_male", "share_black",
                "income", "poverty_rate","unrate", "share_married_15p",
                "share_hs_plus_25p")

# ---- Prepare data for Synth ----
special.predictors <- list(
  list("sy_index", 2012, "level"),
  list("sy_index", 2014, "level"),
  list("sy_index", 2016, "level"),
  list("sy_index", 2018, "level"),
  list("sy_index", 2021, "level"),
  list("sy_index", 2010:2014, "mean"),
  list("sy_index", 2015:2021, "mean")
)

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

# ---- Run synth ----
synth.out <- synth(dataprep.out, nested = TRUE)

# ---- Extract results ----
path.plot(synth.res = synth.out, dataprep.res = dataprep.out,
          Ylab = "sy_index", Xlab = "Year",
          Legend = c("Texas", "Synthetic Texas"),
          Legend.position = "bottomright")

png(file.path(OUT_DIR, glue("synth_tx_sy_index_level.png")), width=700, height=500)
path.plot(synth.res = synth.out, dataprep.res = dataprep.out,
          Ylab = "sy_index", Xlab = "Year",
          Legend = c("Texas", "Synthetic Texas"),
          Legend.position = "bottomright")
dev.off()

# ---- GAP plot (Actual − Synthetic) ----
gaps.plot(synth.res = synth.out, dataprep.res = dataprep.out,
          Ylab = "Gap (Actual - Synthetic)", Xlab = "Year")
png(file.path(OUT_DIR, glue("synth_tx_sy_index_gap.png")), width=700, height=500)
gaps.plot(synth.res = synth.out, dataprep.res = dataprep.out,
          Ylab = "Gap (Actual - Synthetic)", Xlab = "Year")
dev.off()

# ---- Tables of weights ----
synth.tables <- synth.tab(dataprep.res = dataprep.out, synth.res = synth.out)
write_csv(as.data.frame(synth.tables$tab.w), file.path(OUT_DIR, "tx_weights.csv"))
write_csv(as.data.frame(synth.tables$tab.pred), file.path(OUT_DIR, "tx_predictors.csv"))
