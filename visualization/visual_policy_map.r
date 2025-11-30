# ============================================
# Visualization: policy map
# ============================================
library(tidyverse)
library(sf)
library(ggplot2)
library(ggpattern)



policy_df <- read_csv("/Users/okuran/Desktop/thesis/master_data/abortion_policies.csv",
                      show_col_types = FALSE) %>%
  mutate(
    fips = as.character(state_fips),
    fips = str_pad(fips, 2, pad = "0")  
  )

# -------------------------------------------------
# 2. 合并 states_sf
# -------------------------------------------------
states_sf <- states_sf %>%
  mutate(
    fips = as.character(fips),
    fips = str_pad(fips, 2, pad = "0")
  ) %>%
  filter(!fips %in% c("02","15","72"))

map_df <- states_sf %>%
  left_join(policy_df, by = "fips")
# -------------------------------------------------
# 3. KFF colors
# -------------------------------------------------
kff_colors <- c(
  "4" = "#D62728",
  "3" = "#FF7F0E",
  "2" = "#add8e6", 
  "1" = "#1f77b4",
  "0" = "#144c73"
)

map_df$policy_intensity <- factor(as.character(map_df$policy_intensity),
                                  levels = c(4,3,2,1,0))

map_df$policy_intensity[is.na(map_df$policy_intensity)] <- "0"


# -------------------------------------------------
# 4. Plot: correct order = (1) base layer → (2) pattern layer
# -------------------------------------------------
p <- ggplot() +
  geom_sf(
    data = map_df,
    aes(fill = policy_intensity),
    color = "white",
    size = 0.3) +
  
  geom_sf_pattern(
    data = map_df |> filter(treated_year == 2022),
    aes(geometry = geometry),
    pattern          = "pch",
    pattern_shape    = 20,      # small round dot ●
    pattern_fill     = "black",
    pattern_colour   = "black",
    pattern_alpha    = 0.50,
    pattern_density  = 0.35,
    pattern_spacing  = 0.035,
    fill             = NA,      # ★ keep base color visible
    color            = NA) +
  
  scale_fill_manual(
    values = kff_colors,
    name   = "Policy Intensity",
    labels = c(
      "4" = "Total ban",
      "3" = "Limit 6–12 weeks",
      "2" = "Limit 18–22 weeks",
      "1" = "Limit at viability",
      "0" = "No limit"
    )) +
  
  scale_pattern_manual(values = c("pch" = "pch"), guide = "none") +
  
  coord_sf(
    crs  = 5070,
    xlim = c(-2400000, 2500000),
    ylim = c(150000, 3300000),
    expand = FALSE
  ) +
  
  theme_void(base_size = 15) +
  theme(
    legend.position = "right",
    legend.title    = element_text(size = 14),
    legend.text     = element_text(size = 12)
  )

# -------------------------------------------------
# 5. Export
# -------------------------------------------------
ggsave(
  "/Users/okuran/Desktop/thesis/out/choropleth/policy_map_intensity_pattern.png",
  p, width = 10, height = 6, dpi = 300
)