library(dplyr)
library(ggplot2)

gon_avg <- go |>
  group_by(year) |>
  summarise(avg_rate = mean(rate_gon, na.rm = TRUE))

ggplot(gon_avg, aes(x = factor(year), y = avg_rate)) +
  geom_col(fill = "blue") +
  labs(x = "Year", 
       y = "Average Rate per 100k",
       title = "Average Rate per 100k by Year (Gonorrhea)") +
  theme_minimal()


syp_avg <- sy |>
  group_by(year) |>
  summarise(avg_rate = mean(rate_syphilis, na.rm = TRUE))

ggplot(syp_avg, aes(x = factor(year), y = avg_rate)) +
  geom_col(fill = "red") +
  labs(x = "Year", 
       y = "Average Rate per 100k",
       title = "Average Rate per 100k by Year (Syphilis)") +
  theme_minimal()