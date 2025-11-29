# ============================================================
# Sun & Abraham Event Study for Three STDs
# ============================================================

library(fixest)
library(data.table)
library(modelsummary)

# ------------------------------
# 1. Load panel
# ------------------------------

panel <- fread("/Users/okuran/Desktop/thesis/master_data/state_panel_2018_2024.csv")

# create FE id
panel[, fips_id := as.numeric(factor(fips))]

# relative time
panel[, rel_time := time_id - treat_time]

# restrict event window
panel <- panel[is.na(rel_time) | (rel_time >= -24 & rel_time <= 24)]

# ------------------------------
# 2. Outcomes & controls
# ------------------------------

outcomes <- c("sy_index", "go_index", "ch_index")

controls <- c(
  "income_log", "unrate", "temp", "covid_cases_per_100k",
  "share_age_15_44", "share_male", "share_black",
  "share_married_15p", "share_ba_plus_25p",
  "share_hs_plus_25p", "poverty_rate", "uninsured_rate",
  "internet_use_pct"
)

# If no-controls needed:
# controls <- character(0)


# ------------------------------
# 3. Run Sun & Abraham + Event Study plotting
# ------------------------------

run_event_study <- function(y, panel, controls, save = FALSE, outdir = NULL){
  
  # --- Build formula
  if (length(controls) == 0) {
    fml <- as.formula(
      paste0(
        y, " ~ sunab(treat_time, time_id)"
      )
    )
  } else {
    fml <- as.formula(
      paste0(
        y, " ~ sunab(treat_time, time_id) + ",
        paste(controls, collapse = " + ")
      )
    )
  }
  
  # --- Estimate model
  model <- feols(
    fml,
    data = panel,
    fixef = c("fips_id", "time_id"),
    cluster = "fips_id"
  )
  
  print(summary(model))
  
  # --- Draw event-study plot
  p <- iplot(
    model,
    main = paste0("Event Study (Sun & Abraham): ", y),
    xlab = "Years since treatment",
    ylab = "ATT",
    ref.line = 0,
    xlim = c(-24, 24)
  )
  
  # --- Save plot if required
  if (save) {
    fname <- paste0(outdir, "/", y, "_event_study.png")
    png(fname, width = 1600, height = 1200, res = 200)
    iplot(
      model,
      main = paste0("Event Study (Sun & Abraham): ", y),
      xlab = "Years since treatment",
      ylab = "ATT",
      ref.line = 0,
      xlim = c(-24, 24)
    )
    dev.off()
  }
  
  return(model)
}


# ------------------------------
# 4. Run for all three diseases
# ------------------------------

out_dir <- "/Users/okuran/Desktop/thesis/out/event_study_sunab"

models <- lapply(
  outcomes,
  \(y) run_event_study(
    y = y,
    panel = panel,
    controls = controls,
    save = TRUE,
    outdir = out_dir
  )
)

names(models) <- c("Syphilis", "Gonorrhea", "Chlamydia")



