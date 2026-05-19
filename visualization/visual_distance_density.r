library(tidyverse)
library(ggplot2)
library(patchwork)

panel <- read_csv("/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv")

theme_clean <- theme_minimal(base_size = 16) +
  theme(
    legend.position = c(0.98, 0.98),
    legend.justification = c(1, 1),
    legend.title    = element_blank(),
    legend.background = element_rect(
      fill = "white", color = NA
    ),
    
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    
    panel.background   = element_rect(fill = "white", color = NA),
    plot.background    = element_rect(fill = "white", color = NA)
  )



# =======================
# Treated 图
# =======================
df_treated <- panel %>%
  filter(treated == 1, year %in% c(2021, 2023)) %>%
  mutate(year = factor(year))

p_treated <- ggplot(df_treated, aes(x = distance, color = year, fill = year)) +
  geom_density(alpha = 0.25, size = 0.5) +
  scale_color_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  scale_fill_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  labs(
    x = "Distance (miles)",
    y = "Density",
    color = "Year",
    fill = "Year"
  ) +
  theme_clean

ggsave(
  filename = "/Users/okuran/Desktop/thesis/out/distance_density_treated.pdf",
  plot = p_treated,
  width = 6,
  height = 4
)


# =======================
# Control 图
# =======================
df_control <- panel %>%
  filter(treated == 0, year %in% c(2021, 2023)) %>%
  mutate(year = factor(year))

p_control <- ggplot(df_control, aes(x = distance, color = year, fill = year)) +
  geom_density(alpha = 0.25, size = 0.5) +
  scale_color_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  scale_fill_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  labs(
    x = "Distance (miles)",
    y = "Density",
    color = "Year",
    fill = "Year"
  ) +
  theme_clean

ggsave(
  filename = "/Users/okuran/Desktop/thesis/out/distance_density_control.pdf",
  plot = p_control,
  width = 6,
  height = 4
)
