library(data.table)
library(lubridate)
library(zoo)

dt <- fread("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/percapita_income_raw.csv")

dt[, fips := sprintf("%02d", as.integer(GeoFips) / 1000)]

q_cols <- grep("^\\d{4}:Q[1-4]$", names(income), value = TRUE)

income_long <- data.table::melt(
  dt,
  id.vars = c("fips", "GeoName"),
  measure.vars = q_cols,
  variable.name = "quarter",
  value.name = "income"
)

income_long[, quarter := gsub(":", "-", quarter)]
income_long[, q_start := as.Date(as.yearqtr(quarter, format = "%Y-Q%q"))]

income_monthly <- income_long[,
  {
    month_seq <- seq(q_start, by = "month", length.out = 3)
    .(month = month_seq, income = income)
  },
  by = .(fips, GeoName, quarter)
]

fwrite(income_monthly, "/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_income_2010_2025.csv")
