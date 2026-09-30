# =============================================================================
# ABPM Integrated Bilingual Analysis System  (EN / 中文)
# -----------------------------------------------------------------------------
# One integrated R Shiny application combining:
#   - the full metric engine of the optimized ABPM calculator,
#   - the v1.3 English standalone experience (column mapping, flexible input),
#   - built-in preprocessing for raw Mobil-O-Graph 24h PWA exports (.xls/.xlsx).
#
# Copyright (c) 2026 Moran Li, Tongji University School of Medicine
# (PhD candidate). Developed by Moran Li, who retains the right of final
# interpretation. Contact: morethanlee@163.com
# =============================================================================

# --- Deployment flag (public demo mode) ---
# DEMO_MODE = TRUE  -> all file uploads are hidden; only the two built-in
#                      demo paths remain (prepared CSV P001-P010 and raw
#                      device samples 50002/50003).
# DEMO_MODE = FALSE -> uploads enabled (full version; the local default).
# DEMO_MODE_DEFAULT is the default used when the environment variable
# SHINY_DEMO_MODE is not set (deploy.R flips this line to stage the
# upload-disabled demo variant for shinyapps.io).
DEMO_MODE_DEFAULT <- FALSE
DEMO_MODE <- if (nzchar(Sys.getenv("SHINY_DEMO_MODE"))) {
  isTRUE(as.logical(Sys.getenv("SHINY_DEMO_MODE")))
} else {
  DEMO_MODE_DEFAULT
}

# --- 0. Load Required Packages ---
packages <- c("shiny", "dplyr", "stringr", "DT", "shinythemes",
              "shinyjs", "tidyr", "zoo", "plotly", "ggplot2", "openxlsx",
              "readxl", "rintrojs", "zip")

new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
# Skip auto-install in non-interactive sessions (e.g. shinyapps.io, where
# rsconnect installs the declared packages at deploy time).
if (length(new_packages) && interactive()) install.packages(new_packages)

suppressPackageStartupMessages({
  library(shiny)
  library(dplyr)
  library(stringr)
  library(DT)
  library(shinythemes)
  library(shinyjs)
  library(tidyr)
  library(zoo)
  library(plotly)
  library(ggplot2)
  library(openxlsx)
  library(readxl)
})

has_introjs <- requireNamespace("rintrojs", quietly = TRUE)
if (has_introjs) {
  library(rintrojs)
} else {
  warning("rintrojs is not installed; the interactive guided tour will be disabled.",
          call. = FALSE)
}

# zip packs the selected-result CSVs. Guarded so the app still starts (and
# falls back to utils::zip) when the package is unavailable.
has_zip <- requireNamespace("zip", quietly = TRUE)
if (has_zip) suppressPackageStartupMessages(library(zip))

`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0L || (length(a) == 1L && is.na(a)) ||
      (length(a) == 1L && is.character(a) && !nzchar(a))) b else a
}
