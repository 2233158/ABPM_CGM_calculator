# ABPM Integrated Bilingual Analysis System (EN / 中文)

One integrated R Shiny application that combines

- the full metric engine of the optimized ABPM calculator (latest Chinese edition),
- the v1.3 English standalone experience (column mapping, flexible input), and
- **built-in preprocessing** for raw **Mobil-O-Graph 24h PWA** exports (`.xls` / `.xlsx`),

with a **bilingual interface (English / 中文)** switchable at any time.

- Main application: `ABPM_calculator_integrated.R` (single file)
- Self-test: `self_test.R`
- Raw test exports: `test_data/`
- Golden converted CSVs: `converted_samples/`

Copyright © 2026 Moran Li, Tongji University School of Medicine (PhD candidate).
Developed by Moran Li, who retains the right of final interpretation.
Contact: morethanlee@163.com

## 1. Requirements

- R (>= 4.0 recommended) with RStudio, or the `shiny` package from a terminal.
- Internet access on first run so missing packages can be installed automatically:
  `shiny, dplyr, stringr, DT, shinythemes, shinyjs, tidyr, zoo, plotly, ggplot2, openxlsx, readxl, rintrojs, zip`.
  `zip` is used to pack the selected-result download; it is guarded, and the app
  falls back to `utils::zip()` (which needs an external `zip` executable) if it
  is missing.
- Python (with `xlrd`) on PATH, used only as a fallback reader for damaged
  legacy `.xls` exports (see section 4).

## 2. Run

In RStudio: open `ABPM_calculator_integrated.R` and click **Run App**.

From a terminal:

```r
shiny::runApp("ABPM_calculator_integrated.R")
```

The app starts in English; use the **EN / 中文** switch in the top bar to change
the language at any time. Imported data, settings and results are preserved
across a language switch.

There are two built-in demos, one per input path:

- **Prepared CSV path**: tick "Use built-in demo data (P001-P010)".
- **Raw device export path** (default): "Use built-in device samples
  (50002/50003)" - two anonymized real 24h PWA exports that drive the same
  Convert → preview → Load workflow as uploaded raw files.

### Glucose (CGM) domain

The sidebar **Data domain** switch adds a glucose domain alongside ABPM:

- Inputs (raw and processed, like BP): raw CGM exports (`.xlsx`/`.xls`, e.g.
  the 5-minute device sheet) are converted to the canonical
  `MASKID, Time, GLU (mmol/L)` long table; processed glucose CSVs map the
  GLU column via the same mapping panel.
- Built-in sample: a **14-day anonymized CGM recording** (device serial
  LT2503SGHM, 4012 readings, day offsets `+0D..+14D`; personal name removed).
- Multi-day support: for recordings ≥ 3 days the day/night windows are applied
  to every calendar day (`+0D..+15D`), so the full 14 days are analysed.
- Results are separated by metric prefix (`GLU_*` vs `SBP_*` etc.), and the
  Personalized Analysis tab shows a glucose block: four dimensions (Mean,
  CV, TIR, TAR/TBR burden) judged against **ADA 2025** and the **China CDS
  2024** guideline targets (TIR 3.9-10.0 ≥ 70%, CV ≤ 36%, mean ≤ 8.6 mmol/L,
  TAR ≤ 25%, TBR ≤ 4%).

### Demo mode and deployment

The local source file runs with **uploads enabled** by default
(`DEMO_MODE_DEFAULT <- FALSE` at the top). File uploads are hidden only when
`DEMO_MODE` resolves to TRUE (set the flag to TRUE, or the env var
`SHINY_DEMO_MODE=TRUE`). `deploy.R` stages both variants for shinyapps.io:
the demo app (uploads disabled) and the full app (uploads enabled).

### Deploy to shinyapps.io (free tier)

1. Register at https://www.shinyapps.io/ and copy your token/secret
   (Dashboard → Account → Tokens).
2. Once, in RStudio:
   `install.packages("rsconnect")`, then
   `rsconnect::setAccountInfo(name, token, secret)`.
3. Open `deploy.R`, adjust `appName`, and run it. Re-run after every change
   to update the deployed app. See `部署到shinyapps.io指南.md` for details.

## 3. Step-by-step workflow

1. **Import your data** — two input paths, each with its own built-in demo:
   - *Prepared CSV* (built-in P001-P010, or your own CSV files, multiple
     allowed): map the columns to `MASKID / Time / SBP / DBP / HR / PP / MAP`
     (aliases are detected automatically) and click **Apply mapping**.
   - *Raw device export* (built-in samples 50002/50003, or your own
     Mobil-O-Graph 24h PWA files, multiple allowed): check the MASKID per
     file, click **Convert**, then **Load into analysis**. You may also
     download the preprocessed CSV.
2. **Define day/night times and analysis options** — set Day 1 / Day 2 daytime
   and nighttime start times (presets: East Asia 05–20, Europe/US 07–22),
   choose the **interpolation mode** (see the inline explanation of edge
   handling) and the **VIM mode** (fixed / cohort; the formula card next to it
   explains the parameters).
3. **Process the data (Step 1)** — click `1. Process Data`.
4. **Set target ranges** — SBP/DBP/HR limits for Day / Night / 24h unified;
   PP/MAP optional (auto-derivable from SBP/DBP).
5. **Calculate metrics (Step 2)** — click `2. Calculate Metrics`. Four result
   sets are produced: day, night, 24h (unified thresholds) and 24h (segmented
   thresholds).
6. **Review, assess and export** — visualizations, the personalized assessment
   (per-period hypertension judgment against ESC 2024 / AHA/ACC 2025 / China 2024
   plus the four-dimension grading), then tick the export items and download
   **CSV (zip)** or **Excel**.

A **guided tour** button in the top bar walks through these steps inside the
app; the **User Guide** tab contains the same instructions plus an FAQ.

## 4. Data formats

- **Preprocessed CSV**: header row; only `MASKID` and `Time` are required.
  Any subset of `SBP/DBP/HR/PP/MAP` may be present (all metric columns are
  optional), and `GLU` is optional too - a file without glucose data simply
  produces no glucose metrics and does not affect the BP analysis. Time format
  `HHMM+XD` (e.g. `0807+0D`) or `HHMM`. Imported PP/MAP
  are kept as-is; they are only derived where missing. Multiple files may have
  different column structures; they are merged by column name (missing values
  stay empty). A CSV containing only e.g. SBP is fully supported (DBP/HR are
  simply not calculated). To analyse a different metric, map its source column
  (e.g. cSBP) onto one of the SBP/DBP/HR/PP/MAP slots in the mapping panel.
  Besides `MASKID`/`ID`/`Patient No.` etc., the ID column is also auto-detected
  when it is labelled `Number`/`No.`/`序号` as in device exports - this match
  has the lowest priority, so a file carrying a real `MASKID` still uses it.
- **Raw Mobil-O-Graph 24h PWA export**: single-sheet layout with metadata rows
  on top and a `Number/Date/Time/Systole/...` table below. The index column of
  that table may be labelled `Number`, `No.`, `Nr.` or `序号` depending on the
  firmware/localisation; the header row is located either way. The converter keeps
  the device-measured `pPP`/`MAP`, drops failed readings (zero values: artefacts,
  device off, ...) and reports how many rows were dropped. The patient ID
  (MASKID) is read automatically from the file's metadata `ID` (editable before
  conversion; falls back to the file name when the metadata has no ID).
  Note: some device exports carry a damaged OLE2 stream that R's `readxl`
  refuses; the app then falls back to a **Python + xlrd** bridge, so Python
  (with the `xlrd` package) should be installed and on PATH for such files.

## 5. Verification

This development environment has no R runtime, so the R code was verified
statically (structure, dictionary keys, input IDs, delimiter balance) and the
conversion algorithm was validated against the two raw exports with an
independent Python prototype. Please run on your machine:

```r
source("self_test.R")
```

It converts both `test_data/*.xls` files with the app's own R functions and
compares every value against `converted_samples/*.csv`. Expected results:
50010 → 102 valid rows (33 failed rows dropped), 50001 → 131 valid rows
(7 failed rows dropped).

## 6. Calculation contract

- Traditional statistics (`max/min/Delta/mean/SD/CV/ARV/VIM` and the count-based
  `Load`) are computed from the **raw observed readings only** (duplicate
  timestamps kept).
- Area/time metrics (`Sa/Sc/Sd/AUC/Ts1/Ts2/Ts3/TTR/TOTR/TUTR/hyper_Burden/
  hypo_Burden/cumulative_Load/Se/Sf`) are computed on the patient-specific
  **interpolated timeline** (linear, with exact threshold-crossing times).
  In the 24h-segmented result set, day and night use their own limits and are
  then summed.
- All formulas are listed with their data source in the **User Guide** tab.

## 7. Notes

- The analysis windows cover Day-0 night through the end of the Day-2 daytime
  window; readings beyond that point (longer recordings) are included in the
  24h (unified) results only.
- Interpolation mode "Full-axis, edge clamping" fills missing edges with the
  nearest observed value across the whole analysis window; "Valid-observation-
  window" interpolates only between the first and last valid reading.
- Outputs support research analysis and do not replace clinical diagnosis.
