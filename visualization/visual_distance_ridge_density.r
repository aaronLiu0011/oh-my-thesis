library(tidyverse)
library(ggplot2)
library(ggridges)
library(patchwork)

# =============================
# Treated Data
# =============================
df_treated <- panel %>%
  filter(treated == 1, year >= 2016, year <= 2023) %>%
  mutate(year = factor(year))

p_treated <- ggplot(df_treated, aes(
  x = distance,
  y = year,
  fill = after_stat(x)
)) +
  geom_density_ridges_gradient(
    scale = 2.0,
    rel_min_height = 0.01,
    color = "black",
    size = 0.3
  ) +
  scale_fill_viridis_c(option = "plasma", name = "Distance\n(miles)") +
  labs(
    title = "Treated States",
    x = "Distance (miles)",
    y = "Year"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )


# =============================
# Control Data
# =============================
df_control <- panel %>%
  filter(is.na(treated), year >= 2016, year <= 2023) %>%
  mutate(year = factor(year))

p_control <- ggplot(df_control, aes(
  x = distance,
  y = year,
  fill = after_stat(x)
)) +
  geom_density_ridges_gradient(
    scale = 2.0,
    rel_min_height = 0.01,
    color = "black",
    size = 0.3
  ) +
  scale_fill_viridis_c(option = "plasma", name = "Distance\n(miles)") +
  labs(
    title = "Control States",
    x = "Distance (miles)",
    y = "Year"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )


# =============================
# LEFT–RIGHT Layout
# =============================
p_final <- p_treated + p_control +
  plot_layout(ncol = 2)

p_final
