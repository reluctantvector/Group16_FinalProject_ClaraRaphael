# Data

This folder contains the data used in the project.

## Main files

- `corpus_metadata.csv`: main dataset for the final project. It contains manually curated metadata for the selected Mediestream corpus, relevance coding, manual stance coding, Sentida scores and analysis-related fields.
- `search_log.csv`: brief documentation of search queries and selection work.
- `keyword_frequency_table.csv`: derived table with keyword frequencies used in the keyword analysis.
- `manual_stance_counts.csv`: derived table summarising the manual stance coding.
- `semantic_fields_by_article_stance_table.csv`: derived table used to compare semantic fields across article stance categories.

## Notes

Sentida scores were first produced in a separate working file, but they have been inserted into `corpus_metadata.csv` in the final repository version. The separate Sentida working sheet is therefore not included.

Some intermediate working sheets and temporary exports were discarded during the project. The repository contains the files needed to document and reproduce the final analysis, not every temporary version created during data cleaning.

Some fields may include OCR-derived or manually corrected text passages used for analysis. These source texts are included only for transparency and reproducibility. They are not re-licensed by the project authors.
