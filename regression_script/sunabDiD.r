library(fixest)
library(data.table)

panel <- fread("/Users/okuran/Desktop/thesis/master_data/panel.csv")
panel[, fips_id := as.numeric(factor(fips))]

mod_sunab_ch <- feols(
  log(1+ch_index) ~ sunab(treat_time, time_id),
  data = panel,
  fixef = c("fips_id", "time_id"),
  cluster = "fips_id"
)

summary(mod_sunab_ch)

iplot(mod_sunab_ch,
      main = "Event Study: Sun & Abraham",
      xlab = "Years since treatment",
      ylab = "ATT")

iplot(mod_sunab_ch, ref.line = 0, xlim = c(-12, 24))
