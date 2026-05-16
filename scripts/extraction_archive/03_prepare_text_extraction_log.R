# 03_prepare_text_extraction_log.R
# Group 16 - Clara Raphael Reception, 1850-55
#
# Purpose:
# Create a working table for manual inspection of API OCR text.
# Manual decisions and notes were added later during corpus preparation.

library(tidyverse)
library(stringr)

# Read the fulltext segments created in script 02 -------------------------

fulltext_segments <- read_csv(
  "data/api_high_fulltext_segments.csv",
  show_col_types = FALSE
)

# Make one row per corpus item -------------------------------------------

text_extraction_log <- fulltext_segments %>%
  group_by(id, title, newspaper, date_iso, publication_place) %>%
  summarise(
    api_segments = n(),
    recordIDs = paste(recordID, collapse = "; "),
    raw_text_found = if_else(any(!is.na(fulltext_org) & fulltext_org != ""), "yes", "no"),
    contains_clara = if_else(
      any(str_detect(str_to_lower(fulltext_org), "clara")),
      "yes",
      "no"
    ),
    usable_for_text_analysis = "",
    decision = "",
    notes = "",
    .groups = "drop"
  ) %>%
  arrange(id)

# Save the working table -------------------------------------------------

write_csv(
  text_extraction_log,
  "data/text_extraction_log.csv"
)

text_extraction_log