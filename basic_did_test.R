library(data.table)
library(dplyr)
library(fixest)
library(ggplot2)

dir <- "/Users/okuran/Desktop/thesis/processed_data"

sy <- fread(file.path(dir, "Primary_Secondary_Syphilis_2010_2023.csv"))
ab <- fread(file.path(dir, "abortion_policies_test.csv"))
ue    <- fread(file.path(dir, "merged_laucnty_unemployment_2010_2023.csv"))           # fips, year, unemployment_rate
sahie <- fread(file.path(dir, "sahie_county_insured_uninsured_2010_2023.csv"))  # fips, year, uninsured_rate
saipe <- fread(file.path(dir, "saipe_county_mhi_2010_2023_real2023usd.csv"))    # fips, year, mhi_real2023

norm_fips <- function(x) sprintf("%05s", gsub("\\D","", as.character(x)))

sy <- sy |>
  mutate(
    fips = norm_fips(fips),
    year = as.integer(sub("\\([^)]*\\)", "", Year)),
    rate = na_if(rate_per_100000, "Data not available"),
    rate = na_if(rate, "Data suppressed"),
    rate = as.numeric(rate)
  ) |>
  transmute(fips, year, y_syphilis = rate)

ue <- ue |>
  mutate(fips = norm_fips(fips), year = as.integer(year)) |>
  select(fips, year, unemp_rate)

ui <- sahie |>
  mutate(fips = norm_fips(fips), year = as.integer(year)) |>
  select(fips, year, PCTUI_PT)

mhi <- saipe |>
  mutate(fips = norm_fips(fips), year = as.integer(year)) |>
  select(fips, year, mhi_real_2023usd)

ab <- ab |>
  mutate(
    state_fips = sprintf("%02s", gsub("\\D","", as.character(state_fips))),
    treated_year = as.integer(treated_year)
  ) |>
  select(state_fips, treated_year, binary_treatment)

# ==========================================
panel <- sy |>
  left_join(ue,  by = c("fips","year")) |>
  left_join(ui,  by = c("fips","year")) |>
  left_join(mhi, by = c("fips","year")) |>
  mutate(state_fips = substr(fips, 1, 2)) |>
  left_join(ab, by = "state_fips")

# ==========================================
panel <- panel |>
  mutate(
    post  = as.integer(!is.na(treated_year) & year >= treated_year),
    did   = binary_treatment * post,
    # define event time for treated units
    event_time = ifelse(binary_treatment == 1, year - treated_year, NA_integer_)
  )

# set a period
panel <- panel |> filter(!is.na(y_syphilis), year >= 2010, year <= 2023)
# drop the units whose treated year is 2023
panel <- panel |>
  filter(!state_fips %in% c("18", "31", "37", "45"))
# =========================================
# fixest 默认去除完全多重共线性
did_fit <- feols(
  y_syphilis ~ did + PCTUI_PT + unemp_rate + mhi_real_2023usd | fips + year,
  data = panel,
  cluster = ~ state_fips # cluster at state level
)
etable(did_fit, se = "cluster")

# Robustness: log(1 + rate) 
did_fit_log <- feols(
  log1p(y_syphilis) ~ did + PCTUI_PT + unemp_rate + mhi_real_2023usd | fips + year,
  data = panel,
  cluster = ~ state_fips
)
etable(did_fit, did_fit_log, se = "cluster", headers = c("Level","Log(1+rate)"))

# ==========================================
# sunab(g, t): g = treated_year, t = year
# treated_year=NA will be never-treated units
es_fit <- feols(
  y_syphilis ~ sunab(treated_year, year) + PCTUI_PT + unemp_rate + mhi_real_2023usd | fips + year,
  data = panel,
  cluster = ~ state_fips
)

iplot(es_fit, ref.line = 0, xlab = "Event time (years)", ylab = "Effect on syphilis rate",
      main = "Event study (Sun & Abraham via fixest)")

# coefficient of event study 
es_coefs <- broom::tidy(es_fit) |> filter(grepl("^sunab::", term))
head(es_coefs)

# ===================== 
# (a) 人口加权：若有 population 列，可在 feols 中使用 weights = ~ population
# (b) 子样本：例如仅 treated 与从未采用州
# panel_sub <- panel |> filter(treated==1 | is.na(treated_year))
# (c) 事件窗：fixest::sunab 可加 trim = c(-4,4) 仅展示 -4~+4
# es_fit_win <- feols(y_syphilis ~ sunab(treated_year, year, trim = c(-4,4)) | fips + year,
#                     data = panel, cluster = ~ state_fips)
# iplot(es_fit_win, ref.line=0)

