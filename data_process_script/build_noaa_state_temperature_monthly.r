library(tidyverse)
library(lubridate)

#========================
# Please read before run: 
# https://www.ncei.noaa.gov/pub/data/cirs/climdiv/state-readme.txt 
#========================
# NOAA state code → FIPS mapping
noaa_to_fips <- tribble(
  ~noaa_code, ~fips, ~state_name,
  1,  1, "Alabama",    2,  4, "Arizona",      3,  5, "Arkansas",
  4,  6, "California", 5,  8, "Colorado",     6,  9, "Connecticut",
  7, 10, "Delaware",   8, 12, "Florida",      9, 13, "Georgia",
  10, 16, "Idaho",     11, 17, "Illinois",    12, 18, "Indiana",
  13, 19, "Iowa",      14, 20, "Kansas",      15, 21, "Kentucky",
  16, 22, "Louisiana", 17, 23, "Maine",       18, 24, "Maryland",
  19, 25, "Massachusetts", 20, 26, "Michigan", 21, 27, "Minnesota",
  22, 28, "Mississippi", 23, 29, "Missouri",  24, 30, "Montana",
  25, 31, "Nebraska",  26, 32, "Nevada",      27, 33, "New Hampshire",
  28, 34, "New Jersey", 29, 35, "New Mexico", 30, 36, "New York",
  31, 37, "North Carolina", 32, 38, "North Dakota", 33, 39, "Ohio",
  34, 40, "Oklahoma",  35, 41, "Oregon",      36, 42, "Pennsylvania",
  37, 44, "Rhode Island", 38, 45, "South Carolina", 39, 46, "South Dakota",
  40, 47, "Tennessee", 41, 48, "Texas",       42, 49, "Utah",
  43, 50, "Vermont",   44, 51, "Virginia",    45, 53, "Washington",
  46, 54, "West Virginia", 47, 55, "Wisconsin", 48, 56, "Wyoming",
  49, 15, "Hawaii",    50,  2, "Alaska"
)

# --- Download & Read NOAA data ---
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

# --- Filter for statewide mean temperature ---
raw <- raw |>
  filter(division == 0, element == 2)

# --- Replace missing values ---
raw[month.abb] <- lapply(raw[month.abb], function(x) {
  x <- as.numeric(x)
  x[x <= -99] <- NA
  return(x)
})

# --- Reshape and attach FIPS ---
climate <- raw |>
  pivot_longer(cols = Jan:Dec, names_to = "month", values_to = "temp") |>
  mutate(
    month_num = match(month, month.abb),
    date = make_date(year, month_num, 1),
    state_code = as.numeric(state_code)
  ) |>
  left_join(noaa_to_fips, by = c("state_code" = "noaa_code")) |>
  filter(!is.na(fips)) |>  # exclude region/national codes
  filter(date >= as.Date("2018-01-01") & date <= as.Date("2025-09-01")) |>
  select(fips, state_name, year, month_num, date, temp)

dc <- climate |> filter(fips == 24) |> mutate(fips = 11, state_name = "District of Columbia")
climate <- bind_rows(climate, dc) |> arrange(fips, date)

# --- Export ---
write_csv(climate, "state_temperature_monthly_2018_2025.csv")

head(climate)