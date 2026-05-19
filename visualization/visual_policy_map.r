# ============================================
# USA mainland policy map
# ============================================
options(tigris_use_cache = TRUE)
options(tigris_class = "sf")

library(tidyverse)
library(sf)
library(tigris)
library(ggpattern)
library(ggplot2)
library(ggrepel)

# -------------------------------------------------
# 1. Load policy data
# -------------------------------------------------
policy_df <- read_csv(
  "/Users/okuran/Desktop/thesis/master_data/abortion_policies.csv",
  show_col_types = FALSE
) %>%
  mutate(
    fips = str_pad(as.character(state_fips), 2, pad = "0")
  )

# -------------------------------------------------
# 2. Load states shapefile + abbreviations
# -------------------------------------------------
states_sf <- states(cb = TRUE) |>
  select(GEOID, geometry) |>
  rename(fips = GEOID)

state_info <- tribble(
  ~fips, ~name,            ~abbr,
  "01","Alabama","AL","02","Alaska","AK","04","Arizona","AZ","05","Arkansas","AR",
  "06","California","CA","08","Colorado","CO","09","Connecticut","CT","10","Delaware","DE",
  "11","District of Columbia","DC","12","Florida","FL","13","Georgia","GA","15","Hawaii","HI",
  "16","Idaho","ID","17","Illinois","IL","18","Indiana","IN","19","Iowa","IA",
  "20","Kansas","KS","21","Kentucky","KY","22","Louisiana","LA","23","Maine","ME",
  "24","Maryland","MD","25","Massachusetts","MA","26","Michigan","MI","27","Minnesota","MN",
  "28","Mississippi","MS","29","Missouri","MO","30","Montana","MT","31","Nebraska","NE",
  "32","Nevada","NV","33","New Hampshire","NH","34","New Jersey","NJ","35","New Mexico","NM",
  "36","New York","NY","37","North Carolina","NC","38","North Dakota","ND","39","Ohio","OH",
  "40","Oklahoma","OK","41","Oregon","OR","42","Pennsylvania","PA","44","Rhode Island","RI",
  "45","South Carolina","SC","46","South Dakota","SD","47","Tennessee","TN","48","Texas","TX",
  "49","Utah","UT","50","Vermont","VT","51","Virginia","VA","53","Washington","WA",
  "54","West Virginia","WV","55","Wisconsin","WI","56","Wyoming","WY"
)

states_sf <- states_sf %>%
  mutate(fips = str_pad(fips, 2, pad = "0")) %>%
  left_join(state_info, by = "fips")

# Remove AK & HI
mainland_sf <- states_sf %>% filter(!fips %in% c("02","15"))

# -------------------------------------------------
# 3. Merge policy data
# -------------------------------------------------
mainland_map <- mainland_sf %>%
  left_join(policy_df, by = "fips")

# Replace NA → 0
mainland_map$policy_intensity[is.na(mainland_map$policy_intensity)] <- "0"

# -------------------------------------------------
# 4. Colors
# -------------------------------------------------
kff_colors <- c(
  "4" = "#740938",      # Purple - Total ban
  "3" = "#FF7F0E",      # Orange - Limit 6-12 weeks
  "2" = "#fddbc7",      # Light orange/peach - Limit 18-22 weeks
  "1" = "#1f77b4",      # Medium blue - Limit at viability
  "0" = "#144c73"       # Dark blue - No limit
)

# -------------------------
# Separate small vs large states
# -------------------------
small_states <- c("CT","RI","MA","NJ","DE","MD","DC")

mainland_map <- mainland_map %>%
  mutate(center = st_point_on_surface(geometry))

df_small <- mainland_map %>% filter(abbr %in% small_states)
df_large <- mainland_map %>% filter(!abbr %in% small_states)

# ============================
# 5. Plot Mainland Only
# ============================

p_main <- ggplot() +
  geom_sf(
    data = mainland_map,
    aes(fill = factor(policy_intensity, levels = c("4","3","2","1","0"))),
    color = "white", size = 0.3
  ) +
  geom_sf(
    data = mainland_map |> filter(treated_year == 2022),
    aes(geometry = geometry),
    fill = NA,
    color = "red",
    linewidth = 0.8
  ) +
  geom_sf_label(
    data = df_large,
    aes(label = abbr),
    size = 3.1,
    label.size = 0,
    fill = alpha("white", 0.75)
  ) +
  # Small states: repelled labels
  geom_label_repel(
    data = df_small,
    aes(label = abbr, geometry = center),
    stat = "sf_coordinates",
    size = 3.1,
    label.size = 0,
    fill = alpha("white", 0.75),
    max.overlaps = Inf,
    force = 1,
    min.segment.length = 0,
    seed = 2025
  ) +
  scale_fill_manual(
    values = kff_colors,
    name   = "Policy Intensity",
    labels = c(
      "4" = "Total ban",
      "3" = "Limit 6–12 weeks",
      "2" = "Limit 18–22 weeks",
      "1" = "Limit at viability",
      "0" = "No limit"
    )
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
    legend.text  = element_text(size = 12)
  )

# ============================
# 6. Save
# ============================
ggsave(
  "/Users/okuran/Desktop/thesis/out/choropleth/policy_map_mainland.png",
  p_main, width = 11, height = 7, dpi = 300
)
