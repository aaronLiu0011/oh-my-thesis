library(tidyverse)
library(sf)
library(tigris)
library(ggnewscale)
library(ggpattern)


DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
panel <- read_csv(DATA_PATH, show_col_types = FALSE)
states_sf  # 美国州 shapefile（EPSG 5070）

options(tigris_use_cache = TRUE, tigris_class = "sf")
states_sf <- states(cb = TRUE) |>
  filter(!STUSPS %in% c("AK", "HI", "PR")) |>
  transmute(fips = GEOID, geometry)


get_diff_range <- function(var) {
  d <- panel |> 
    filter(year %in% c(2021, 2023)) |>
    select(fips, year, value = !!sym(var)) |>
    pivot_wider(names_from = year, values_from = value) |>
    mutate(diff = `2023` - `2021`) |>
    pull(diff)
  c(min(d, na.rm = TRUE), max(d, na.rm = TRUE))
}

plot_diff_map <- function(var, var_label) {
  
  if (!(var %in% colnames(panel))) {
    stop(paste("Variable", var, "not found in panel!"))
  }
  
  # ---- 差分 Δ ----
  df <- panel |>
    filter(year %in% c(2021, 2023)) |>
    select(fips, year, treated, value = !!sym(var)) |>
    pivot_wider(names_from = year, values_from = value) |>
    mutate(
      fips    = str_pad(fips, 2, pad = "0"),
      diff    = `2023` - `2021`,
      treated = replace_na(treated, 0)
    ) |>
    select(fips, treated, diff)
  
  dat <- states_sf |> left_join(df, by = "fips")
  
  # ---- 色阶（PuOr 发散） ----
  diff_palette <- c(
    "#542788","#8073AC","#B2ABD2","#D8DAEB",
    "#F7F7F7",
    "#FEE0B6","#FDB863","#E08214","#B35806"
  )
  
  range <- range(dat$diff, na.rm = TRUE)
  
  p <- ggplot() +
    
    # --- Control 图层（无 pattern） ---
    geom_sf(
      data = dat |> filter(treated == 0),
      aes(fill = diff),
      color = "grey40",
      size  = 0.2
    ) +
    
    # --- Treated 图层前：颜色底层 ---
    geom_sf(
      data = dat |> filter(treated == 1),
      aes(fill = diff),
      color = "grey40",   # 粗边框
      size  = 0.2
    ) +
    
    # --- Treated pattern（点阵填充） ---
    geom_sf_pattern(
      data = dat |> filter(treated == 1),
      aes(geometry = geometry),
      pattern = "circle",       # ★ 旧版 ggpattern 支持的点阵
      pattern_fill   = "grey20",
      pattern_colour = NA,
      pattern_alpha  = 0.6,    # 半透明（不遮挡差分色阶）
      pattern_density = 0.3,   # 点的密度
      pattern_spacing = 0.04,   # 间距
      fill = NA,                # ✦ 保留下层颜色
      color = NA
    ) +
    
    
    
    # --- 色阶 ---
    scale_fill_gradientn(
      colours  = diff_palette,
      limits   = range,
      name     = paste0(var_label, "\n(2023 − 2021)"),
      na.value = "grey90"
    ) +
    
    coord_sf(
      crs  = 5070,
      xlim = c(-2400000, 2500000),
      ylim = c(150000, 3300000)
    ) +
    
    labs(
      title   = paste0("Change in ", var_label, " (2023 − 2021)"),
      caption = "Purple = decrease; Orange = increase; dot pattern = Treated states"
    ) +
    
    theme_void() +
    theme(
      plot.title   = element_text(size = 16, face = "bold"),
      plot.caption = element_text(size = 10),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 10)
    )
  
  p
}



OUT_DIR <- "/Users/okuran/Desktop/thesis/out/choropleth/diff_maps"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

outcomes <- tribble(
  ~var,         ~label,
  "sy_index",   "Syphilis Index",
  "go_index",   "Gonorrhea Index",
  "ch_index",   "Chlamydia Index",
  "std_index",  "STD Composite Index"
)

for (i in 1:nrow(outcomes)) {
  var <- outcomes$var[i]
  lab <- outcomes$label[i]
  
  p <- plot_diff_map(var, lab)
  ggsave(
    paste0(OUT_DIR, "/", var, "_diff.png"),
    p, width = 10, height = 6, dpi = 300
  )
}
