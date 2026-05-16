# 03_keyword_analysis.R
# Keyword and semantic field visualisations for the Clara Raphael project
# Based on the original draft code, but with data import, case-insensitive matching,
# safer regex patterns, word boundaries, normalisation and file export added.

library(readr)
library(dplyr)
library(stringr)
library(ggplot2)
library(tidyr)

# -----------------------------
# Settings
# -----------------------------

input_file <- "data/corpus_metadata.csv"
output_dir <- "figures/03_keyword_analysis"

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Set to TRUE if keyword analysis should only use high-relevance items.
# Set to FALSE to stay closer to Erik's original corpus-wide keyword figures.
use_high_relevance_only <- FALSE

# -----------------------------
# Load and prepare data
# -----------------------------

data <- read_csv(input_file, show_col_types = FALSE) %>%
  mutate(
    manual_stance = str_to_lower(str_trim(manual_stance)),
    relevance = str_to_lower(str_trim(relevance)),
    article_text_clean = coalesce(article_text_clean, ""),
    article_text_clean_lower = str_to_lower(article_text_clean),
    word_count = str_count(article_text_clean_lower, boundary("word"))
  ) %>%
  filter(article_text_clean_lower != "")

if (use_high_relevance_only) {
  data <- data %>% filter(relevance == "high")
}

# -----------------------------
# 1. Keyword frequency in the corpus
# -----------------------------

all_text <- paste(data$article_text_clean_lower, collapse = " ")
total_words <- sum(data$word_count, na.rm = TRUE)

keywords <- c(
  "Qvinde/Kvinde" = "\\b(qvinde\\w*|kvinde\\w*)\\b",
  "Emancipation" = "\\bemancipation\\w*\\b",
  "Frihed" = "\\bfrihed\\w*\\b",
  "Ægteskab" = "\\bægteskab\\w*\\b",
  "Christ/Krist/Gud/Religion" = "\\b(christ\\w*|krist\\w*|gud\\w*|religion\\w*)\\b",
  "Moder/Hustru" = "\\b(moder\\w*|hustru\\w*)\\b",
  "Kritik/Critique" = "\\b(kritik\\w*|critique\\w*)\\b",
  "Idee/Idé" = "\\b(idee\\w*|idé\\w*)\\b"
)

keyword_df <- tibble(
  keyword = names(keywords),
  pattern = keywords
) %>%
  rowwise() %>%
  mutate(
    count = str_count(all_text, regex(pattern)),
    per_1000_words = count / total_words * 1000
  ) %>%
  ungroup()

keyword_plot <- ggplot(
  keyword_df,
  aes(x = reorder(keyword, count), y = count)
) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Keyword Frequency in the Clara Raphael Corpus",
    x = "Keyword",
    y = "Frequency"
  ) +
  theme_minimal()

keyword_plot

ggsave(
  filename = file.path(output_dir, "keyword_frequency_raw_counts.png"),
  plot = keyword_plot,
  width = 8,
  height = 5,
  dpi = 300
)

# Optional normalised version, useful if comparing with semantic fields
keyword_plot_per_1000 <- ggplot(
  keyword_df,
  aes(x = reorder(keyword, per_1000_words), y = per_1000_words)
) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Keyword Frequency in the Clara Raphael Corpus",
    subtitle = "Hits per 1,000 words",
    x = "Keyword",
    y = "Hits per 1,000 words"
  ) +
  theme_minimal()

keyword_plot_per_1000

ggsave(
  filename = file.path(output_dir, "keyword_frequency_per_1000_words.png"),
  plot = keyword_plot_per_1000,
  width = 8,
  height = 5,
  dpi = 300
)

write_csv(
  keyword_df,
  file.path(output_dir, "keyword_frequency_table.csv")
)

# -----------------------------
# 2. Semantic fields by article stance
# -----------------------------

semantic_fields <- c(
  "Gender" = "\\b(qvinde\\w*|kvinde\\w*|fruentimmer\\w*|pige\\w*|dame\\w*|skjøge\\w*)\\b",
  "Emancipation" = "\\b(emancipation\\w*|emancipere\\w*|frigørelse\\w*|frihed\\w*)\\b",
  "Marriage_Family" = "\\b(ægteskab\\w*|mand\\w*|hustru\\w*|moder\\w*|familie\\w*|hjem\\w*)\\b",
  "Religion_Morality" = "\\b(gud\\w*|christ\\w*|krist\\w*|religion\\w*|tro\\w*|synd\\w*|pligt\\w*|daab\\w*|nadver\\w*)\\b",
  "Education_Development" = "\\b(dannelse\\w*|opdragelse\\w*|udvikling\\w*|skole\\w*|lære\\w*)\\b",
  "Authorship_Literature" = "\\b(roman\\w*|bog\\w*|forfatterinde\\w*|forfatter\\w*|talent\\w*|stil\\w*|digtning\\w*)\\b",
  "Nation_Politics" = "\\b(fædreland\\w*|dansk\\w*|tydsk\\w*|krig\\w*|folk\\w*|frihed\\w*|demokrati\\w*)\\b",
  "Ideas_Abstraction" = "\\b(idee\\w*|idé\\w*|sag\\w*|aand\\w*|princip\\w*|ret\\w*)\\b"
)

stance_texts <- data %>%
  filter(!is.na(manual_stance), manual_stance != "") %>%
  group_by(manual_stance) %>%
  summarise(
    text = paste(article_text_clean_lower, collapse = " "),
    total_words = sum(word_count, na.rm = TRUE),
    .groups = "drop"
  )

semantic_results <- crossing(
  stance_texts,
  tibble(
    semantic_field = names(semantic_fields),
    pattern = semantic_fields
  )
) %>%
  rowwise() %>%
  mutate(
    count = str_count(text, regex(pattern)),
    per_1000_words = count / total_words * 1000
  ) %>%
  ungroup()

# Raw-count version: closest to Erik's original figure
semantic_plot_raw <- ggplot(
  semantic_results,
  aes(x = semantic_field, y = count, fill = manual_stance)
) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(
    title = "Semantic Fields by Article Stance",
    x = "Semantic Field",
    y = "Frequency",
    fill = "Article Stance"
  ) +
  theme_minimal() +
  theme(
    text = element_text(size = 12)
  )

semantic_plot_raw

ggsave(
  filename = file.path(output_dir, "semantic_fields_by_article_stance_raw_counts.png"),
  plot = semantic_plot_raw,
  width = 9,
  height = 5.5,
  dpi = 300
)

# Normalised version: better for comparing stance groups
semantic_plot_per_1000 <- ggplot(
  semantic_results,
  aes(x = semantic_field, y = per_1000_words, fill = manual_stance)
) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(
    title = "Semantic Fields by Article Stance",
    subtitle = "Hits per 1,000 words",
    x = "Semantic Field",
    y = "Hits per 1,000 words",
    fill = "Article Stance"
  ) +
  theme_minimal() +
  theme(
    text = element_text(size = 12)
  )

semantic_plot_per_1000

ggsave(
  filename = file.path(output_dir, "semantic_fields_by_article_stance_per_1000_words.png"),
  plot = semantic_plot_per_1000,
  width = 9,
  height = 5.5,
  dpi = 300
)

write_csv(
  semantic_results,
  file.path(output_dir, "semantic_fields_by_article_stance_table.csv")
)
