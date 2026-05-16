# 01_match_mediestream_api.R
# Group 16 - Clara Raphael Reception, 1850-55

# NOTE:
# This script documents the preparatory Mediestream API/OCR extraction workflow.
# It is kept as documentation of how raw OCR text was inspected and prepared.
# The final analysis pipeline starts from data/corpus_metadata.csv, which contains
# the curated metadata, manually selected passages, OCR-corrected article_text_clean
# and Sentida subset coding.
#
# This script is not required for running the final analysis figures.

library(tidyverse)
library(stringr)

# Read files -------------------------------------------------------------

corpus <- read_csv("data/corpus_metadata.csv", show_col_types = FALSE)

api_export <- read_csv(
  "data/api_export_metadata_clara_raphael_1850_1855.csv",
  show_col_types = FALSE
)

# Quick check of the corpus file -----------------------------------------

cat("Corpus rows and columns:\n")
print(dim(corpus))

cat("\nRelevance counts:\n")
print(corpus %>% count(relevance))

# Extract UUIDs from Mediestream links -----------------------------------
# The UUID is the long identifier in the Mediestream link.

extract_uuid <- function(x) {
  str_extract(
    x,
    "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"
  )
}

# Prepare corpus metadata ------------------------------------------------

corpus_high <- corpus %>%
  mutate(
    relevance = str_to_lower(str_trim(relevance)),
    corpus_uuid = extract_uuid(mediestream_link)
  ) %>%
  filter(relevance == "high")

# Prepare API metadata ---------------------------------------------------

api_prepared <- api_export %>%
  mutate(
    api_uuid = extract_uuid(link),
    api_date = str_sub(timestamp, 1, 10)
  )

# Match corpus items with API records ------------------------------------

api_matches <- corpus_high %>%
  left_join(
    api_prepared,
    by = c("corpus_uuid" = "api_uuid")
  )

# Keep matched and unmatched rows separately -----------------------------

matched <- api_matches %>%
  filter(!is.na(recordID))

unmatched <- api_matches %>%
  filter(is.na(recordID)) %>%
  select(
    id,
    title,
    newspaper,
    date_iso,
    publication_place,
    mediestream_link,
    relevance,
    manual_stance,
    corpus_uuid
  )

# Make a simple match summary --------------------------------------------

match_summary <- api_matches %>%
  group_by(
    id,
    title,
    newspaper,
    date_iso,
    publication_place,
    mediestream_link,
    relevance,
    manual_stance,
    corpus_uuid
  ) %>%
  summarise(
    n_api_matches = sum(!is.na(recordID)),
    api_dates = paste(unique(na.omit(api_date)), collapse = "; "),
    api_newspapers = paste(unique(na.omit(familyId)), collapse = "; "),
    pwa = paste(unique(na.omit(pwa)), collapse = "; "),
    cer = paste(unique(na.omit(cer)), collapse = "; "),
    match_status = if_else(n_api_matches > 0, "matched", "unmatched"),
    .groups = "drop"
  )

# Check items with more than one API match --------------------------------
# These are usually several API segments from the same Mediestream page.

multiple_matches <- matched %>%
  group_by(id) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  select(
    id,
    title,
    newspaper,
    date_iso,
    publication_place,
    recordID,
    timestamp,
    familyId,
    lplace,
    newspaper_page,
    pwa,
    cer,
    link
  ) %>%
  arrange(id, recordID)

# Save output files ------------------------------------------------------

write_csv(matched, "data/api_high_matches_metadata.csv")
write_csv(unmatched, "data/api_high_unmatched_metadata.csv")
write_csv(match_summary, "data/api_high_match_summary.csv")
write_csv(multiple_matches, "data/api_multiple_matches_check.csv")

# Print result in console ------------------------------------------------

cat("\nAPI matching result:\n")
cat("High relevance corpus items:", nrow(corpus_high), "\n")
cat("Matched corpus items:", sum(match_summary$match_status == "matched"), "\n")
cat("Unmatched corpus items:", sum(match_summary$match_status == "unmatched"), "\n")
cat("API rows connected to high relevance items:", nrow(matched), "\n")

cat("\nItems with more than one API match:\n")

match_summary %>%
  filter(n_api_matches > 1) %>%
  select(id, newspaper, date_iso, n_api_matches) %>%
  print()