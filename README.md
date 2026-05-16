# Group 16: Clara Raphael Reception, 1850–55

Group members: Philip M-L*, Rikke Kjeldsen Otkjær and Erik Bæk Hansen.

This repository contains the digital product for Group 16’s final project in Digital Archives and Methods.

The project examines the early Danish newspaper reception of Mathilde Fibiger’s *Clara Raphael* through a curated Mediestream corpus. The analysis combines corpus overview, manual stance coding, keyword analysis and Sentida sentiment scores.

*User is registered under Name and address protection.

## Research question

How can a curated Mediestream corpus be used to map the early Danish newspaper reception of Mathilde Fibiger’s Clara Raphael from 1850 to 1855, and what does the comparison between manual stance coding, keyword analysis and Sentida sentiment analysis reveal about the possibilities and limits of computational methods in historical reception studies?

## Repository structure

- `data/`: search log, corpus metadata and cleaned analysis data
- `scripts/`: R scripts used for corpus overview, stance visualisation, keyword analysis and Sentida comparison
- `figures/`: exported visualisations
- `report/`: final report or report-related files

## Data

The corpus is based on selected Mediestream newspaper items from 1850–55. The dataset is curated and does not contain all Mediestream hits for *Clara Raphael*. Each selected item is referenced through a stable Mediestream link in `corpus_metadata.csv`.

Mediestream source PDFs and newspaper facsimiles are not redistributed in this repository.

## Analysis

The project contains four analytical components:

1. Corpus construction
2. Manual stance coding
3. Keyword / term frequency analysis
4. Sentida as comparison

## How to reproduce the analysis

1. Open the project in RStudio or Posit Cloud.
2. Install or load the packages listed in the scripts.
3. Place the CSV files in `data/`.
4. Run the scripts in numerical order from `scripts/`.
5. Exported visualisations are saved to `figures/`.

## License

The R scripts and project code written by the authors are licensed under the MIT License.

The authors’ own metadata, manual coding, derived tables, figures and documentation are licensed under CC BY 4.0. See `DATA_LICENSE.md`.

Original newspaper texts, OCR output, Mediestream source images, PDFs, facsimiles and infrastructure are not covered by these licenses. They are historical source materials accessed through Mediestream and referenced through stable Mediestream links in the dataset. The repository does not redistribute Mediestream PDFs or newspaper facsimiles.

## Limitations

The corpus is shaped by Mediestream search results, OCR quality, digitisation coverage, article-boundary problems and manual relevance decisions. Sentida is used as an exploratory comparison, not as a definitive measure of historical stance.
