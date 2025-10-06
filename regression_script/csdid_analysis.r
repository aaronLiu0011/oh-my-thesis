library(data.table)
library(dplyr)
library(fixest)
library(ggplot2)
library(stringr)

#==========tool============
data_dir <- file.path(getwd(), "master_data")
ctrlVar_dir <- file.path(getwd(), "master_data/ctrl_var_state_2018_2025")

norm_fips <- function(x) {
  x <- as.character(x)
  x <- gsub("\\D", "", x)
  ifelse(nchar(x)==2, x, str_pad(x, 2, pad="0"))
}

to_int <- function(x) suppressWarnings(as.integer(as.character(x)))
NA_STR <- c("Data not available","Data suppressed","Suppressed","NA","")

#==========Load Data=========

## Outcome (Google Trends)

### y_1: Syphilis
sy <- fread(file.path(data_dir, "10-5_processed_Syphilis_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
sy <- sy |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    Year = format(date, "%Y"),
    Month = format(date, "%m"),
    sy_index = as.numeric(value_scaled)
  )

### y_2: Gonorrhea
go <- fread(file.path(data_dir, "10-5_processed_Gonorrhea_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
go <- go |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    Year = format(date, "%Y"),
    Month = format(date, "%m"),
    go_index = as.numeric(value_scaled)
  )

### y_3: Chlamydia
ch <- fread(file.path(data_dir, "10-5_processed_Chlamydia_CA_anchor_scaled.csv"),
            na.strings = NA_STR)
ch <- ch |>
  transmute(
    fips = norm_fips(FIPS),
    date = as.Date(Month),
    Year = format(date, "%Y"),
    Month = format(date, "%m"),
    ch_index = as.numeric(value_scaled)
  )

#-------------
## Control Variables

### x_1: Unemployment rate
congregation <- fread(file.path(ctrlVar_dir, "state_congregation_2020.csv"))
congregation <- congregation |>
  transmute(
    fips = norm_fips(`State Code`),
    Cong_per_100000 = as.numeric(`Congregations per 100,000 Population`)
  )

