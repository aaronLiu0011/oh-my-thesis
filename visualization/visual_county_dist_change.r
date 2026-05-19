# ============================================
# County-level Distance Change Map (2023-2021)
# ============================================
options(tigris_use_cache = TRUE)
options(tigris_class = "sf")

library(tidyverse)
library(sf)
library(tigris)
library(ggplot2)
library(viridis)

# -------------------------------------------------
# 1. Load distance data
# -------------------------------------------------
distance_df <- read_csv(
  "/Users/okuran/Desktop/thesis/master_data/2023-2021_abortionaccess_countyxmonth.csv",
  show_col_types = FALSE
)

# Calculate 2021 and 2023 annual averages by county
distance_change <- distance_df %>%
  filter(year %in% c(2021, 2023)) %>%
  group_by(origin_fips_code, year) %>%
  summarise(
    avg_distance = mean(distance_origintodest, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = year,
    values_from = avg_distance,
    names_prefix = "dist_"
  ) %>%
  mutate(
    distance_change = dist_2023 - dist_2021,
    fips = str_pad(origin_fips_code, 5, pad = "0")
  )

# -------------------------------------------------
# 2. Load county shapefile
# -------------------------------------------------
counties_sf <- counties(cb = TRUE, year = 2021) %>%
  select(GEOID, geometry) %>%
  rename(fips = GEOID)

# Remove AK & HI
mainland_counties <- counties_sf %>%
  filter(!str_starts(fips, "02|15"))

# -------------------------------------------------
# 3. Merge distance change data
# -------------------------------------------------
county_map <- mainland_counties %>%
  left_join(distance_change, by = "fips") 

# -------------------------------------------------
# 4. Load state borders
# -------------------------------------------------
states_sf <- states(cb = TRUE, year = 2021) %>%
  filter(!GEOID %in% c("02", "15", "72")) %>%  # Remove AK, HI, PR
  select(GEOID, geometry) %>%
  rename(state_fips = GEOID)

# Define treated states (13 states with 2022 bans)
treated_states <- c("16", "46", "29", "21", "54", "40", "05", 
                    "47", "13", "01", "28", "22", "48")

# Separate treated and control state borders
treated_states_sf <- states_sf %>%
  filter(state_fips %in% treated_states)

control_states_sf <- states_sf %>%
  filter(!state_fips %in% treated_states)

# -------------------------------------------------
# 5. Define color breaks
# -------------------------------------------------
# Create bins for distance change
county_map <- county_map %>%
  mutate(
    change_category = case_when(
      distance_change < 0 ~ "Decrease",
      distance_change >= 0 & distance_change < 10 ~ "0-10 miles",
      distance_change >= 10 & distance_change < 50 ~ "10-50 miles",
      distance_change >= 50 & distance_change < 100 ~ "50-100 miles",
      distance_change >= 100 & distance_change < 200 ~ "100-200 miles",
      distance_change >= 200 ~ "200+ miles"
    ),
    change_category = factor(
      change_category,
      levels = c("Decrease", "0-10 miles", "10-50 miles", 
                 "50-100 miles", "100-200 miles", "200+ miles")
    )
  )

# Color palette - using blue-purple gradient (avoids red/white)
distance_colors <- c(
  "Decrease"    = "#59AC77",
  "0-10 miles"  = "grey70",   # Neutral
  "10-50 miles" = "#D4BEE4",
  "50-100 miles"= "#9B7EBD",
  "100-200 miles" = "#5D2F77",
  "200+ miles"="#3B1E54"
)

# -------------------------------------------------
# 6. Create map
# -------------------------------------------------
p_distance <- ggplot() +
  # County fills
  geom_sf(
    data = county_map |> filter(!is.na(change_category)),
    aes(fill = change_category),
    color = NA
  ) +
  # Control state borders (white)
  geom_sf(
    data = control_states_sf,
    fill = NA,
    color = "white",
    size = 0.4
  ) +
  geom_sf(
    data = treated_states_sf,
    fill = NA,
    color = "#d62728",
    linewidth = 0.8
  ) +
  scale_fill_manual(
    values = distance_colors,
    name = "Change in Distance\n(2023 - 2021)",
    drop = TRUE
  ) +
  coord_sf(
    crs = 5070,
    xlim = c(-2400000, 2500000),
    ylim = c(150000, 3300000),
    expand = FALSE
  ) +
  theme_void(base_size = 15) +
  theme(
    legend.position = "right",
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )
# -------------------------------------------------
# 7. Save
# -------------------------------------------------
ggsave(
  "/Users/okuran/Desktop/thesis/out/county_distance_change_2023_2021.png",
  p_distance, 
  width = 11, height = 7, dpi = 300,
  bg = "white"
)

# -------------------------------------------------
# 8. Summary statistics
# -------------------------------------------------
summary_stats <- county_map %>%
  st_drop_geometry() %>%
  filter(!is.na(distance_change)) %>%
  summarise(
    mean_change = mean(distance_change, na.rm = TRUE),
    median_change = median(distance_change, na.rm = TRUE),
    max_change = max(distance_change, na.rm = TRUE),
    min_change = min(distance_change, na.rm = TRUE),
    counties_with_increase = sum(distance_change > 0, na.rm = TRUE),
    counties_with_large_increase = sum(distance_change > 100, na.rm = TRUE)
  )

print(summary_stats)