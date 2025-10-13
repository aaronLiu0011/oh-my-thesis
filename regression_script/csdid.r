library(did)
library(data.table)

panel <- fread("/Users/okuran/Desktop/thesis/master_data/panel.csv")

summary(panel$time_id)
summary(panel$treat_time)

panel[, fips_id := as.numeric(factor(fips))]

att_monthly <- att_gt(
  yname   = "sy_index",
  tname   = "time_id",
  idname  = "fips",
  gname   = "treat_time",
  xformla = ~ percapita_income + urate + temp + Cong_per_100000 +
    age_15_44 + black_share + hispanic_share +
    uninsured_pct + highschool + married +
    unmarried_birth + physician_rate,
  data    = panel,
  est_method     = "dr",
  control_group  = "nevertreated"
)

summary(att_monthly)

agg_simple  <- aggte(att_monthly, type = "simple", na.rm = TRUE)
agg_dynamic <- aggte(att_monthly, type = "dynamic", na.rm = TRUE)

summary(agg_simple)
summary(agg_dynamic)
