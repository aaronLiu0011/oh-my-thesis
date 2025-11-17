options(tigris_use_cache = TRUE)   # 缓存 shape，提高速度
options(tigris_class = "sf")       # 直接返回 sf 对象

library(tidyverse)
library(sf)
library(tigris)
library(ggpattern)
library(ggplot2)
library(ggnewscale)


DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
OUT_DIR   <- "/Users/okuran/Desktop/thesis/out/choropleth"

if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

panel <- read_csv(DATA_PATH, show_col_types = FALSE)

# 载入美国州界（不包含领地）
states_sf <- states(cb = TRUE) |>           # cb=TRUE 表示 simplified boundaries，图更简洁
  filter(!STUSPS %in% c("AK", "HI", "PR")) |>  # 如果不要阿拉斯加和夏威夷
  transmute(
    fips = GEOID,
    geometry
  )


get_global_range <- function(var) {
  x <- panel |> pull(!!sym(var))
  c(min(x, na.rm = TRUE), max(x, na.rm = TRUE))
}

plot_state_map <- function(year, var, var_label) {
  
  range <- get_global_range(var)   # 全局色阶范围
  
  df <- panel |>
    filter(year == !!year) |>
    transmute(
      fips    = str_pad(fips, 2, pad = "0"),
      value   = !!sym(var),
      treated = treated
    )
  
  dat <- states_sf |>
    left_join(df, by = "fips")
  
  # 色阶：红（Treated）与 蓝（Control）
  red_palette <- c(
    "#FFF5F0","#FEE0D2","#FCBBA1","#FC9272",
    "#FB6A4A","#EF3B2C","#CB181D","#99000D"
  )
  blue_palette <- c(
    "#F0F8FF","#D7EBFF","#ADD6FF","#7FBFFF",
    "#4FA6FF","#1E90FF","#1877CC","#0F4C81"
  )
  
  p <- ggplot() +
    
    ## ---- 1) Control 组：蓝色色阶 ----
  geom_sf(
    data  = dat |> filter(treated == 0),
    aes(fill = value),
    color = "grey30", size = 0.2
  ) +
    scale_fill_gradientn(
      colours  = blue_palette,
      limits   = range,
      na.value = "grey90",
      name     = paste0(var_label, " (Control)")
    ) +
    
    ## 开启第二条 fill 色标
    new_scale_fill() +
    
    ## ---- 2) Treated 组：红色色阶 ----
  geom_sf(
    data  = dat |> filter(treated == 1),
    aes(fill = value),
    color = "grey30", size = 0.2
  ) +
    scale_fill_gradientn(
      colours  = red_palette,
      limits   = range,
      na.value = "grey90",
      name     = paste0(var_label, " (Treated)")
    ) +
    
    coord_sf(
      crs  = 5070,
      xlim = c(-2400000, 2500000),
      ylim = c(150000, 3300000)
    ) +
    
    labs(
      title   = paste0(var_label, " in ", year),
      caption = "Source: CDC, author's calculation"
    ) +
    theme_void() +
    theme(
      plot.title   = element_text(size = 16, face = "bold"),
      plot.caption = element_text(size = 10),
      legend.title = element_text(size = 11),
      legend.text  = element_text(size = 9)
    )
  
  p
}


outcomes <- tribble(
  ~var,             ~label,
  "sy_index",   "Syphilis per 100k",
  "go_index",  "Gonorrhea per 100k",
  "ch_index",  "Chlamydia per 100k",
  "std_index",        "STD Index"
)

years <- c(2021, 2023)

for (yr in years) {
  for (i in 1:nrow(outcomes)) {
    var  <- outcomes$var[i]
    lab  <- outcomes$label[i]
    
    p <- plot_state_map(yr, var, lab)
    
    fname <- paste0(OUT_DIR, "/", var, "_", yr, ".png")
    ggsave(fname, p, width = 10, height = 6, dpi = 300)
  }
}
