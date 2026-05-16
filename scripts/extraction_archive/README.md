\# Extraction archive



This folder contains exploratory and preparatory scripts used during the Mediestream APIOCR extraction phase of the project.



These scripts document how we inspected and prepared raw OCR text from Mediestream API output. They were used to match selected corpus items with API metadata, extract OCR text from `fulltext\_org`, prepare text previews and combine relevant OCR segments for manual inspection.



The scripts in this folder are not part of the final analysis pipeline. The final analysis starts from



`datacorpus\_metadata.csv`



This file contains the curated metadata, stable Mediestream links, relevance coding, manual stance coding, manually selected raw passages, OCR-corrected `article\_text\_clean`, and Sentida subset coding used in the report.



The extraction scripts are kept for transparency, but they should not be understood as a fully automated reproduction of the final cleaned corpus. Article boundaries, column order and OCR usability were assessed manually during corpus preparation.



\## Scripts



\- `01\_match\_mediestream\_api.R` matches selected corpus items with Mediestream API metadata.

\- `02\_extract\_api\_fulltext.R` extracts raw OCR text from the API field `fulltext\_org`.

\- `03\_prepare\_text\_extraction\_log.R` creates a working table for manual inspection of OCR usability.

\- `04\_make\_text\_preview.R` creates preview files for checking relevant OCR passages.

\- `05\_combine\_api\_segments.R` combines selected OCR segments for inspection.



For the final analysis scripts, see the main `scripts` folder.



