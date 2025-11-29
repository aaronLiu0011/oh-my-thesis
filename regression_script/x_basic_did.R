library(data.table)
library(dplyr)
library(fixest)
library(ggplot2)
library(did)

dir <- "/Users/okuran/Desktop/thesis/processed_data"

# ==========================================
# syphilis
sy <- fread(file.path(dir, "Primary_Secondary_Syphilis_2010_2023.csv"))

# abortion policies
ab <- fread(file.path(dir, "abortion_policies.csv"))

# control
ue    <- fread(file.path(dir, "merged_laucnty_unemployment_2010_2023.csv"))           # fips, year, unemployment_rate
sahie <- fread(file.path(dir, "sahie_county_insured_uninsured_2010_2023.csv"))  # fips, year, uninsured_rate
saipe <- fread(file.path(dir, "saipe_county_mhi_2010_2023_real2023usd.csv"))    # fips, year, mhi_real2023

# ==========================================
norm_fips <- function(x) sprintf("%05s", gsub("\\D","", as.character(x)))

sy <- sy %>%
  mutate(
    fips = norm_fips(fips),
    year = as.integer(Year),
    Cases = suppressWarnings(as.numeric(gsub(",", "", Cases))),
    rate_per_100000 = suppressWarnings(as.numeric(rate_per_100000)),
    Population = suppressWarnings(as.numeric(gsub(",", "", Population)))
  ) %>%
  mutate(
    rate = ifelse(!is.na(rate_per_100000), rate_per_100000,
                  ifelse(!is.na(Cases) & !is.na(Population) & Population > 0,
                         (Cases / Population) * 1e5, NA_real_))
  ) %>%
  transmute(fips, year, y_syphilis = rate)

ue <- ue %>%
  mutate(fips = norm_fips(fips), year = as.integer(year)) %>%
  select(fips, year, unemp_rate)

ui <- sahie %>%
  mutate(fips = norm_fips(fips), year = as.integer(year)) %>%
  select(fips, year, PCTUI_PT)

mhi <- saipe %>%
  mutate(fips = norm_fips(fips), year = as.integer(year)) %>%
  select(fips, year, mhi_real_2023usd)

ab <- ab %>%
  mutate(
    state_fips = sprintf("%02s", gsub("\\D","", as.character(state_fips))),
    adopt_year = as.integer(treated_year),
  ) %>%
  select(state_fips, adopt_year, binary_treatment)

# ==========================================
panel <- sy %>%
  left_join(ue,  by = c("fips","year")) %>%
  left_join(ui,  by = c("fips","year")) %>%
  left_join(mhi, by = c("fips","year")) %>%
  mutate(state_fips = substr(fips, 1, 2)) %>%
  left_join(ab, by = "state_fips")

# ===================== 4) 构造 DID / Event Study 变量 =====================
panel <- panel %>%
  mutate(
    post  = as.integer(!is.na(adopt_year) & year >= adopt_year),
    did   = binary_treatment * post,
    # event time 仅对 treated 州定义；未采用设为 NA
    event_time = ifelse(binary_treatment == 1, year - adopt_year, NA_integer_)
  )

panel <- panel %>% filter(!is.na(y_syphilis), year >= 2010, year <= 2023)

panel <- panel %>%
  filter(!state_fips %in% c("12", "18", "19", "31", "37", "45"))

# ===================== 5) 最基础 DID（县FE×年FE，州聚类） =====================
# 注意：fixest 默认去除完全多重共线性。聚类在州层。
did_fit <- feols(
  y_syphilis ~ did + PCTUI_PT + unemp_rate + mhi_real_2023usd | fips + year,
  data = panel,
  cluster = ~ state_fips
)
etable(did_fit, se = "cluster")

# 对因变量做 log(1 + rate) 稳健性
did_fit_log <- feols(
  log1p(y_syphilis) ~ did + PCTUI_PT + unemp_rate + mhi_real_2023usd | fips + year,
  data = panel,
  cluster = ~ state_fips
)
etable(did_fit, did_fit_log, se = "cluster", headers = c("Level","Log(1+rate)"))


# ===================== Event study（Sun & Abraham 在 fixest 的 sunab） =====================
# sunab(g, t) 里 g = adopt_year（分组/采用年），t = year（时间）
# 未采用州 adopt_year=NA 会自动作为“永不处理”对照组
es_fit <- feols(
  y_syphilis ~ sunab(adopt_year, year) + PCTUI_PT + unemp_rate + mhi_real_2023usd | fips + year,
  data = panel,
  cluster = ~ state_fips
)
ggiplot(es_fit,
        ref.line = 0, # ggiplot 也支持这些参数
        xlab = "Event time (years)",
        ylab = "Effect on syphilis rate",
        main = "Event study (Sun & Abraham via ggiplot)")

# 同样可以添加垂直线
abline(v = -0.5, lty = 2, col = "red")

# ===================== 7) 常见变体 =====================
# (a) 人口加权：若有 population 列，可在 feols 中使用 weights = ~ population
# (b) 子样本：例如仅 treated 与从未采用州
# panel_sub <- panel %>% filter(treated==1 | is.na(adopt_year))
# (c) 事件窗：fixest::sunab 可加 trim = c(-4,4) 仅展示 -4~+4
# es_fit_win <- feols(y_syphilis ~ sunab(adopt_year, year, trim = c(-4,4)) | fips + year,
#                     data = panel, cluster = ~ state_fips)
# iplot(es_fit_win, ref.line=0)