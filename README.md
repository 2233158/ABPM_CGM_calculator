# ABPM Integrated Bilingual Analysis System (EN / 中文)

An integrated R Shiny application for analysing 24-hour ambulatory blood pressure
monitoring (ABPM) data. It ingests raw Mobil-O-Graph 24h PWA device exports or
prepared CSV files and computes a comprehensive metric set — day, night and
24-hour statistics (mean, SD, CV, ARV, VIM, AUC, TTR and more) — assessed against
ESC 2024, AHA/ACC 2025 and China 2024 guideline targets, with an optional CGM
glucose domain assessed under ADA 2025 / China CDS 2024 targets. The bilingual
English / 中文 interface can be switched at any time, and all results can be
exported to CSV or Excel for further research.

- Main application: `ABPM_calculator_integrated.R` (single file)
- Full manual: `README_English.md` (English) · `使用说明_中文.md` (中文)
- Deployment guide: `部署到shinyapps.io指南.md`

Copyright © 2026 Moran Li, Tongji University School of Medicine (PhD candidate).
Contact: morethanlee@163.com

## 1. Requirements

- R (>= 4.0 recommended) with RStudio.
- Internet access on the first run, so that missing packages can be installed
  automatically (`shiny, dplyr, stringr, DT, shinythemes, shinyjs, tidyr, zoo,
  plotly, ggplot2, openxlsx, readxl, rintrojs, zip`).

## 2. Run the app

In RStudio: open `ABPM_calculator_integrated.R` and click **Run App**.

From a terminal:

```r
shiny::runApp("ABPM_calculator_integrated.R")
```

The app starts in English; use the **EN / 中文** switch in the top bar to change
the language at any time. Imported data, settings and results are preserved across
a language switch.

**Try it without your own data.** Two built-in demos cover the two input paths:

- *Prepared CSV path*: tick **Use built-in demo data (P001-P010)**.
- *Raw device export path* (default): **Use built-in device samples (50002/50003)** —
  two anonymized real 24h PWA exports that follow the same Convert → preview →
  Load workflow as uploaded files.

## 3. Workflow in six steps

1. **Import your data** — two input paths:
   - *Prepared CSV*: map the columns to `MASKID / Time / SBP / DBP / HR / PP / MAP`
     (aliases are auto-detected) and click **Apply mapping**.
   - *Raw device export*: check the MASKID per file, click **Convert**, then
     **Load into analysis**. The preprocessed CSV can also be downloaded.
2. **Define day/night times and options** — daytime and nighttime start times for
   Day 1 / Day 2 (presets: East Asia 05–20, Europe/US 07–22), the interpolation
   mode, and the VIM mode.
3. **Process the data** — click **1. Process Data**.
4. **Set target ranges** — SBP/DBP/HR limits for Day / Night / 24h; PP/MAP are
   optional (auto-derivable from SBP/DBP).
5. **Calculate metrics** — click **2. Calculate Metrics**. Four result sets are
   produced: day, night, 24h (unified thresholds) and 24h (segmented thresholds).
6. **Review and export** — visualizations and the personalized assessment
   (per-period hypertension judgement against ESC 2024 / AHA/ACC 2025 / China 2024
   plus a four-dimension grading), then tick the export items and download
   **CSV (zip)** or **Excel**.

A **guided tour** button in the top bar walks through these steps inside the app;
the **User Guide** tab contains the same instructions plus an FAQ.

## 4. Optional glucose (CGM) domain

The sidebar **Data domain** switch adds a glucose domain alongside ABPM. Raw CGM
exports or prepared glucose CSVs are supported, with a built-in **14-day
anonymized CGM recording** as a sample. Glucose results carry the `GLU_*` prefix
and are graded on four dimensions (mean, CV, TIR, TAR/TBR burden) against ADA 2025
and China CDS 2024 targets.

## 5. Input formats at a glance

- **Prepared CSV**: header row; only `MASKID` and `Time` are required. Any subset
  of `SBP/DBP/HR/PP/MAP` (and optional `GLU`) may be present. Time format `HHMM+XD`
  (e.g. `0807+0D`) or `HHMM`. Multiple files with different column structures are
  merged by column name.
- **Raw Mobil-O-Graph 24h PWA export** (`.xls` / `.xlsx`): single-sheet layout with
  metadata rows on top. The converter keeps device-measured `pPP`/`MAP` and drops
  failed (zero-value) readings, reporting how many rows were dropped. The patient
  ID is read from the file's metadata automatically.

## 6. Verification (optional)

```r
source("self_test.R")
```

This converts both `test_data/*.xls` files with the app's own R functions and
compares every value against the golden CSVs in `converted_samples/`. Expected:
50010 → 102 valid rows (33 failed rows dropped), 50001 → 131 valid rows
(7 failed rows dropped).

## 7. Notes

- Results support research analysis and do not replace clinical diagnosis.
- Local source runs with uploads enabled by default (`DEMO_MODE_DEFAULT <- FALSE`);
  the demo variant hides uploads and exposes only the built-in demos.
- See `README_English.md` for the full manual (data formats, calculation contract,
  deployment details).
