# 05_combine_api_segments.R
# Group 16 - Clara Raphael Reception, 1850-55
#
# Purpose:
# Combine API OCR segments into one raw inspection file per corpus item.
# The final article_text_raw and article_text_clean fields were selected,
# corrected and checked separately in corpus_metadata.csv.

library(tidyverse)
library(stringr)

fulltext_segments <- read_csv(
  "data/api_high_fulltext_segments.csv",
  show_col_types = FALSE
)

dir.create("data/ocr_api_by_id", showWarnings = FALSE)

combined_texts <- fulltext_segments %>%
  group_by(id, title, newspaper, date_iso) %>%
  summarise(
    combined_fulltext = paste(fulltext_org, collapse = "\n\n--- NEW API SEGMENT ---\n\n"),
    api_segments = n(),
    .groups = "drop"
  )

for (i in seq_len(nrow(combined_texts))) {
  
  file_name <- paste0(
    "data/ocr_api_by_id/",
    combined_texts$id[i],
    "_api_raw_combined.txt"
  )
  
  writeLines(combined_texts$combined_fulltext[i], file_name, useBytes = TRUE)
}

write_csv(combined_texts, "data/api_high_fulltext_combined.csv")

cat("Combined text files created:", nrow(combined_texts), "\n")