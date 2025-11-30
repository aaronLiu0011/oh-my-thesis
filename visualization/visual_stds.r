#================================
# Bar Plot: STD Trends (2010-2023)
#================================

library(ggplot2)
library(tidyr)

DATA_PATH <- "/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv"
panel <- read_csv(DATA_PATH, show_col_types = FALSE)
  
std_trends <- panel %>%
  group_by(year) %>%
  summarise(
    Syphilis = mean(sy_index, na.rm = TRUE),
    Gonorrhea = mean(go_index, na.rm = TRUE),
    Chlamydia = mean(ch_index, na.rm = TRUE),
    Total_STD = Syphilis + Gonorrhea + Chlamydia,   # ★ 新增
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = c(Syphilis, Gonorrhea, Chlamydia),
    names_to = "Disease",
    values_to = "Rate"
  )

p1 <- ggplot(std_trends, aes(x = factor(year))) +
  
  # -----------------------
# ★ 1. 柱状图（三疾病）
# -----------------------
geom_bar(
  aes(y = Rate, fill = Disease),
  stat = "identity",
  position = "dodge",
  width = 0.7
) +
  
  scale_fill_manual(values = c(
    "Syphilis"  = "grey20",
    "Gonorrhea" = "grey50",
    "Chlamydia" = "grey70"
  )) +
  
  
  # -----------------------
# ★ 2. 折线图：三疾病总量 Total_STD
# -----------------------
geom_line(
  data = std_trends |> distinct(year, Total_STD),
  aes(y = Total_STD, group = 1),
  color = "black",
  linewidth = 1
) +
  geom_point(
    data = std_trends |> distinct(year, Total_STD),
    aes(y = Total_STD),
    color = "black",
    size = 2
  ) +
  
  
  # -----------------------
# ★ 3. 双轴设定
#     左轴：柱子（三疾病）
#     右轴：折线（Total_STD）
# -----------------------
scale_y_continuous(
  name = "Rate per 100,000 (individual diseases)", 
  sec.axis = sec_axis(
    trans = ~ .,                                  
    name = "Total STD Index (Combined)"           
  )
) +
  
  
  # -----------------------
# 4. 主题和标题
# -----------------------
labs(
  title = "STD Trends in the United States (2010–2023)",
  subtitle = "Bar: individual STDs | Line: combined STD index",
  x = "Year",
  fill = "Disease"
) +
  
  theme_minimal() +
  theme(
    plot.title      = element_text(size = 14, face = "bold"),
    plot.subtitle   = element_text(size = 11),
    axis.text.x     = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.background   = element_rect(fill = "white", color = NA),
    plot.background    = element_rect(fill = "white", color = NA)
  )

ggsave(
  "/Users/okuran/Desktop/thesis/out/std_trends_barplot.png",
  p1, width = 10, height = 6, dpi = 300, bg = "white"
)
