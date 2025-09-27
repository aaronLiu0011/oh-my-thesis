library(tidyverse)
library(lubridate)

#========================
# Please read before run: 
# https://www.ncei.noaa.gov/pub/data/cirs/climdiv/state-readme.txt 
#========================

base_url <- "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/"
files <- readLines(base_url)

tmp_file_name <- stringr::str_extract(files, "climdiv-tmpcst-v1.0.0-[0-9]+")
tmp_file_name <- tmp_file_name[!is.na(tmp_file_name)][1]

file_url <- paste0(base_url, tmp_file_name)
message("Downloading: ", file_url)

tmp_file <- tempfile()
download.file(file_url, tmp_file, mode = "wb")

raw <- read.fwf(
  file = tmp_file,
  widths = c(3, 1, 2, 4, rep(7, 12)),
  col.names = c("state_code", "division", "element", "year", month.abb),
  stringsAsFactors = FALSE
)

raw <- raw |>
  filter(division == 0, element == 2)

raw[month.abb] <- lapply(raw[month.abb], function(x) {
  x <- as.numeric(x)
  x[x <= -99] <- NA
  return(x)
})

climate <- raw |>
  pivot_longer(cols = Jan:Dec, names_to = "month", values_to = "temp") |>
  mutate(
    month_num = match(month, month.abb),
    date = make_date(year, month_num, 1),
    temp = as.numeric(temp)
  ) |>
  filter(date >= as.Date("2018-01-01") & date <= as.Date("2025-09-01")) |>
  select(state_code, year, month_num, date, temp)

head(climate)

write_csv(climate, "state_monthly_temperature_2018_2025.csv")

