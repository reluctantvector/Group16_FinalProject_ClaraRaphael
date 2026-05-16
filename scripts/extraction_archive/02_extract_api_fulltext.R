# 02_extract_api_fulltext.R
# Group 16 - Clara Raphael Reception, 1850-55
#
# Purpose:
# Extract raw OCR text for high relevance corpus items from the
# Mediestream API fulltext export.

library(tidyverse)
library(stringr)

# Read files -------------------------------------------------------------

high_matches <- read_csv(
  "data/api_high_matches_metadata.csv",
  show_col_types = FALSE
)

api_fulltext <- read_csv(
  "data/api_export_fulltext_clara_raphael_1850_1855.csv",
  show_col_types = FALSE
)

# Keep only API rows that match high relevance corpus items ---------------

high_record_ids <- high_matches %>%
  select(id, title, newspaper, date_iso, publication_place, recordID) %>%
  distinct()

high_fulltext <- high_record_ids %>%
  left_join(
    api_fulltext %>%
      select(recordID, timestamp, familyId, lplace, newspaper_page, pwa, cer, link, fulltext_org),
    by = "recordID"
  ) %>%
  arrange(id, recordID)

# Save one CSV with the relevant OCR segments ----------------------------

write_csv(
  high_fulltext,
  "data/api_high_fulltext_segments.csv"
)

# Save each OCR segment as a separate txt file ----------------------------

dir.create("data/ocr_api_raw", showWarnings = FALSE)

for (i in seq_len(nrow(high_fulltext))) {
  
  current_id <- high_fulltext$id[i]
  current_record <- high_fulltext$recordID[i]
  current_text <- high_fulltext$fulltext_org[i]
  
  segment <- str_extract(current_record, "segment_\\d+")
  
  if (is.na(segment)) {
    segment <- paste0("row_", i)
  }
  
  if (is.na(current_text)) {
    current_text <- ""
  }
  
  file_name <- paste0(
    "data/ocr_api_raw/",
    current_id,
    "_",
    segment,
    "_api_raw.txt"
  )
  
  writeLines(current_text, file_name, useBytes = TRUE)
}

# Console check ----------------------------------------------------------

cat("API fulltext rows kept:", nrow(high_fulltext), "\n")
cat("Corpus IDs represented:", n_distinct(high_fulltext$id), "\n")
cat(
  "Rows with missing fulltext_org:",
  sum(is.na(high_fulltext$fulltext_org) | high_fulltext$fulltext_org == ""),
  "\n"
)

high_fulltext %>%
  count(id, newspaper, date_iso, name = "api_segments") %>%
  arrange(desc(api_segments), id) %>%
  print()