library(tidyverse)

data <- read_csv("/Users/okuran/Desktop/thesis/master_data/ctrl_var_state/state_titleX_user_2010_2023.csv")

national_trend <- data %>%
  group_by(Year) %>%
  summarise(total_users = sum(Total, na.rm = TRUE)) %>%
  ungroup()

p <- ggplot(national_trend, aes(x = Year, y = total_users)) +
  geom_line(linewidth = 1.2, color = "steelblue4") +
  geom_point(size = 2.5, color = "steelblue4") +
  geom_smooth(method = "loess", se = FALSE, color = "grey40", linetype = "dashed") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Title X Program Utilization in the United States (2010–2023)",
    subtitle = "Total number of clients served annually",
    x = "Year",
    y = "Total Users",
    caption = "Source: Title X Program State-Level Reports, 2010–2023"
  ) +
  theme_minimal(base_family = "Times", base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 12, color = "grey30"),
    plot.caption = element_text(size = 9, hjust = 1, color = "grey50"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    plot.margin = margin(10, 15, 10, 10)
  )

print(p)
