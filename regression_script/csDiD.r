library(did)
library(data.table)
library("panelView")

panel <- fread("/Users/okuran/Desktop/thesis/master_data/panel.csv")

summary(panel$time_id)
summary(panel$treat_time)

panel[, fips_id := as.numeric(factor(fips))]

att_monthly <- att_gt(
  yname   = "sy_index",
  tname   = "time_id",
  idname  = "fips_id",
  gname   = "treat_time",
  xformla = ~ 1,
  data    = panel
)

summary(att_monthly)

agg_simple  <- aggte(att_monthly, type = "simple", na.rm = TRUE)
agg_dynamic <- aggte(att_monthly, type = "dynamic", na.rm = TRUE)

summary(agg_simple)
summary(agg_dynamic)
