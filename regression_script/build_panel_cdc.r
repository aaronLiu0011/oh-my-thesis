library(tidyverse)
library(fixest)      
library(did)        
library(lfe)         
library(ggplot2)
library(broom)
library(data.table)
library(dplyr)
library(stringr)
library(plm)


#==========tool============
data_dir <- file.path(getwd(), "master_data")

norm_fips <- function(x) {
  x <- as.character(x)
  x <- gsub("\\D", "", x)
  ifelse(nchar(x)==2, x, str_pad(x, 2, pad="0"))
}

to_int <- function(x) suppressWarnings(as.integer(as.character(x)))
NA_STR <- c("Data not available","Data suppressed","Suppressed","NA","")

#==========Load Data=========
#----------
# data type
# - fips: character
# - Year/Month: integer
#----------

## Outcome

### y_1: Syphilis
y_sy <- fread(file.path(data_dir, "/STDs_state/Syphilis_state_2010_2023.csv"),
            na.strings = NA_STR)

pop <- y_sy |>
  transmute(
    fips = norm_fips(FIPS),
    year = as.numeric(Year),
    pop = as.numeric(gsub(",", "", Population))
  )

y_sy <- y_sy |>
  transmute(
    fips = norm_fips(FIPS),
    year = as.numeric(Year),
    sy_index = as.numeric(`Rate per 100000`)
  )



### y_2: Gonorrhea
y_go <- fread(file.path(data_dir, "/STDs_state/Gonorrhea_state_2010_2023.csv"),
              na.strings = NA_STR)
y_go <- y_go |>
  transmute(
    fips = norm_fips(FIPS),
    year = as.numeric(Year),
    go_index = as.numeric(`Rate per 100000`)
  )

### y_3: Chlamydia
y_ch <- fread(file.path(data_dir, "/STDs_state/Chlamydia_state_2010_2023.csv"),
              na.strings = NA_STR)
y_ch <- y_ch |>
  transmute(
    fips = norm_fips(FIPS),
    year = as.numeric(Year),
    ch_index = as.numeric(`Rate per 100000`)
  )

#-------------
## treatment Variables
abortion_policy <- fread(file.path(data_dir, "abortion_policies.csv"))

abortion_policy <- abortion_policy |>
  transmute(
    fips = norm_fips(state_fips),
    treated = as.integer(binary_treatment),
    treated_year = as.numeric(treated_year)
  ) |>
  mutate(
    cohort = ifelse(treated == 1 & !is.na(treated_year), treated_year, NA_integer_)
  ) |>
  select(fips, cohort) |>
  distinct()

#-------------
## Control Variables

### demographics
demo <- fread(file.path(data_dir, "/ctrl_var_state/state_demographics_2010_2023.csv"))
demo <- demo |>
  transmute(
    year = as.numeric(YEAR),
    fips = norm_fips(STATEA),
    share_age_15_44 = as.numeric(share_age_15_44),
    share_male = as.numeric(share_male),
    share_black = as.numeric(share_black),
    share_married_15p = as.numeric(share_married_15p),
    share_ba_plus_25p = as.numeric(share_ba_plus_25p),
    share_hs_plus_25p = as.numeric(share_hs_plus_25p)
    )

### insurance
uninsured <- fread(file.path(data_dir, "/ctrl_var_state/state_insurance_2010_2023.csv"))
uninsured <- uninsured |>
  transmute(
    year = as.numeric(year),
    fips = norm_fips(state),
    uninsured_pct = as.numeric(uninsured_pct)/100
  )

### income
income <- fread(file.path(data_dir, "/ctrl_var_state/state_percapita-income_2010_2025.csv"))
income <- income |>
  mutate(year = as.numeric(substr(month, 1, 4)),
         fips = norm_fips(fips)) |>     
  group_by(fips, year) |>
  summarise(income = mean(income, na.rm = TRUE)) |>
  ungroup()

### unemployment
urate <- fread(file.path(data_dir, "/ctrl_var_state/state_unemployment_2010_2024.csv"))
urate <- urate |>
  mutate(fips = norm_fips(state_fips),
         year = as.numeric(year)) |>
  group_by(fips, year) |>
  summarise(unrate = mean(urate , na.rm = TRUE)/100) |>
  ungroup()

### poverty rate
poverty <- fread(file.path(data_dir, "/ctrl_var_state/state_poverty_2010_2023.csv"))
poverty <- poverty |>
  transmute(
    fips = norm_fips(state),
    year = as.numeric(year),
    poverty_rate = as.numeric(poverty_rate)/100
  )



#==========Merge Panel=========
library(purrr)

y_panel <- reduce(
  list(y_sy, y_go, y_ch),
  full_join,
  by = c("fips", "year")
)

y_panel <- left_join(y_panel, abortion_policy,
                     by = c("fips"))

# controls
panel <- y_panel |>
  left_join(demo, by = c("fips", "year")) |>
  left_join(income, by = c("fips", "year")) |>
  left_join(poverty, by = c("fips", "year")) |>
  left_join(uninsured, by = c("fips", "year")) |>
  left_join(urate, by = c("fips", "year")) |>
  filter(cohort == 2022 | is.na(cohort)) |> # filtrate the late-adopted states
  filter(year != 2020) |>
  mutate(
    event_time = year - 2022,
    post = ifelse(year >= cohort & !is.na(cohort), 1, 0),
    treated = ifelse(is.na(cohort), 0, 1),
    did = treated * post
  )

panel <- panel |>
  mutate(
    sy_z = scale(sy_index)[,1],
    go_z = scale(go_index)[,1],
    ch_z = scale(ch_index)[,1],
    std_index = rowMeans(cbind(sy_z, go_z, ch_z), na.rm = TRUE)
  )

pdata <- pdata.frame(panel, index = c("fips", "year"))
pdim(pdata) 

colSums(is.na(panel))

write.csv(panel, "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv")