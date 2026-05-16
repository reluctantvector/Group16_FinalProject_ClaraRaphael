# 04_make_text_preview.R
# Group 16 - Clara Raphael Reception, 1850-55
#
# Purpose:
# Create short text previews from the API OCR text,
# so we can check whether each item contains usable Clara Raphael text.

library(tidyverse)
library(stringr)

# Read fulltext segments -------------------------------------------------

fulltext_segments <- read_csv(
  "data/api_high_fulltext_segments.csv",
  show_col_types = FALSE
)

# Function to extract a short snippet around "Clara" ----------------------

make_snippet <- function(text) {
  
  if (is.na(text)) {
    return("")
  }
  
  text_lower <- str_to_lower(text)
  position <- str_locate(text_lower, "clara")[1]
  
  if (is.na(position)) {
    return(str_sub(text, 1, 600))
  }
  
  start <- max(position - 300, 1)
  end <- min(position + 800, str_length(text))
  
  str_sub(text, start, end)
}

# Create preview table ---------------------------------------------------

text_preview <- fulltext_segments %>%
  mutate(
    contains_clara = str_detect(str_to_lower(fulltext_org), "clara"),
    contains_raphael = str_detect(str_to_lower(fulltext_org), "raphael"),
    preview = map_chr(fulltext_org, make_snippet)
  ) %>%
  select(
    id,
    title,
    newspaper,
    date_iso,
    recordID,
    contains_clara,
    contains_raphael,
    pwa,
    cer,
    preview
  ) %>%
  arrange(id, recordID)

# Save preview file ------------------------------------------------------

write_csv(
  text_preview,
  "data/text_preview_clara_raphael.csv"
)

# Console check ----------------------------------------------------------

text_preview %>%
  count(id, newspaper, date_iso, contains_clara, contains_raphael) %>%
  print(n = 40)