# 01_corpus_overview.R
# Group 16 - Clara Raphael reception project
#
# Purpose:
# Create basic overview figures of the curated corpus.

library(tidyverse)

# Load data
# The file should be placed in the data folder.
corpus <- read_csv("data/corpus_metadata.csv", show_col_types = FALSE)

# Prepare columns for plotting
corpus <- corpus %>%
  mutate(
    year = as.integer(str_sub(date_iso, 1, 4)),
    newspaper = str_squish(newspaper),
    publication_place = str_squish(publication_place),
    relevance = str_to_lower(str_squish(relevance)),
    
    # Correct known spelling issue if it occurs
    newspaper = str_replace(
      newspaper,
      "Avertissemenststidende",
      "Avertissementstidende"
    )
  )

# Create folders for output
dir.create("figures", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

# Quick checks in console
print(corpus %>% count(relevance))
print(corpus %>% count(year))
print(corpus %>% count(newspaper, sort = TRUE))
print(corpus %>% count(publication_place, sort = TRUE))


# ------------------------------------------------------------
# Figure 1: Corpus items by year
# ------------------------------------------------------------

corpus_by_year <- corpus %>%
  count(year)

fig_year <- ggplot(corpus_by_year, aes(x = factor(year), y = n)) +
  geom_col(fill = "grey40") +
  labs(
    title = "Corpus items by year",
    subtitle = "Curated Mediestream corpus on the early reception of Clara Raphael, 1850–55",
    x = "Year",
    y = "Number of items"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/corpus_by_year.png",
  plot = fig_year,
  width = 7,
  height = 5,
  dpi = 300
)


# ------------------------------------------------------------
# Figure 2: Corpus items by newspaper
# ------------------------------------------------------------

corpus_by_newspaper <- corpus %>%
  count(newspaper, sort = TRUE) %>%
  mutate(newspaper = fct_reorder(newspaper, n))

fig_newspaper <- ggplot(corpus_by_newspaper, aes(x = n, y = newspaper)) +
  geom_col(fill = "grey40") +
  labs(
    title = "Corpus items by newspaper",
    subtitle = "Number of selected items per newspaper",
    x = "Number of items",
    y = "Newspaper"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/corpus_by_newspaper.png",
  plot = fig_newspaper,
  width = 8,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# Figure 3: Corpus items by publication place
# ------------------------------------------------------------

corpus_by_place <- corpus %>%
  count(publication_place, sort = TRUE) %>%
  mutate(publication_place = fct_reorder(publication_place, n))

fig_place <- ggplot(corpus_by_place, aes(x = n, y = publication_place)) +
  geom_col(fill = "grey40") +
  labs(
    title = "Corpus items by publication place",
    subtitle = "Number of selected items per publication city",
    x = "Number of items",
    y = "Publication place"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/corpus_by_publication_place.png",
  plot = fig_place,
  width = 7,
  height = 5,
  dpi = 300
)


# ------------------------------------------------------------
# Figure 4: Relevance distribution
# ------------------------------------------------------------

corpus_by_relevance <- corpus %>%
  mutate(
    relevance = factor(relevance, levels = c("high", "medium", "low"))
  ) %>%
  count(relevance)

fig_relevance <- ggplot(corpus_by_relevance, aes(x = relevance, y = n)) +
  geom_col(fill = "grey40") +
  labs(
    title = "Relevance distribution",
    subtitle = "Manual relevance coding of selected Mediestream items",
    x = "Relevance category",
    y = "Number of items"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  "figures/corpus_by_relevance.png",
  plot = fig_relevance,
  width = 7,
  height = 5,
  dpi = 300
)


# ------------------------------------------------------------
# Save summary tables
# ------------------------------------------------------------

write_csv(corpus_by_year, "outputs/corpus_by_year.csv")
write_csv(corpus_by_newspaper, "outputs/corpus_by_newspaper.csv")
write_csv(corpus_by_place, "outputs/corpus_by_publication_place.csv")
write_csv(corpus_by_relevance, "outputs/corpus_by_relevance.csv")

print("Done. Figures saved in /figures and tables saved in /outputs.")

