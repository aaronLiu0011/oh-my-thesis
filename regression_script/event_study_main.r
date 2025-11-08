library(tidyverse)
library(fixest)
library(ggplot2)
library(broom)
library(data.table)
library(dplyr)
library(stringr)

panel_data <- read_csv("/Users/okuran/Desktop/thesis/master_data/state_panel_2010_2023.csv")

run_event_study <- function(dep_var, title_text) {
  
  formula <- as.formula(
    paste0(
      dep_var, 
      " ~ i(event_time, treated, ref = -1) + ",
      "share_age_15_44 + share_male + share_black + log(income) + unrate + poverty_rate + ",
      "share_married_15p + share_hs_plus_25p + share_ba_plus_25p + titlex_rate | fips + year"
    )
  )
  
  model <- feols(
    formula,
    data = panel_data,
    cluster = ~fips
  )
  
  coefs <- coef(model)
  ses <- se(model)
  event_vars <- grep("event_time::", names(coefs), value = TRUE)
  times <- as.numeric(gsub(".*event_time::(-?[0-9]+).*", "\\1", event_vars))
  
  plot_data <- tibble(
    time = c(times, -1),
    estimate = c(coefs[event_vars], 0),
    se = c(ses[event_vars], 0)
  ) %>%
    mutate(
      ci_lower = estimate - 1.96 * se,
      ci_upper = estimate + 1.96 * se
    ) %>%
    arrange(time)
  
  p <- ggplot(plot_data, aes(x = time, y = estimate)) +
    geom_hline(yintercept = 0, size = 0.7,linetype = "solid", color = "grey") +
    geom_vline(xintercept = -1, size = 0.7, linetype = "solid", color = "grey") +
    geom_line(aes(y = ci_upper), linetype = "dashed", color = "black") +
    geom_line(aes(y = ci_lower), linetype = "dashed", color = "black") +
    geom_line(size = 1, color = "black") +
    scale_x_continuous(breaks = seq(min(plot_data$time), max(plot_data$time), by = 1)) +
    labs(title = paste0("Event Study: Effect of Abortion Ban on ", title_text),
      x = "Periods relative to treatment",
      y = "Coefficient"
    ) +
    theme_classic(base_size = 14) +
    theme(
      axis.line = element_line(color = "grey"),
      plot.title = element_text(
        size = 13, 
        face = "bold", 
        hjust = 0.5,     # 居中
        margin = margin(b = 10)
      ),
      axis.title.x = element_text(margin = margin(t = 10)),
      axis.title.y = element_text(margin = margin(r = 10))
    )
  
  ggsave(filename = paste0("/Users/okuran/Desktop/thesis/out/event_study_plot_", title_text, ".png"),
         plot = p,
         width = 6, height = 4, dpi = 300)
  
  print(p)
  

  pre_coefs <- grep("event_time::-[2-9]", names(coef(model)), value = TRUE)
  test <- wald(model, pre_coefs)
  
  cat("\n=== Parallel Trend Test: ", dep_var, " ===\n", sep = "")
  cat("F Statistic:", test$stat, "\n")
  cat("P Value:", test$p, "\n")
  if(test$p > 0.05) {
    cat("Conclusion: The parallel trend assumption cannot be rejected ✓\n")
  } else {
    cat("Conclusion: Potential violation of the parallel trend assumption ✗\n")
  }
}

run_event_study("sy_index", "Syphilis")
run_event_study("go_index", "Gonorrhea")
run_event_study("ch_index", "Chlamydia")
run_event_study("std_index", "STDs")

