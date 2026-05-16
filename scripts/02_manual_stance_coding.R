# 02_manual_stance_coding.R
# Manual stance visualisations for the Clara Raphael project
# Based on the original draft code, but with data import, light cleaning and file export added.

library(readr)
library(dplyr)
library(stringr)
library(ggplot2)

# -----------------------------
# Settings
# -----------------------------

input_file <- "data/corpus_metadata.csv"
output_dir <- "figures/02_manual_stance_coding"

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Set to TRUE if the final report should only use high-relevance items.
# Set to FALSE to reproduce Erik's original logic more closely, using all coded items.
use_high_relevance_only <- FALSE

# -----------------------------
# Load and prepare data
# -----------------------------

data <- read_csv(input_file, show_col_types = FALSE) %>%
  mutate(
    manual_stance = str_to_lower(str_trim(manual_stance)),
    relevance = str_to_lower(str_trim(relevance)),
    newspaper = str_squish(newspaper)
  ) %>%
  filter(!is.na(manual_stance), manual_stance != "")

if (use_high_relevance_only) {
  data <- data %>% filter(relevance == "high")
}

# Keep stance categories in a stable order if they exist in the data
stance_order <- c("critical", "ambivalent", "supportive", "descriptive", "unclear")

data <- data %>%
  mutate(
    manual_stance = factor(manual_stance, levels = stance_order)
  )

# -----------------------------
# 1. Donut chart
# -----------------------------

category_counts <- data %>%
  count(manual_stance, .drop = FALSE) %>%
  filter(!is.na(manual_stance), n > 0) %>%
  mutate(
    percentage = n / sum(n) * 100,
    label = paste0(round(percentage), "%")
  )

donut_plot <- ggplot(
  category_counts,
  aes(x = 2, y = percentage, fill = manual_stance)
) +
  geom_col(color = "white") +
  coord_polar(theta = "y") +
  xlim(0.5, 2.5) +
  geom_text(
    aes(label = label),
    position = position_stack(vjust = 0.5),
    size = 4
  ) +
  labs(
    title = "Percentage Distribution of Article Categories",
    fill = "Category"
  ) +
  theme_void() +
  theme(
    text = element_text(size = 12),
    plot.title = element_text(hjust = 0.5)
  )

donut_plot

ggsave(
  filename = file.path(output_dir, "manual_stance_donut.png"),
  plot = donut_plot,
  width = 7,
  height = 5,
  dpi = 300
)

# -----------------------------
# 2. Newspapers and reception
# -----------------------------

newspaper_plot <- ggplot(
  data,
  aes(x = newspaper, fill = manual_stance)
) +
  geom_bar() +
  labs(
    title = "Newspapers and Reception of Clara Raphael",
    x = "Newspaper",
    y = "Number of Articles",
    fill = "Manual stance"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8)
  ) +
  scale_y_continuous(breaks = seq(0, max(table(data$newspaper)) + 1, by = 1))

newspaper_plot

ggsave(
  filename = file.path(output_dir, "manual_stance_by_newspaper.png"),
  plot = newspaper_plot,
  width = 10,
  height = 5.5,
  dpi = 300
)

# -----------------------------
# Save table used for figures
# -----------------------------

write_csv(
  category_counts,
  file.path(output_dir, "manual_stance_counts.csv")
)
