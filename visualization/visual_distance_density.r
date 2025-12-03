library(tidyverse)
library(ggplot2)
library(patchwork)

panel <- read_csv("/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv")

# =======================
# Treated 图
# =======================
df_treated <- panel %>%
  filter(treated == 1, year %in% c(2021, 2023)) %>%
  mutate(year = factor(year))

p_treated <- ggplot(df_treated, aes(x = distance, color = year, fill = year)) +
  geom_density(alpha = 0.25, size = 1.0) +
  scale_color_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  scale_fill_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  labs(
    title = "Treated States",
    x = "Distance (miles)",
    y = "Density",
    color = "Year",
    fill = "Year"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

# =======================
# Control 图
# =======================
df_control <- panel %>%
  filter(treated == 0, year %in% c(2021, 2023)) %>%
  mutate(year = factor(year))

p_control <- ggplot(df_control, aes(x = distance, color = year, fill = year)) +
  geom_density(alpha = 0.25, size = 1.0) +
  scale_color_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  scale_fill_manual(values = c("2021" = "#1f77b4", "2023" = "#d62728")) +
  labs(
    title = "Control States",
    x = "Distance (miles)",
    y = "Density",
    color = "Year",
    fill = "Year"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    axis.title.y = element_blank()
  )

# =======================
# 左右并排
# =======================
p_final <- p_treated + p_control +
  plot_layout(ncol = 2, guides = "collect") & theme(legend.position = "bottom")

p_final

ggsave(
  filename = "/Users/okuran/Desktop/thesis/out/distance_density.pdf",
  plot = p_final,
  width = 12,
  height = 5
)
