# 04_sentida_analysis.R
# Group 16 - Clara Raphael reception project
#
# Purpose:
# Run Sentida on the OCR-corrected text subset,
# add Sentida scores to corpus metadata,
# and inspect how Sentida compares with manual stance coding.

library(tidyverse)
library(tidytext)
library(Sentida)

# ------------------------------------------------------------
# 1. Load data and create output folders
# ------------------------------------------------------------

corpus <- read_csv("data/corpus_metadata.csv", show_col_types = FALSE)

dir.create("figures/04_sentida_analysis", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

# Colour palettes
stance_colours <- c(
  "critical" = "#D55E00",
  "ambivalent" = "#E69F00",
  "supportive" = "#009E73",
  "descriptive" = "#999999",
  "unclear" = "#666666"
)

sentiment_colours <- c(
  "positive" = "#009E73",
  "negative" = "#D55E00"
)

subset_colours <- c(
  "core" = "#0072B2",
  "expanded" = "#56B4E9",
  "expanded_uncertain" = "#999999"
)

# ------------------------------------------------------------
# 2. Prepare the Sentida subset
# ------------------------------------------------------------

sentida_data <- corpus %>%
  select(
    id,
    title,
    newspaper,
    date_iso,
    manual_stance,
    sentida_subset,
    article_text_clean
  ) %>%
  mutate(
    sentida_subset = str_to_lower(str_squish(sentida_subset)),
    manual_stance = str_to_lower(str_squish(manual_stance)),
    article_text_clean = str_squish(article_text_clean),
    word_count = str_count(article_text_clean, "\\S+"),
    manual_stance = factor(
      manual_stance,
      levels = c("critical", "ambivalent", "supportive", "descriptive", "unclear")
    )
  ) %>%
  filter(
    sentida_subset %in% c("core", "expanded", "expanded_uncertain"),
    !is.na(article_text_clean),
    article_text_clean != ""
  )

# Quick checks
sentida_data %>%
  count(sentida_subset)

sentida_data %>%
  count(manual_stance)

# ------------------------------------------------------------
# 3. Run Sentida on each article
# ------------------------------------------------------------

# We use output = "mean" because the texts have different lengths.
# Stopwords are not removed before Sentida, because this could affect negation.

sentida_results <- sentida_data %>%
  rowwise() %>%
  mutate(
    sentida_score = sentida(article_text_clean, output = "mean")
  ) %>%
  ungroup()

sentida_results_compact <- sentida_results %>%
  select(
    id,
    title,
    newspaper,
    date_iso,
    manual_stance,
    sentida_subset,
    word_count,
    sentida_score
  )

write_csv(sentida_results_compact, "outputs/sentida_results.csv")

# Add Sentida scores back into metadata
# We save a new file and do not overwrite the original corpus_metadata.csv.

corpus_with_sentida <- corpus %>%
  left_join(
    sentida_results_compact %>%
      select(id, sentida_score, word_count),
    by = "id"
  )

write_csv(
  corpus_with_sentida,
  "data/corpus_metadata_with_sentida.csv"
)

# ------------------------------------------------------------
# 4. Summary tables
# ------------------------------------------------------------

sentida_summary_by_stance <- sentida_results_compact %>%
  group_by(manual_stance) %>%
  summarise(
    n = n(),
    mean_score = mean(sentida_score, na.rm = TRUE),
    median_score = median(sentida_score, na.rm = TRUE),
    min_score = min(sentida_score, na.rm = TRUE),
    max_score = max(sentida_score, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(
  sentida_summary_by_stance,
  "outputs/sentida_summary_by_stance.csv"
)

sentida_summary_by_subset <- sentida_results_compact %>%
  group_by(sentida_subset) %>%
  summarise(
    n = n(),
    mean_score = mean(sentida_score, na.rm = TRUE),
    median_score = median(sentida_score, na.rm = TRUE),
    min_score = min(sentida_score, na.rm = TRUE),
    max_score = max(sentida_score, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(
  sentida_summary_by_subset,
  "outputs/sentida_summary_by_subset.csv"
)

sentida_summary_by_stance
sentida_summary_by_subset

# ------------------------------------------------------------
# 5. Figure 1: Article scores by manual stance
# ------------------------------------------------------------

# This figure shows the main comparison:
# Does Sentida score critical, ambivalent and supportive texts differently?

stance_point_plot <- ggplot(
  sentida_results_compact,
  aes(x = manual_stance, y = sentida_score, colour = manual_stance)
) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
  geom_jitter(width = 0.12, size = 2.6, alpha = 0.8) +
  stat_summary(
    fun = mean,
    geom = "crossbar",
    width = 0.45,
    colour = "black"
  ) +
  scale_colour_manual(values = stance_colours, drop = FALSE) +
  labs(
    title = "Sentida scores compared with manual stance",
    subtitle = "Points show individual articles; black bars show category means",
    x = "Manual stance",
    y = "Sentida mean score",
    colour = "Manual stance"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/04_sentida_analysis/fig01_sentida_scores_by_manual_stance.png",
  plot = stance_point_plot,
  width = 8,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 6. Figure 2: Article-level Sentida scores
# ------------------------------------------------------------

# This figure is useful for choosing cases for closer discussion.

article_plot <- sentida_results_compact %>%
  mutate(
    article_label = paste(id, newspaper, sep = " - "),
    article_label = fct_reorder(article_label, sentida_score)
  ) %>%
  ggplot(aes(x = sentida_score, y = article_label, fill = manual_stance)) +
  geom_col() +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
  scale_fill_manual(values = stance_colours, drop = FALSE) +
  labs(
    title = "Sentida score by article",
    subtitle = "Articles are ordered by Sentida score and coloured by manual stance",
    x = "Sentida mean score",
    y = "Article",
    fill = "Manual stance"
  ) +
  theme_minimal(base_size = 11)

ggsave(
  "figures/04_sentida_analysis/fig02_sentida_score_by_article.png",
  plot = article_plot,
  width = 8,
  height = 7,
  dpi = 300
)

# ------------------------------------------------------------
# 7. Word-level inspection
# ------------------------------------------------------------

# This does not replace the article-level Sentida scores.
# It helps us inspect which words Sentida treats as positive or negative.

tokens <- sentida_results %>%
  select(id, manual_stance, sentida_subset, article_text_clean) %>%
  unnest_tokens(word, article_text_clean) %>%
  filter(str_length(word) > 2)

# Score each unique word once
word_scores <- tokens %>%
  distinct(word) %>%
  rowwise() %>%
  mutate(
    word_sentida_score = sentida(word, output = "mean")
  ) %>%
  ungroup()

sentida_words <- tokens %>%
  left_join(word_scores, by = "word") %>%
  filter(
    !is.na(word_sentida_score),
    word_sentida_score != 0
  ) %>%
  mutate(
    sentiment_category = if_else(word_sentida_score > 0, "positive", "negative")
  )

write_csv(sentida_words, "outputs/sentida_words_all_tokens.csv")

# ------------------------------------------------------------
# 8. Figure 3: Positive and negative Sentida-coded words by stance
# ------------------------------------------------------------

word_counts_by_stance <- sentida_words %>%
  count(manual_stance, sentiment_category) %>%
  group_by(manual_stance) %>%
  mutate(
    share = n / sum(n)
  ) %>%
  ungroup()

write_csv(
  word_counts_by_stance,
  "outputs/sentida_word_counts_by_stance.csv"
)

word_category_plot <- ggplot(
  word_counts_by_stance,
  aes(x = manual_stance, y = share, fill = sentiment_category)
) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_fill_manual(values = sentiment_colours) +
  labs(
    title = "Positive and negative Sentida-coded words by manual stance",
    subtitle = "Shares are calculated within each manual stance category",
    x = "Manual stance",
    y = "Share of Sentida-coded words",
    fill = "Sentida word category"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/04_sentida_analysis/fig03_sentida_word_categories_by_stance.png",
  plot = word_category_plot,
  width = 8,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 9. Figure 4: Top words contributing to positive and negative scores
# ------------------------------------------------------------

top_sentida_words <- sentida_words %>%
  count(word, sentiment_category, word_sentida_score, sort = TRUE) %>%
  mutate(
    contribution = n * word_sentida_score
  ) %>%
  group_by(sentiment_category) %>%
  slice_max(order_by = abs(contribution), n = 12, with_ties = FALSE) %>%
  ungroup()

write_csv(
  top_sentida_words,
  "outputs/top_sentida_words.csv"
)

top_word_plot <- top_sentida_words %>%
  mutate(word = fct_reorder(word, contribution)) %>%
  ggplot(aes(x = contribution, y = word, fill = sentiment_category)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ sentiment_category, scales = "free") +
  scale_fill_manual(values = sentiment_colours) +
  labs(
    title = "Words contributing most to Sentida scores",
    subtitle = "Top positive and negative words in the OCR-corrected Sentida subset",
    x = "Frequency × Sentida word score",
    y = "Word"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/04_sentida_analysis/fig04_top_sentida_words.png",
  plot = top_word_plot,
  width = 8,
  height = 6,
  dpi = 300
)

# ------------------------------------------------------------
# 10. Figure 5: Positive words in critical articles
# ------------------------------------------------------------

# This figure helps explain why manually critical articles
# may still receive positive Sentida scores.

positive_words_in_critical <- sentida_words %>%
  filter(
    manual_stance == "critical",
    sentiment_category == "positive"
  ) %>%
  count(word, word_sentida_score, sort = TRUE) %>%
  mutate(
    contribution = n * word_sentida_score
  ) %>%
  slice_max(order_by = contribution, n = 12, with_ties = FALSE)

write_csv(
  positive_words_in_critical,
  "outputs/positive_words_in_critical_articles.csv"
)

critical_word_plot <- ggplot(
  positive_words_in_critical,
  aes(x = contribution, y = fct_reorder(word, contribution))
) +
  geom_col(fill = "#009E73") +
  labs(
    title = "Positive Sentida-coded words in manually critical articles",
    subtitle = "A possible explanation for positive scores in critical reviews",
    x = "Frequency × Sentida word score",
    y = "Word"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/04_sentida_analysis/fig05_positive_words_in_critical_articles.png",
  plot = critical_word_plot,
  width = 8,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 11. Figure 6: Core and expanded subsets
# ------------------------------------------------------------

subset_plot <- ggplot(
  sentida_summary_by_subset,
  aes(x = sentida_subset, y = mean_score, fill = sentida_subset)
) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
  geom_text(aes(label = paste0("n = ", n)), vjust = -0.4, size = 3.5) +
  scale_fill_manual(values = subset_colours) +
  labs(
    title = "Mean Sentida score by text subset",
    subtitle = "Core and expanded OCR-corrected texts",
    x = "Text subset",
    y = "Mean Sentida score",
    fill = "Text subset"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/04_sentida_analysis/fig06_sentida_score_by_subset.png",
  plot = subset_plot,
  width = 7,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 12. Case candidates for close reading
# ------------------------------------------------------------

# These cases are not automatic findings.
# They are useful candidates for close reading in the discussion.

case_candidates <- bind_rows(
  sentida_results_compact %>%
    arrange(desc(sentida_score)) %>%
    slice_head(n = 5) %>%
    mutate(case_group = "highest Sentida scores"),
  
  sentida_results_compact %>%
    arrange(sentida_score) %>%
    slice_head(n = 5) %>%
    mutate(case_group = "lowest Sentida scores"),
  
  sentida_results_compact %>%
    filter(manual_stance == "critical") %>%
    arrange(desc(sentida_score)) %>%
    slice_head(n = 3) %>%
    mutate(case_group = "critical articles with high Sentida scores"),
  
  sentida_results_compact %>%
    filter(manual_stance == "supportive") %>%
    arrange(sentida_score) %>%
    slice_head(n = 3) %>%
    mutate(case_group = "supportive articles with low Sentida scores")
) %>%
  distinct(id, case_group, .keep_all = TRUE)

write_csv(
  case_candidates,
  "outputs/sentida_case_candidates_for_close_reading.csv"
)

case_candidates

print("Done. Sentida analysis completed.")