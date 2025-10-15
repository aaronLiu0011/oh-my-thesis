library(fixest)
library(data.table)

panel <- fread("/Users/okuran/Desktop/thesis/master_data/panel.csv")
panel[, fips_id := as.numeric(factor(fips))]

mod_sunab_go <- feols(
  go_index ~ sunab(treat_time, time_id) + percapita_income + urate + temp + Cong_per_100000 +
    age_15_44 + black_share + hispanic_share +
    uninsured_pct + highschool + married +
    unmarried_birth + physician_rate,
  data = panel,
  fixef = c("fips_id", "time_id"),
  cluster = "fips_id"
)

summary(mod_sunab_go)

iplot(mod_sunab_go,
      main = "Event Study: Sun & Abraham",
      xlab = "Years since treatment",
      ylab = "ATT")

iplot(mod_sunab_go, ref.line = 0, xlim = c(-12, 24))
