library(tidycensus)
library(tidyverse)

years <- c(2011:2019,2021:2024)

vars_list <- map(years, ~{
  load_variables(.x, "acs1/profile", cache = TRUE) %>%
    mutate(year = .x)
})

vars_all <- bind_rows(vars_list)

focus <- vars_all %>%
  filter(
    grepl("Percent", label, ignore.case = TRUE)
  ) %>%
  filter(
    grepl("high school", label, ignore.case = TRUE) |
      grepl("bachelor", label, ignore.case = TRUE) |
      grepl("internet", label, ignore.case = TRUE) |
      grepl("Never married", label, ignore.case = TRUE) |
      grepl("Now married", label, ignore.case = TRUE) |
      grepl("black", label, ignore.case = TRUE)
  )

View(focus)

focus %>% 
  group_by(label) %>%
  summarize(
    n_codes = n_distinct(name),
    codes = paste(unique(name), collapse = ", ")
  ) %>% 
  arrange(desc(n_codes))

focus %>% 
  count(year, name) %>% 
  arrange(name, year)

write_csv(focus, "/Users/okuran/Desktop/thesis/data_reference/acs_profile_variable_changes_2011_2024.csv")