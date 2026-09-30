# -*- coding: utf-8 -*-
"""Assemble the integrated bilingual R Shiny app from the base file and parts.

Reads the original 4,735-line R file, extracts the unchanged engine regions,
applies all planned patches (interpolation/VIM parameterization, bilingual
messages, chart localization, selected-item exports), and writes the final
single-file application.

Every patch asserts that its anchor exists exactly once (or the expected
number of times), so a mismatch fails loudly instead of silently corrupting
the output. All paths are relative to this script's own directory.
"""

from pathlib import Path

BASE = r"_build/base_latest.R"
OUT = r"ABPM_calculator_integrated.R"
PART_FILES = {
    "01_header.R": r"_build/parts/01_header.R",
    "02_dict.R": r"_build/parts/02_dict.R",
    "03_preprocess.R": r"_build/parts/03_preprocess.R",
    "04_load_prepare.R": r"_build/parts/04_load_prepare.R",
    "05_series.R": r"_build/parts/05_series.R",
    "06_vim.R": r"_build/parts/06_vim.R",
    "07_assessment.R": r"_build/parts/07_assessment.R",
    "08_ui.R": r"_build/parts/08_ui.R",
    "09_server_head.R": r"_build/parts/09_server_head.R",
    "10_server_data.R": r"_build/parts/10_server_data.R",
    "11_server_exports.R": r"_build/parts/11_server_exports.R",
    "12_footer.R": r"_build/parts/12_footer.R",
    "13_glucose.R": r"_build/parts/13_glucose.R",
    "14_glucose_server.R": r"_build/parts/14_glucose_server.R",
}

base = Path(BASE).read_text(encoding="utf-8")

def part(name):
    return Path(PART_FILES[name]).read_text(encoding="utf-8")

def section(start_anchor, end_anchor=None):
    i = base.index(start_anchor)
    j = base.index(end_anchor, i) if end_anchor else len(base)
    return base[i:j]

def rep(text, old, new, count=1, label=""):
    n = text.count(old)
    if n != count:
        raise SystemExit("PATCH FAILED [%s]: anchor found %d times (expected %d):\n%s"
                         % (label, n, count, old[:120]))
    return text.replace(old, new)

def rep_all(text, old, new, min_count=1, label=""):
    n = text.count(old)
    if n < min_count:
        raise SystemExit("PATCH FAILED [%s]: anchor found %d times (expected >=%d):\n%s"
                         % (label, n, min_count, old[:120]))
    return text.replace(old, new)

# ---------------------------------------------------------------- extraction
builtin = section("# --- 1. Built-in Example Data (Reduced to P001, P002) ---",
                  "# --- 2. Helper Functions ---")
builtin = builtin.replace(
    "# --- 1. Built-in Example Data (Reduced to P001, P002) ---",
    "# --- 1. Built-in Example Data (prepared-CSV path demo) ---\n"
    "# P001-P010: simulated sample in the canonical long CSV format.")

# --- 1b. Built-in device samples (raw-export path demo) ---
# Two anonymized real device exports, embedded in the canonical converted
# format so the "raw device export" workflow (edit ID -> Convert -> Load)
# can be demonstrated without real files.
device_items = []
for key, fname in (("50002", "builtin_50002.csv"), ("50003", "builtin_50003.csv")):
    rows = Path("_build/" + fname).read_text(encoding="utf-8").strip().split("\n")
    if not rows or rows[0] != "MASKID,Time,SBP,DBP,HR,PP,MAP":
        raise SystemExit("unexpected header in %s" % fname)
    device_items.append('  `%s` = "%s"' % (key, "\\n".join(rows)))
device_block = (
    "# --- 1b. Built-in device samples (anonymized real 24h PWA exports) ---\n"
    "# Only ID/time/measurements are retained. These power the built-in\n"
    "# 'raw device export' demo path (Convert -> preview -> Load).\n"
    "DEVICE_SAMPLE_CSVS <- list(\n" + ",\n".join(device_items) + "\n)\n"
)

# --- 1c. Built-in glucose samples (anonymized 14-day CGM export) ---
# GLUCOSE_SAMPLE_RAW : the original sheet layout as CSV text (header row with
#                      metadata; the personal name is replaced by ***).
# GLUCOSE_SAMPLE_CSV : the canonical processed form MASKID,Time,GLU (mmol/L).
# MASKID = device serial; no personal information is retained.
glu_raw_text = Path("_build/builtin_glu_raw.csv").read_text(encoding="utf-8")
glu_processed_text = Path("_build/builtin_glu_processed.csv").read_text(encoding="utf-8")
glucose_block = (
    "# --- 1c. Built-in glucose sample (anonymized 14-day CGM export) ---\n"
    "# Raw layout: the original sheet as CSV text (name replaced by ***).\n"
    "# Processed form: canonical MASKID,Time,GLU in mmol/L, day offsets +0D..+14D.\n"
    'GLUCOSE_SAMPLE_RAW <- "%s"\n'
    'GLUCOSE_SAMPLE_CSV <- "%s"\n'
    % (glu_raw_text.strip().replace('"', '\\"'), glu_processed_text.strip())
)
helpers_time = section("# --- 2. Helper Functions ---",
                       "load_and_prepare_data <- function(df) {")
helpers_wide = section("# --- 2.3 Data Transformation (Wide Format) --- (Unchanged)",
                       "create_individual_patient_series <- function(long_data,")
helpers_after_series = section("individual_series_to_wide <- function(individual_series) {",
                               "add_vim_from_observed_results <- function(results_df) {")
region_D = section("calculate_abpm_metrics_for_period_individual <- function(metric_patient_series, period_key,",
                   "# --- 2.8 Visualization Plotting Functions --- (Unchanged)")
region_charts = section("# --- 2.8 Visualization Plotting Functions --- (Unchanged)",
                        "# --- 2.9 Full export and four-dimensional personalized assessment ---")
server_rest = section("  # --- UI Rendering for Data Tables (Unchanged) ---",
                      "} # End server function")

# ------------------------------------------------- patches on helpers_after_series (multi-day windows)
helpers_after_series = rep(helpers_after_series,
"""individual_period_indices <- function(time_values, period_key,
                                      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                      day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  d1_day_start <- day_start1_h * 60 + day_start1_m
  d1_night_start <- night_start1_h * 60 + night_start1_m
  d2_day_start <- 24 * 60 + day_start2_h * 60 + day_start2_m
  d2_night_start <- 24 * 60 + night_start2_h * 60 + night_start2_m
  if (period_key == "24h") return(seq_along(time_values))
  if (period_key == "day") {
    return(which((time_values >= d1_day_start & time_values < d1_night_start) |
                   (time_values >= d2_day_start & time_values < d2_night_start)))
  }
  if (period_key == "night") {
    return(which(time_values < d1_day_start |
                   (time_values >= d1_night_start & time_values < d2_day_start)))
  }
  integer(0)
}""",
"""individual_period_indices <- function(time_values, period_key,
                                      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                      day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  d1_day_start <- day_start1_h * 60 + day_start1_m
  d1_night_start <- night_start1_h * 60 + night_start1_m
  d2_day_start <- 24 * 60 + day_start2_h * 60 + day_start2_m
  d2_night_start <- 24 * 60 + night_start2_h * 60 + night_start2_m
  if (period_key == "24h") return(seq_along(time_values))

  # Multi-day recordings (>= 3 days, e.g. 14-day CGM with offsets +0D..+15D):
  # apply the same clock windows to EVERY calendar day instead of only
  # Day 1 / Day 2. Short recordings keep the original two-day behaviour.
  multi_day <- length(time_values) > 0 && max(time_values) >= 3 * 24 * 60
  if (multi_day) {
    day_clock_s <- d1_day_start
    night_clock_s <- d1_night_start
    # +1 day: the sensor may be worn from the first evening, so the windows
    # extend one extra day to complete the final night through the next
    # morning (relevant for full-axis edge clamping).
    max_day <- max(time_values) %/% (24 * 60) + 1
    day_idx <- integer(0)
    night_idx <- which(time_values < day_clock_s) # pre-day-0 night
    for (k in 0:max_day) {
      base <- k * 24 * 60
      day_idx <- c(day_idx, which(time_values >= base + day_clock_s &
                                    time_values < base + night_clock_s))
      night_idx <- c(night_idx, which(time_values >= base + night_clock_s &
                                        time_values < base + 24 * 60 + day_clock_s))
    }
    if (period_key == "day") return(sort(unique(day_idx)))
    if (period_key == "night") return(sort(unique(night_idx)))
    return(integer(0))
  }

  if (period_key == "day") {
    return(which((time_values >= d1_day_start & time_values < d1_night_start) |
                   (time_values >= d2_day_start & time_values < d2_night_start)))
  }
  if (period_key == "night") {
    return(which(time_values < d1_day_start |
                   (time_values >= d1_night_start & time_values < d2_day_start)))
  }
  integer(0)
}""",
label="individual_period_indices multi-day")

helpers_after_series = rep(helpers_after_series,
"""individual_period_indices <- function(time_values, period_key,
                                      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                      day_start2_h, day_start2_m, night_start2_h, night_start2_m) {""",
"""individual_period_indices <- function(time_values, period_key,
                                      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                      day_start2_h, day_start2_m, night_start2_h, night_start2_m,
                                      multi_day = NULL) {""",
label="individual_period_indices multi_day param")
helpers_after_series = rep(helpers_after_series,
"""  multi_day <- length(time_values) > 0 && max(time_values) >= 3 * 24 * 60""",
"""  multi_day <- isTRUE(multi_day) || (length(time_values) > 0 && max(time_values) >= 3 * 24 * 60)""",
label="individual_period_indices multi_day logic")

# Analysis-window day/night segmentation: replace the fixed Day1/Day2 (0-3D)
# classification with a repeating daily pattern anchored at recording day 0
# (day 0 uses the Day-1 clocks, later days use the Day-2 clocks). This covers
# any window span - a window starting on day 1/2 or crossing several days is
# segmented correctly instead of yielding empty day/night periods.
helpers_after_series = rep(helpers_after_series,
"""  multi_day <- isTRUE(multi_day) || (length(time_values) > 0 && max(time_values) >= 3 * 24 * 60)
  if (multi_day) {
    day_clock_s <- d1_day_start
    night_clock_s <- d1_night_start
    # +1 day: the sensor may be worn from the first evening, so the windows
    # extend one extra day to complete the final night through the next
    # morning (relevant for full-axis edge clamping).
    max_day <- max(time_values) %/% (24 * 60) + 1
    day_idx <- integer(0)
    night_idx <- which(time_values < day_clock_s) # pre-day-0 night
    for (k in 0:max_day) {
      base <- k * 24 * 60
      day_idx <- c(day_idx, which(time_values >= base + day_clock_s &
                                    time_values < base + night_clock_s))
      night_idx <- c(night_idx, which(time_values >= base + night_clock_s &
                                        time_values < base + 24 * 60 + day_clock_s))
    }
    if (period_key == "day") return(sort(unique(day_idx)))
    if (period_key == "night") return(sort(unique(night_idx)))
    return(integer(0))
  }

  if (period_key == "day") {
    return(which((time_values >= d1_day_start & time_values < d1_night_start) |
                   (time_values >= d2_day_start & time_values < d2_night_start)))
  }
  if (period_key == "night") {
    return(which(time_values < d1_day_start |
                   (time_values >= d1_night_start & time_values < d2_day_start)))
  }
  integer(0)
}""",
"""  d2_day_clock <- d2_day_start - 24 * 60
  d2_night_clock <- d2_night_start - 24 * 60
  max_day <- if (length(time_values) > 0) max(time_values) %/% (24 * 60) else 0
  day_idx <- integer(0)
  night_idx <- which(time_values < d1_day_start) # night before the first day segment
  for (k in 0:max_day) {
    base <- k * 24 * 60
    ds <- if (k == 0) d1_day_start else d2_day_clock
    ns <- if (k == 0) d1_night_start else d2_night_clock
    day_idx <- c(day_idx, which(time_values >= base + ds & time_values < base + ns))
    night_idx <- c(night_idx, which(time_values >= base + ns &
                                      time_values < base + 24 * 60 + d2_day_clock))
  }
  if (period_key == "day") return(sort(unique(day_idx)))
  if (period_key == "night") return(sort(unique(night_idx)))
  integer(0)
}""",
label="individual_period_indices window pattern")

# Segmented-data view follows the same repeating day/night pattern.
helpers_wide = rep(helpers_wide,
"""  # Define time boundaries in total minutes from the start (00:00+0D)
  d1_day_start_min   <- day_start1_h * 60 + day_start1_m
  d1_night_start_min <- night_start1_h * 60 + night_start1_m
  d2_day_start_min   <- (24 * 60) + (day_start2_h * 60 + day_start2_m)
  d2_night_start_min <- (24 * 60) + (night_start2_h * 60 + night_start2_m)
  
  # Define PERIOD ENDS (exclusive of the next start time)
  d0_night_end_min   <- d1_day_start_min
  d1_day_end_min     <- d1_night_start_min
  d1_night_end_min   <- d2_day_start_min
  d2_day_end_min     <- d2_night_start_min
  
  # Get indices for each period based on sorted_minutes
  cols_idx_d0_night <- which(sorted_minutes < d0_night_end_min)
  cols_idx_d1_day   <- which(sorted_minutes >= d1_day_start_min & sorted_minutes < d1_day_end_min)
  cols_idx_d1_night <- which(sorted_minutes >= d1_night_start_min & sorted_minutes < d1_night_end_min)
  cols_idx_d2_day   <- which(sorted_minutes >= d2_day_start_min & sorted_minutes < d2_day_end_min)""",
"""  # Define time boundaries in total minutes from the start (00:00+0D)
  d1_day_start_min   <- day_start1_h * 60 + day_start1_m
  d1_night_start_min <- night_start1_h * 60 + night_start1_m
  d2_day_clock       <- day_start2_h * 60 + day_start2_m
  d2_night_clock     <- night_start2_h * 60 + night_start2_m

  # Repeating daily pattern (same rule as the metric pipeline): day 0 uses the
  # Day-1 clocks and every later day uses the Day-2 clocks, so the segmented
  # columns follow the analysis window instead of a fixed Day1/Day2 layout.
  max_day <- if (length(sorted_minutes) > 0) max(sorted_minutes) %/% (24 * 60) else 0
  cols_idx_d0_night <- which(sorted_minutes < d1_day_start_min)
  cols_idx_d1_day   <- which(sorted_minutes >= d1_day_start_min & sorted_minutes < d1_night_start_min)
  cols_idx_d1_night <- which(sorted_minutes >= d1_night_start_min &
                               sorted_minutes < 24 * 60 + d2_day_clock)
  cols_idx_d2_day   <- integer(0)
  if (max_day >= 1) {
    for (k in 1:max_day) {
      base <- k * 24 * 60
      cols_idx_d2_day <- c(cols_idx_d2_day,
                           which(sorted_minutes >= base + d2_day_clock &
                                   sorted_minutes < base + d2_night_clock))
      cols_idx_d1_night <- c(cols_idx_d1_night,
                             which(sorted_minutes >= base + d2_night_clock &
                                     sorted_minutes < base + 24 * 60 + d2_day_clock))
    }
  }""",
label="split_wide_data_day_night window pattern")


# GLU joins the metric family everywhere
helpers_wide = rep(helpers_wide,
    'metrics <- c("SBP", "DBP", "HR", "PP", "MAP")',
    'metrics <- c("SBP", "DBP", "HR", "PP", "MAP", "GLU")',
    label="wide metrics add GLU")
region_D = rep(region_D,
"""calculate_abpm_metrics_for_period_individual <- function(metric_patient_series, period_key,
                                                         upper_limit, lower_limit,
                                                         day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                         day_start2_h, day_start2_m, night_start2_h, night_start2_m) {""",
"""calculate_abpm_metrics_for_period_individual <- function(metric_patient_series, period_key,
                                                         upper_limit, lower_limit,
                                                         day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                         day_start2_h, day_start2_m, night_start2_h, night_start2_m,
                                                         vim_mode = "cohort", vim_ref_mean = 100) {""",
label="region_D for_period signature")

region_D = rep(region_D,
"""calculate_abpm_metrics_without_limits_individual <- function(metric_patient_series, period_key,
                                                              day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                              day_start2_h, day_start2_m, night_start2_h, night_start2_m) {""",
"""calculate_abpm_metrics_without_limits_individual <- function(metric_patient_series, period_key,
                                                              day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                              day_start2_h, day_start2_m, night_start2_h, night_start2_m,
                                                              vim_mode = "cohort", vim_ref_mean = 100) {""",
label="region_D without_limits signature")

region_D = rep(region_D,
"""calculate_abpm_metrics_24h_segmented_individual <- function(individual_series,
                                                            targets_day, targets_night,
                                                            day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                            day_start2_h, day_start2_m, night_start2_h, night_start2_m) {""",
"""calculate_abpm_metrics_24h_segmented_individual <- function(individual_series,
                                                            targets_day, targets_night,
                                                            day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                            day_start2_h, day_start2_m, night_start2_h, night_start2_m,
                                                            vim_mode = "cohort", vim_ref_mean = 100) {""",
label="region_D segmented signature")

# The engine reports both "SD" (standard deviation) and "Sd" (total area,
# identical to AUC). Excel column names are case-insensitive, so openxlsx
# rejects the pair. Drop the redundant "Sd" output column (AUC carries the
# same value); internal calculations keep using Sd untouched.
region_D = rep_all(region_D,
                   '"Sa", "Sc", "Sd", "AUC",',
                   '"Sa", "Sc", "AUC",',
                   min_count=3, label="drop Sd output column")

region_D = rep(region_D,
                   "results_df <- add_vim_from_observed_results(results_df)",
                   "results_df <- add_vim_from_observed_results(results_df, vim_mode = vim_mode, vim_ref_mean = vim_ref_mean)",
                   count=1, label="region_D for_period add_vim call")
region_D = rep(region_D,
               "results_df <- add_vim_from_observed_results(bind_rows(all_results))",
               "results_df <- add_vim_from_observed_results(bind_rows(all_results), vim_mode = vim_mode, vim_ref_mean = vim_ref_mean)",
               label="region_D without_limits add_vim call")
region_D = rep(region_D,
               "result_df <- add_vim_from_observed_results(bind_rows(patient_results))",
               "result_df <- add_vim_from_observed_results(bind_rows(patient_results), vim_mode = vim_mode, vim_ref_mean = vim_ref_mean)",
               label="region_D segmented add_vim call")

region_D = rep_all(region_D,
                   "vim_mode = \"cohort\", vim_ref_mean = 100) {",
                   "vim_mode = \"cohort\", vim_ref_mean = 100,\n      multi_day = FALSE) {",
                   min_count=3, label="region_D add multi_day param")
region_D = rep_all(region_D,
"""      day_start2_h, day_start2_m, night_start2_h, night_start2_m
    )""",
"""      day_start2_h, day_start2_m, night_start2_h, night_start2_m,
      multi_day = multi_day
    )""",
min_count=4, label="region_D pass multi_day (interp/raw calls)")
region_D = rep_all(region_D,
"""day_start2_h, day_start2_m, night_start2_h, night_start2_m)""",
"""day_start2_h, day_start2_m, night_start2_h, night_start2_m, multi_day = multi_day)""",
min_count=4, label="region_D pass multi_day (segmented calls)")

# The segmented PP/MAP fallback must honour the selected VIM mode instead of
# silently using the cohort default (single-patient cohorts then get NA VIM).
region_D = rep(region_D,
"""      results_df <- calculate_abpm_metrics_without_limits_individual(
        individual_series[[metric]], "24h",
        day_start1_h, day_start1_m, night_start1_h, night_start1_m,
        day_start2_h, day_start2_m, night_start2_h, night_start2_m
      )""",
"""      results_df <- calculate_abpm_metrics_without_limits_individual(
        individual_series[[metric]], "24h",
        day_start1_h, day_start1_m, night_start1_h, night_start1_m,
        day_start2_h, day_start2_m, night_start2_h, night_start2_m,
        vim_mode = vim_mode, vim_ref_mean = vim_ref_mean
      )""",
label="region_D segmented PP/MAP pass VIM mode")

# Area/time metrics must only join ADJACENT axis points into trapezoids. The
# per-period selections are non-contiguous (e.g. day = morning + afternoon
# around a night), so the selected points are split into contiguous runs and
# each run is integrated separately, then summed. Without this, the last point
# of one segment and the first point of the next form a phantom trapezoid
# spanning the whole complementary period, which double-counts day/night time.
region_D = rep(region_D,
"""calculate_abpm_metrics_for_period_individual <- function(metric_patient_series, period_key,""",
"""calculate_areas_times_runs <- function(row_data, time_points, idx_positions,
                                       region_b_upper, region_b_lower) {
  row_data <- as.numeric(row_data)
  time_points <- as.numeric(time_points)
  idx_positions <- as.integer(idx_positions)
  idx_positions <- idx_positions[is.finite(row_data[idx_positions]) &
                                   is.finite(time_points[idx_positions])]
  if (length(idx_positions) == 0) {
    return(list(
      Sa = if (is.finite(region_b_upper)) 0 else NA_real_,
      Sc = if (is.finite(region_b_lower)) 0 else NA_real_,
      Sd = 0, AUC = 0, Ts1_total = 0, Ts2_total = 0, Ts3_total = 0))
  }
  run_id <- cumsum(c(TRUE, diff(idx_positions) > 1))
  acc <- list(Sa = 0, Sc = 0, Sd = 0, Ts1_total = 0, Ts2_total = 0, Ts3_total = 0)
  for (r in unique(run_id)) {
    sel <- which(run_id == r)
    pos <- idx_positions[sel]
    # Extend the run by the immediately following axis point so the partial
    # interval up to the next day/night boundary is attributed to this period
    # exactly once (the complementary period's own run starts at that same
    # point, so the axis is partitioned without gaps or overlaps).
    nxt <- max(pos) + 1L
    if (nxt <= length(row_data)) pos <- c(pos, nxt)
    sub <- calculate_areas_times_single_row(
      row_data[pos], time_points[pos],
      region_b_upper, region_b_lower)
    acc$Sa <- acc$Sa + sub$Sa
    acc$Sc <- acc$Sc + sub$Sc
    acc$Sd <- acc$Sd + sub$Sd
    acc$Ts1_total <- acc$Ts1_total + sub$Ts1_total
    acc$Ts2_total <- acc$Ts2_total + sub$Ts2_total
    acc$Ts3_total <- acc$Ts3_total + sub$Ts3_total
  }
  if (!is.finite(region_b_upper)) acc$Sa <- NA_real_
  if (!is.finite(region_b_lower)) acc$Sc <- NA_real_
  acc$AUC <- acc$Sd
  acc
}

calculate_abpm_metrics_for_period_individual <- function(metric_patient_series, period_key,""",
label="region_D add run-aware area helper")

region_D = rep(region_D,
"""    area_time_res <- calculate_areas_times_single_row(
      interp$Value[interp_idx], interp$Total_Minutes[interp_idx], upper_limit, lower_limit
    )""",
"""    area_time_res <- calculate_areas_times_runs(
      interp$Value, interp$Total_Minutes, interp_idx, upper_limit, lower_limit
    )""",
label="region_D for_period run-aware area")

region_D = rep(region_D,
"""    auc_res <- calculate_areas_times_single_row(
      interp$Value[interp_idx], interp$Total_Minutes[interp_idx], NA_real_, NA_real_
    )""",
"""    auc_res <- calculate_areas_times_runs(
      interp$Value, interp$Total_Minutes, interp_idx, NA_real_, NA_real_
    )""",
label="region_D without_limits run-aware area")

region_D = rep(region_D,
"""      day_area <- if (length(day_i) >= 2) {
        calculate_areas_times_single_row(interp$Value[day_i], interp$Total_Minutes[day_i],
                                         day_limits$upper, day_limits$lower)
      } else zero_area
      night_area <- if (length(night_i) >= 2) {
        calculate_areas_times_single_row(interp$Value[night_i], interp$Total_Minutes[night_i],
                                         night_limits$upper, night_limits$lower)
      } else zero_area""",
"""      day_area <- calculate_areas_times_runs(
        interp$Value, interp$Total_Minutes, day_i, day_limits$upper, day_limits$lower)
      night_area <- calculate_areas_times_runs(
        interp$Value, interp$Total_Minutes, night_i, night_limits$upper, night_limits$lower)""",
label="region_D segmented run-aware area")


# ------------------------------------------------- patches on region_charts (bilingual charts)
region_charts = rep(region_charts,
    'labs(title = NULL, x = "时间点", y = paste(metric_name, "值")) + # Simpler X axis title',
    'labs(title = NULL, x = chart_tr("axis_time"), y = paste(metric_name, chart_tr("axis_value"), "(", metric_unit(metric_name), ")")) + # Simpler X axis title',
    label="chart1 axis labels with unit")
region_charts = rep(region_charts,
    'labs(title = NULL, x = "时间点", y = paste(metric_name, "值")) +',
    'labs(title = NULL, x = chart_tr("axis_time"), y = paste(metric_name, chart_tr("axis_value"), "(", metric_unit(metric_name), ")")) +',
    label="chart24h axis labels with unit")
region_charts = rep_all(region_charts,
    'paste("时间:", plot_data$TimeLabelHover, "<br>", metric_name, ":", round(plot_data$Value, 1))',
    'paste(chart_tr("axis_time"), ":", plot_data$TimeLabelHover, "<br>", metric_name, ":", round(plot_data$Value, 1))',
    min_count=2, label="hover text")
region_charts = rep(region_charts,
    'text = paste("上限:", upper_limit),',
    'text = paste(chart_tr("upper"), ":", upper_limit),',
    label="upper annotation")
region_charts = rep(region_charts,
    'text = paste("下限:", lower_limit),',
    'text = paste(chart_tr("lower"), ":", lower_limit),',
    label="lower annotation")

region_charts = rep(region_charts,
"""  data <- data.frame(
    category = factor(c("在目标范围", "高于目标范围", "低于目标范围"), levels = c("在目标范围", "高于目标范围", "低于目标范围")),
    value = c(ttr, totr, tutr)
  )""",
"""  cat_labels <- c(chart_tr("in_range"), chart_tr("over_range"), chart_tr("below_range"))
  data <- data.frame(
    category = factor(cat_labels, levels = cat_labels),
    value = c(ttr, totr, tutr)
  )""",
label="donut categories")
region_charts = rep(region_charts,
    'color_map <- c("在目标范围" = "#4CAF50", "高于目标范围" = "#F44336", "低于目标范围" = "#1565C0")',
    'color_map <- setNames(c("#4CAF50", "#F44336", "#1565C0"), cat_labels)',
    label="donut colors")

region_charts = rep(region_charts,
    'category = factor(c("升高负担", "偏低负担"), levels = c("升高负担", "偏低负担")),',
    'category = factor(c(chart_tr("burden_hyper"), chart_tr("burden_hypo")),\n                    levels = c(chart_tr("burden_hyper"), chart_tr("burden_hypo"))),',
    label="burden categories")
region_charts = rep(region_charts,
    'bar_colors <- c("升高负担" = "#D32F2F", "偏低负担" = "#1A237E")',
    'bar_colors <- setNames(c("#D32F2F", "#1A237E"), c(chart_tr("burden_hyper"), chart_tr("burden_hypo")))',
    label="burden colors")
region_charts = rep(region_charts,
    'yaxis = list(title = "负担 (%)",',
    'yaxis = list(title = chart_tr("axis_burden"),',
    label="burden yaxis")

region_charts = rep(region_charts,
    "name = '患者', # Legend entry for Patient",
    "name = chart_tr('label_patient'), # Legend entry for Patient",
    label="variability patient legend")
region_charts = rep(region_charts,
    "name = '参考', # Legend entry for Reference",
    "name = chart_tr('ref_label'), # Legend entry for Reference",
    label="variability ref legend")
region_charts = rep(region_charts,
    "legend = list(title=list(text='指标类型'),",
    "legend = list(title=list(text=chart_tr('label_metric')),",
    label="variability legend title")
region_charts = rep(region_charts,
    'yaxis = list(title = "指标值",',
    'yaxis = list(title = paste(chart_tr("axis_value"), "(", metric_unit(metric_name), ")"),',
    label="variability yaxis with unit")

# ------------------------------------------------- patches on the kept server region
S = server_rest

# remove duplicated input-tab renderers (now provided by part 10)
S = rep(S, '  output$data_source_title <- renderText({ paste("当前数据预览 (来源:", values$data_source_msg, ")") })\n', "",
        label="remove old data_source_title")
S = rep(S, '  output$raw_data_table <- renderDT({ req(values$raw_data_input); datatable(head(values$raw_data_input, 200), caption="原始输入数据预览 (最多显示200行)", options = list(scrollX = TRUE, pageLength = 5, lengthMenu = c(5, 10, 20)), rownames = FALSE) })\n', "",
        label="remove old raw_data_table")

S = rep(S, 'caption="处理和验证后的长格式数据"',
        'caption = chart_tr("caption_prepared")', label="prepared caption")
S = rep(S, 'return(p("没有可显示的宽格式数据。"))',
        'return(p(chart_tr("no_wide_data")))', label="wide empty msg")
S = rep(S, 'caption = paste0("宽格式数据 (插补前) - ", metric)',
        'caption = paste0(chart_tr("caption_wide"), metric)', label="wide caption")
S = rep(S, 'return(p("没有可显示的插补后宽格式数据。"))',
        'return(p(chart_tr("no_interp_data")))', label="interp empty msg")
S = rep(S, 'caption = paste0("插补后宽格式数据 (原始时间) - ", metric)',
        'caption = paste0(chart_tr("caption_interp"), metric)', label="interp caption")
S = rep(S, 'return(p("没有可显示的24小时整体插补后数据。"))',
        'return(p(chart_tr("no_interp_data")))', label="full interp empty msg")
S = rep(S, 'caption = paste0("24h 整体插补数据 - ", metric)',
        'caption = paste0(chart_tr("caption_full_interp"), metric)', label="full interp caption")
S = rep(S, 'return(p(paste("没有", period_name, "时段的数据。")))',
        'return(p(paste(chart_tr("no_split_data"), ":", period_name)))', label="split empty msg")

# show GLU target ranges in the results subtabs too
S = rep(S, '      metrics <- c("SBP", "DBP", "HR", "PP", "MAP")',
        '      metrics <- c("SBP", "DBP", "HR", "PP", "MAP", "GLU")',
        label="target range display add GLU (generic)")
S = rep(S, '    metrics <- c("SBP", "DBP", "HR", "PP", "MAP")',
        '    metrics <- c("SBP", "DBP", "HR", "PP", "MAP", "GLU")',
        label="target range display add GLU (combined)")

# viz summary header: unit for the 24h mean (converts the label too)
S = rep(S,
        'tags$strong("24h(统一) 均值: "), format_num(mean_val), " | ", # Clarified source',
        'tags$strong(chart_tr("label_mean_24h")), paste0(format_num(mean_val), " ", metric_unit(data$metric_id)), " | ",',
        label="viz header mean label + unit")

# viz info cards: unit for SD/ARV
S = rep(S,
        'sd_str <- format_num(sd_val); arv_str <- format_num(arv_val)',
        'sd_str <- paste0(format_num(sd_val), " ", metric_unit(data$metric_id))\n      arv_str <- paste0(format_num(arv_val), " ", metric_unit(data$metric_id))',
        label="viz info SD/ARV units")

# ---- replace the Process Data observer with a pipeline function + window logic
new_process_block = '''  # --- Data Processing Logic (pipeline function + analysis-window check) ---
  run_process_pipeline <- function(win_args, edge_rule) {
    reset_pipeline_state()
    req(values$raw_data_input)

    d1s_h <- input$day1_start_h; d1s_m <- input$day1_start_m
    d1n_h <- input$day1_night_start_h; d1n_m <- input$day1_night_start_m
    d2s_h <- input$day2_start_h; d2s_m <- input$day2_start_m
    d2n_h <- input$day2_night_start_h; d2n_m <- input$day2_night_start_m

    time_inputs_h <- c(d1s_h, d1n_h, d2s_h, d2n_h)
    time_inputs_m <- c(d1s_m, d1n_m, d2s_m, d2n_m)
    if(any(sapply(time_inputs_h, function(x) !is.numeric(x) || is.na(x) || x < 0 || x > 23 || x != floor(x) )) ||
       any(sapply(time_inputs_m, function(x) !is.numeric(x) || is.na(x) || x < 0 || x > 59 || x != floor(x) ))) {
      error_msg <- chart_tr("err_time_inputs")
      showNotification(error_msg, type="error", duration=7)
      values$processing_error <- error_msg
      return()
    }
    d1_start_total_min = d1s_h * 60 + d1s_m
    d1_night_start_total_min = d1n_h * 60 + d1n_m
    d2_start_total_min_in_day = d2s_h * 60 + d2s_m
    d2_night_start_total_min_in_day = d2n_h * 60 + d2n_m
    if (d1_night_start_total_min == d1_start_total_min || d2_night_start_total_min_in_day == d2_start_total_min_in_day) {
      showNotification(chart_tr("warn_daynight_same"), type="warning", duration=7)
    }

    shinyjs::disable("process_data_btn")
    shinyjs::disable("calculate_metrics_btn")
    shinyjs::disable("save_custom_targets_btn")

    withProgress(message = chart_tr('progress_data'), value = 0, {
      tryCatch({
        incProgress(0.1, detail = chart_tr("progress_prepare"))
        long_prep <- load_and_prepare_data(values$raw_data_input, lang = lang())
        present_metrics <- intersect(c("SBP", "DBP", "HR", "PP", "MAP", "GLU"), colnames(long_prep))
        if (length(present_metrics) == 0) stop(tr(lang(), "err_no_metrics_process"))
        if (is.null(long_prep) || !is.data.frame(long_prep) || nrow(long_prep) == 0) stop(chart_tr("err_prepare_empty"))
        values$prepared_long_data <- long_prep
        incProgress(0.2, detail = "OK")

        incProgress(0.1, detail = chart_tr("progress_wide"))
        wide_result <- create_wide_data_per_metric(values$prepared_long_data,
                                                   d1s_h, d1s_m, d1n_h, d1n_m,
                                                   d2s_h, d2s_m, d2n_h, d2n_m)
        values$wide_dfs <- wide_result$wide_dfs
        if (length(values$wide_dfs) == 0) stop(chart_tr("err_wide_empty"))
        incProgress(0.2, detail = "OK")

        incProgress(0.1, detail = chart_tr("progress_axis"))
        values$individual_series <- create_individual_patient_series(
          values$prepared_long_data,
          d1s_h, d1s_m, d1n_h, d1n_m,
          d2s_h, d2s_m, d2n_h, d2n_m,
          interp_mode = isolate(input$interp_mode),
          window_mode = win_args$window_mode,
          window_hours = win_args$window_hours,
          window_start_spec = win_args$window_start_spec,
          window_end_spec = win_args$window_end_spec,
          edge_rule = edge_rule
        )
        if (length(values$individual_series) == 0) stop(chart_tr("err_interp_empty"))
        individual_wide <- individual_series_to_wide(values$individual_series)
        values$interpolated_dfs <- individual_wide$wide_dfs
        values$sorted_times <- individual_wide$sorted_times
        values$sorted_minutes <- individual_wide$sorted_minutes
        if (length(values$interpolated_dfs) == 0) stop(chart_tr("err_interp_empty"))
        incProgress(0.2, detail = "OK")

        incProgress(0.1, detail = chart_tr("progress_split"))
        split_result_wide <- split_wide_data_day_night(values$interpolated_dfs, values$sorted_times, values$sorted_minutes,
                                                       d1s_h, d1s_m, d1n_h, d1n_m,
                                                       d2s_h, d2s_m, d2n_h, d2n_m)
        values$split_data_wide <- split_result_wide
        incProgress(0.1, detail = "OK")

        values$data_processed_successfully <- TRUE
        values$processing_error <- NULL
        shinyjs::enable("calculate_metrics_btn")
        shinyjs::enable("save_custom_targets_btn")
        showNotification(chart_tr("process_done"), type = "message", duration = 5)
        updateTabsetPanel(session, "main_tabset", selected = "processed_data_tab")
      }, error = function(e) {
        values$processing_error <- e$message
        values$data_processed_successfully <- FALSE
        showNotification(paste(chart_tr("process_fail"), ":", e$message), type = "error", duration = NULL)
        values$prepared_long_data <- NULL; values$wide_dfs <- list(); values$individual_series <- list(); values$interpolated_dfs <- list();
        values$split_data_wide <- list();
        shinyjs::disable("calculate_metrics_btn")
        shinyjs::disable("save_custom_targets_btn")
      }, finally = {
        shinyjs::enable("process_data_btn")
      })
    })
  }

  observeEvent(input$process_data_btn, {
    win_args <- list(
      window_mode = isolate(input$window_mode) %||% "from_first",
      window_hours = isolate(input$window_hours) %||% 24,
      window_start_spec = NULL,
      window_end_spec = NULL
    )
    if (win_args$window_mode %in% c("from_start", "custom")) {
      s0 <- isolate(input$window_start_spec) %||% ""
      start_min <- suppressWarnings(time_string_to_minutes(trimws(s0)))
      if (is.na(start_min)) {
        showNotification(chart_tr("err_window_spec"), type = "error", duration = 7)
        return()
      }
      win_args$window_start_spec <- start_min
    }
    if (win_args$window_mode == "custom") {
      e0 <- isolate(input$window_end_spec) %||% ""
      end_min <- suppressWarnings(time_string_to_minutes(trimws(e0)))
      start_min_ok <- if (!is.null(win_args$window_start_spec)) win_args$window_start_spec else -Inf
      if (is.na(end_min) || end_min <= start_min_ok) {
        showNotification(chart_tr("err_window_spec"), type = "error", duration = 7)
        return()
      }
      win_args$window_end_spec <- end_min
    }

    # endpoint check: a specified start/end point without an exact reading
    # asks the user which endpoint interpolation logic to apply
    needs_modal <- FALSE
    if (win_args$window_mode %in% c("from_start", "custom")) {
      req(values$raw_data_input)
      long_check <- tryCatch(load_and_prepare_data(values$raw_data_input, lang = lang()),
                             error = function(e) NULL)
      if (!is.null(long_check)) {
        obs_times <- unique(long_check$Total_Minutes[is.finite(long_check$Total_Minutes)])
        pts <- c(win_args$window_start_spec, win_args$window_end_spec)
        pts <- pts[!vapply(pts, is.null, logical(1))]
        if (length(pts) > 0 && length(obs_times) > 0 &&
            any(!(pts %in% obs_times))) needs_modal <- TRUE
      }
    }
    values$pending_window_args <- win_args
    if (needs_modal) {
      showModal(modalDialog(
        title = tr(lang(), "edge_modal_title"),
        tr(lang(), "edge_modal_text"),
        radioButtons("edge_rule_choice", NULL,
                     choiceNames = list(tr(lang(), "edge_linear"),
                                        tr(lang(), "edge_nearest"),
                                        tr(lang(), "edge_none")),
                     choiceValues = list("linear", "nearest", "none"),
                     selected = values$edge_rule),
        footer = tagList(
          modalButton(tr(lang(), "edge_cancel")),
          actionButton("edge_rule_ok", tr(lang(), "edge_ok"), class = "btn-primary")
        )
      ))
      return()
    }
    run_process_pipeline(win_args, values$edge_rule)
  })

  observeEvent(input$edge_rule_ok, {
    values$edge_rule <- isolate(input$edge_rule_choice) %||% "linear"
    removeModal()
    run_process_pipeline(values$pending_window_args, values$edge_rule)
  }, ignoreInit = TRUE)

'''

# Show the HEAD and the TAIL (first 50 + last 50 time columns) so both the
# start and the end of the recording can be visually verified.
S = rep(S,
"""      output[[paste0("wide_", tolower(metric), "_table")]] <- renderDT({
        req(values$wide_dfs[[metric]])
        datatable(values$wide_dfs[[metric]], caption = paste0(chart_tr("caption_wide"), metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
      })""",
"""      output[[paste0("wide_", tolower(metric), "_table")]] <- renderDT({
        req(values$wide_dfs[[metric]])
        full_df <- values$wide_dfs[[metric]]
        if (ncol(full_df) > 101) {
          keep_cols <- unique(c(1, 2:51, (ncol(full_df) - 49):ncol(full_df)))
          shown_df <- full_df[, keep_cols, drop = FALSE]
          cap_note <- paste0(" [head & tail shown: first 50 and last 50 of ", ncol(full_df) - 1, " time columns; use Export for the full table]")
        } else {
          shown_df <- full_df
          cap_note <- ""
        }
        datatable(shown_df, caption = paste0(chart_tr("caption_wide"), metric, cap_note), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter = 'top')
      })""",
label="cap wide display table (head+tail)")
S = rep(S,
"""      output[[paste0("interp_", tolower(metric), "_table")]] <- renderDT({
        req(values$interpolated_dfs[[metric]])
        datatable(values$interpolated_dfs[[metric]], caption = paste0(chart_tr("caption_interp"), metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
      })""",
"""      output[[paste0("interp_", tolower(metric), "_table")]] <- renderDT({
        req(values$interpolated_dfs[[metric]])
        full_df <- values$interpolated_dfs[[metric]]
        if (ncol(full_df) > 101) {
          keep_cols <- unique(c(1, 2:51, (ncol(full_df) - 49):ncol(full_df)))
          shown_df <- full_df[, keep_cols, drop = FALSE]
          cap_note <- paste0(" [head & tail shown: first 50 and last 50 of ", ncol(full_df) - 1, " time columns; use Export for the full table]")
        } else {
          shown_df <- full_df
          cap_note <- ""
        }
        datatable(shown_df, caption = paste0(chart_tr("caption_interp"), metric, cap_note), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter = 'top')
      })""",
label="cap interp display table (head+tail)")
S = rep(S,
"""      output[[output_id]] <- renderDT({
        req(values$interpolated_dfs[[metric]])
        datatable(values$interpolated_dfs[[metric]], caption = paste0(chart_tr("caption_full_interp"), metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
      })""",
"""      output[[output_id]] <- renderDT({
        req(values$interpolated_dfs[[metric]])
        full_df <- values$interpolated_dfs[[metric]]
        if (ncol(full_df) > 101) {
          keep_cols <- unique(c(1, 2:51, (ncol(full_df) - 49):ncol(full_df)))
          shown_df <- full_df[, keep_cols, drop = FALSE]
          cap_note <- paste0(" [head & tail shown: first 50 and last 50 of ", ncol(full_df) - 1, " time columns; use Export for the full table]")
        } else {
          shown_df <- full_df
          cap_note <- ""
        }
        datatable(shown_df, caption = paste0(chart_tr("caption_full_interp"), metric, cap_note), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter = 'top')
      })""",
label="cap full-interp display table (head+tail)")
S = rep(S,
"""            output[[output_id]] <- renderDT({
              req(values$split_data_wide[[current_period]][[current_metric]])
              period_title <- switch(current_period, "day0_night" = "Day 0 Night", "day1_day" = "Day 1 Day", "day1_night" = "Day 1 Night", "day2_day" = "Day 2 Day", current_period)
              datatable(values$split_data_wide[[current_period]][[current_metric]], caption = paste0(period_title, " - ", current_metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
            })""",
"""            output[[output_id]] <- renderDT({
              req(values$split_data_wide[[current_period]][[current_metric]])
              period_title <- switch(current_period, "day0_night" = "Day 0 Night", "day1_day" = "Day 1 Day", "day1_night" = "Day 1 Night", "day2_day" = "Day 2 Day", current_period)
              full_df <- values$split_data_wide[[current_period]][[current_metric]]
              if (ncol(full_df) > 101) {
                keep_cols <- unique(c(1, 2:51, (ncol(full_df) - 49):ncol(full_df)))
                shown_df <- full_df[, keep_cols, drop = FALSE]
                cap_note <- paste0(" [head & tail shown: first 50 and last 50 of ", ncol(full_df) - 1, " time columns; use Export for the full table]")
              } else {
                shown_df <- full_df
                cap_note <- ""
              }
              datatable(shown_df, caption = paste0(period_title, " - ", current_metric, cap_note), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter = 'top')
            })""",
label="cap split display table (head+tail)")

# presets
S = rep(S, 'showNotification("时间已预设为：日间 05:00 - 19:59, 夜间 20:00 - 次日 04:59", type = "message")',
        'showNotification(chart_tr("preset_east_msg"), type = "message")', label="preset east msg")
S = rep(S, 'showNotification("时间已预设为：日间 07:00 - 21:59, 夜间 22:00 - 次日 06:59", type = "message")',
        'showNotification(chart_tr("preset_west_msg"), type = "message")', label="preset west msg")

# derived limits warning (console only)
S = rep(S, 'warning("不能计算PP/MAP范围，因为SBP或DBP的上限小于下限。", call. = FALSE)',
        'warning("Cannot derive PP/MAP ranges because an SBP/DBP upper limit is not greater than its lower limit.", call. = FALSE)',
        label="derived limits warning")

# apply_targets observer
S = rep(S, 'showNotification("自定义目标范围已锁定，无法自动更新 PP/MAP。", type = "warning", duration = 5)',
        'showNotification(chart_tr("locked_warn"), type = "warning", duration = 5)',
        count=1, label="locked warn auto")
S = rep(S, 'showNotification("自定义目标范围已锁定，无法应用预设。", type = "warning", duration = 5)',
        'showNotification(chart_tr("locked_warn"), type = "warning", duration = 5)',
        count=1, label="locked warn preset")
S = rep(S, 'period_labels <- c(day = "日间", night = "夜间", `24h` = "24h日夜统一")',
        'period_labels <- c(day = chart_tr("tab_day"), night = chart_tr("tab_night"), `24h` = chart_tr("tab_24h"))',
        label="apply_targets period labels")
S = rep(S, 'paste0("无法自动计算：", period_labels[[period_name]], "的 SBP/DBP 上下限必须全部填写为有效数字。")',
        'paste0(chart_tr("derive_fail_prefix"), " ", period_labels[[period_name]], chart_tr("derive_fail_sbpdbp"))',
        label="derive fail sbpdbp")
S = rep(S, 'paste0("无法自动计算：", period_labels[[period_name]], "的 SBP/DBP 上限必须大于下限。")',
        'paste0(chart_tr("derive_fail_prefix"), " ", period_labels[[period_name]], chart_tr("derive_fail_order"))',
        label="derive fail order")
S = rep(S, '"三套 PP/MAP 范围已根据各自的 SBP/DBP 范围更新；HR范围保持不变。"',
        'chart_tr("derive_msg")', label="derive done")
S = rep(S, '"已应用默认的目标范围 (SBP, DBP, HR, 以及计算出的 PP/MAP)。"',
        'chart_tr("defaults_msg")', label="defaults done")
S = rep(S, '    updateNumericInput(session, "hr_24h_lower", value = 55); updateNumericInput(session, "hr_24h_upper", value = 95)',
        """    updateNumericInput(session, "hr_24h_lower", value = 55); updateNumericInput(session, "hr_24h_upper", value = 95)
    # glucose (CGM) defaults: TIR range 3.9-10.0 mmol/L (ADA / China CDS)
    updateNumericInput(session, "glu_day_lower", value = 3.9); updateNumericInput(session, "glu_day_upper", value = 10.0)
    updateNumericInput(session, "glu_night_lower", value = 3.9); updateNumericInput(session, "glu_night_upper", value = 10.0)
    updateNumericInput(session, "glu_24h_lower", value = 3.9); updateNumericInput(session, "glu_24h_upper", value = 10.0)""",
        label="preset targets add glu defaults")

# save/lock observer
S = rep(S, '"已解除目标范围锁定；当前阈值已保留，可以继续修改、自动计算或应用预设。"',
        'chart_tr("unlock_msg")', label="unlock msg")
S = rep(S, '"自定义目标范围已保存并锁定。计算指标时将使用这份快照。"',
        'chart_tr("lock_msg")', label="lock msg")

# process observer
S = rep(S, 'error_msg <- "错误：日间/夜间 小时(0-23)和分钟(0-59) 必须是有效的整数。"',
        'error_msg <- chart_tr("err_time_inputs")', label="time input err")
S = rep(S, 'showNotification("警告：同一天的日间和夜间开始时间不能相同。请检查时间设置。", type="warning", duration=7)',
        'showNotification(chart_tr("warn_daynight_same"), type="warning", duration=7)', label="daynight same warn")
S = rep(S, "withProgress(message = '处理数据...', value = 0, {",
        "withProgress(message = chart_tr('progress_data'), value = 0, {", label="progress msg")
S = rep(S, 'incProgress(0.1, detail = "数据校验与准备...")',
        'incProgress(0.1, detail = chart_tr("progress_prepare"))', label="progress prepare")
S = rep(S, 'incProgress(0.2, detail = "准备完成")', 'incProgress(0.2, detail = "OK")', label="progress ok1")
S = rep(S, 'incProgress(0.1, detail = "创建宽格式(插补前)...")',
        'incProgress(0.1, detail = chart_tr("progress_wide"))', label="progress wide")
S = rep(S, 'incProgress(0.2, detail = "宽格式(插补前)创建完成")', 'incProgress(0.2, detail = "OK")', label="progress ok2")
S = rep(S, 'incProgress(0.1, detail = "逐患者建立独立时间轴并插补必要边界...")',
        'incProgress(0.1, detail = chart_tr("progress_axis"))', label="progress axis")
S = rep(S, 'incProgress(0.2, detail = "逐患者时间轴处理完成")', 'incProgress(0.2, detail = "OK")', label="progress ok3")
S = rep(S, 'incProgress(0.1, detail = "分割插补后宽数据时段...")',
        'incProgress(0.1, detail = chart_tr("progress_split"))', label="progress split")
S = rep(S, 'incProgress(0.1, detail = "数据分割完成")', 'incProgress(0.1, detail = "OK")', label="progress ok4")
S = rep(S, 'long_prep <- load_and_prepare_data(values$raw_data_input)',
        """long_prep <- load_and_prepare_data(values$raw_data_input, lang = lang())
        present_metrics <- intersect(c("SBP", "DBP", "HR", "PP", "MAP", "GLU"), colnames(long_prep))
        if (length(present_metrics) == 0) stop(tr(lang(), "err_no_metrics_process"))""",
        label="load lang arg + metric presence check")
S = rep(S, 'stop("数据准备步骤未能生成有效数据。")',
        'stop(chart_tr("err_prepare_empty"))', label="prepare empty err")
S = rep(S, 'stop("未能为任何指标创建宽格式数据（插补前）。")',
        'stop(chart_tr("err_wide_empty"))', label="wide empty err")
S = rep(S, 'stop("未能为任何指标生成插补后的宽格式数据。")',
        'stop(chart_tr("err_interp_empty"))', label="interp empty err")
S = rep(S, 'showNotification("数据处理完成！现在可以设置目标范围、锁定自定义范围或计算指标。", type = "message", duration = 5) # Updated message',
        'showNotification(chart_tr("process_done"), type = "message", duration = 5)', label="process done")
S = rep(S, 'showNotification(paste("数据处理失败:", e$message), type = "error", duration = NULL)',
        'showNotification(paste(chart_tr("process_fail"), ":", e$message), type = "error", duration = NULL)',
        label="process fail")
S = rep(S,
"""        values$individual_series <- create_individual_patient_series(
          values$prepared_long_data,
          d1s_h, d1s_m, d1n_h, d1n_m,
          d2s_h, d2s_m, d2n_h, d2n_m
        )""",
"""        values$individual_series <- create_individual_patient_series(
          values$prepared_long_data,
          d1s_h, d1s_m, d1n_h, d1n_m,
          d2s_h, d2s_m, d2n_h, d2n_m,
          interp_mode = isolate(input$interp_mode)
        )""",
        label="series interp_mode arg")

# apply the refactored Process Data observer (replaces the old observer that
# all earlier patches have already transformed; the new block already embeds
# every localized message, the metric-presence check and the window args)
proc_start = "  observeEvent(input$process_data_btn, {"
proc_end = "  # --- Metric Calculation Function (Calculates Day, Night, 24h-unified, AND 24h-segmented) ---"
if proc_start not in S or proc_end not in S:
    raise SystemExit("PATCH FAILED [process observer]: anchors not found")
i_p = S.index(proc_start)
j_p = S.index(proc_end, i_p)
S = S[:i_p] + new_process_block + S[j_p:]

# perform_metric_calculation
S = rep(S, "metrics_to_calculate <- names(values$individual_series)",
        """metrics_to_calculate <- names(values$individual_series)
        vim_mode <- isolate(input$vim_mode) %||% "cohort"
        vim_ref_mean <- isolate(input$vim_ref_mean) %||% 100""",
        label="vim settings read")
S = rep_all(S,
"""              isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
            )""",
"""              isolate(input$day2_night_start_h), isolate(input$day2_night_start_m),
              vim_mode = vim_mode, vim_ref_mean = vim_ref_mean,
              multi_day = tolower(metric) == "glu"
            )""",
min_count=2, label="vim+multi_day args in 24h per-period calls")
S = rep_all(S,
"""                isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
              )""",
"""                isolate(input$day2_night_start_h), isolate(input$day2_night_start_m),
                vim_mode = vim_mode, vim_ref_mean = vim_ref_mean,
                multi_day = tolower(metric) == "glu"
              )""",
min_count=4, label="vim+multi_day args in day/night per-period calls")
S = rep(S,
"""          night_start2_h = isolate(input$day2_night_start_h), night_start2_m = isolate(input$day2_night_start_m)
        )""",
"""          night_start2_h = isolate(input$day2_night_start_h), night_start2_m = isolate(input$day2_night_start_m),
          vim_mode = vim_mode, vim_ref_mean = vim_ref_mean,
          multi_day = "GLU" %in% metrics_to_calculate
        )""",
label="vim+multi_day args in segmented call")
S = rep(S, 'required_target_names <- grep("^(sbp|dbp|hr)_.*_(lower|upper)$", names(all_targets), value = TRUE)',
        'required_target_names <- grep("^(sbp|dbp|hr|glu)_.*_(lower|upper)$", names(all_targets), value = TRUE)',
        label="required targets add glu")
S = rep(S, 'error_msg <- "错误：SBP, DBP, HR 的所有目标范围必须是有效的数字才能计算。";',
        'error_msg <- chart_tr("err_targets_required");', label="targets required err")
S = rep(S, 'error_msg <- "错误：如果 PP/MAP 目标范围被填写，则必须是有效的数字。";',
        'error_msg <- chart_tr("err_targets_optional");', label="targets optional err")
S = rep(S, 'error_msg <- paste0("错误：", optional_pair_validation$message)',
        'error_msg <- optional_pair_validation$message', label="pair validation msg")
S = rep(S,
        'msg <- paste0("错误：", label, " 的目标范围上限 (", upper, ") 必须大于下限 (", lower, ") 才能计算。");',
        'msg <- paste0("Error: ", label, " ", chart_tr("err_limit_order"), " (", upper, ") ", chart_tr("err_limit_order2"), " (", lower, ") ", chart_tr("err_limit_order3"));',
        label="limit order msg")

# rebuild limit_pairs with localized labels
limit_pairs_old_start = """    limit_pairs <- list(
      list(all_targets$sbp_day_lower, all_targets$sbp_day_upper, "白天 SBP")"""
limit_pairs_old_end = """    for (pair in limit_pairs) { if (!check_limits(pair[[1]], pair[[2]], pair[[3]])) { valid_limits <- FALSE; break } }; if (!valid_limits) return()"""
if limit_pairs_old_start not in S:
    raise SystemExit("PATCH FAILED [limit_pairs]: start anchor not found")
if limit_pairs_old_end not in S:
    raise SystemExit("PATCH FAILED [limit_pairs]: end anchor not found")
i1 = S.index(limit_pairs_old_start)
i2 = S.index(limit_pairs_old_end, i1)
new_limit_pairs = """    limit_pairs <- list()
    for (mn in c("sbp", "dbp", "hr", "pp", "map", "glu")) {
      for (pn in c("day", "night", "24h")) {
        limit_pairs[[length(limit_pairs) + 1]] <- list(
          all_targets[[paste0(mn, "_", pn, "_lower")]],
          all_targets[[paste0(mn, "_", pn, "_upper")]],
          paste(period_label(pn), toupper(mn)))
      }
    }
"""
S = S[:i1] + new_limit_pairs + S[i2:]

S = rep(S, 'target_source_text <- if (isTRUE(values$targets_locked)) "已锁定的目标范围快照" else "当前显示的目标范围"',
        'target_source_text <- if (isTRUE(values$targets_locked)) chart_tr("target_snapshot_locked") else chart_tr("target_snapshot_current")',
        label="target source text")
S = rep(S, 'showNotification(paste0("开始计算指标 (使用", target_source_text, ")..."), type = "message", duration = 4)',
        'showNotification(paste0(chart_tr("calc_start"), " [", target_source_text, "]"), type = "message", duration = 4)',
        label="calc start notif")
S = rep(S, "withProgress(message = '计算指标...', value = 0, {",
        "withProgress(message = chart_tr('calc_start'), value = 0, {", label="calc progress msg")
S = rep(S, 'incProgress(0.1, detail = "计算指标（24h日夜统一阈值）...")',
        'incProgress(0.1, detail = chart_tr("progress_calc_24h"))', label="calc p24h")
S = rep(S, 'incProgress(0.1, detail = "计算指标 (白天)...")',
        'incProgress(0.1, detail = chart_tr("progress_calc_day"))', label="calc pday")
S = rep(S, 'incProgress(0.1, detail = "计算指标 (夜晚)...")',
        'incProgress(0.1, detail = chart_tr("progress_calc_night"))', label="calc pnight")
S = rep(S, 'incProgress(0.1, detail = "计算指标（24h日夜分段阈值）...")',
        'incProgress(0.1, detail = chart_tr("progress_calc_seg"))', label="calc pseg")
S = rep(S, 'incProgress(0.1, detail = "完成！")', 'incProgress(0.1, detail = chart_tr("progress_calc_done"))', label="calc pdone")
S = rep(S, 'showNotification("指标计算完成！现在可以进行可视化分析。", type = "message", duration = 5)',
        'showNotification(chart_tr("calc_done"), type = "message", duration = 5)', label="calc done")
S = rep(S, 'showNotification(paste("指标计算失败:", e$message), type = "error", duration = NULL)',
        'showNotification(paste(chart_tr("calc_fail"), ":", e$message), type = "error", duration = NULL)',
        label="calc fail")

# target range displays
S = rep_all(S, 'range_text <- if (!lower_is_num && !upper_is_num) { "未设置"',
        'range_text <- if (!lower_is_num && !upper_is_num) { chart_tr("not_set")',
        min_count=1, label="range not_set")
S = rep_all(S, 'if (!lower_is_num && !upper_is_num) { "未设置"',
        'if (!lower_is_num && !upper_is_num) { chart_tr("not_set")',
        min_count=1, label="format_range not_set")
S = rep(S, 'tags_to_render <- list(tags$p(tags$strong(icon("bullseye"), "本次计算使用的目标范围:")))',
        'tags_to_render <- list(tags$p(tags$strong(icon("bullseye"), chart_tr("targets_used_label"))))',
        label="targets used label")
S = rep(S, 'tags_list <- list(tags$h5(tags$strong("24h（日夜分段阈值）计算使用的日间和夜间目标范围："))) # Clarified title',
        'tags_list <- list(tags$h5(tags$strong(paste0(chart_tr("results_24h_segmented"), " - ", chart_tr("targets_used_label")))))',
        label="combined title")
S = rep_all(S, 'span(" 白天:", style="color: #555;"), tags$code(range_d_text), "; ",',
        'span(paste0(" ", chart_tr("tab_day"), ":"), style="color: #555;"), tags$code(range_d_text), "; ",',
        min_count=1, label="combined day label")
S = rep_all(S, 'span(" 夜晚:", style="color: #555;"), tags$code(range_n_text),',
        'span(paste0(" ", chart_tr("tab_night"), ":"), style="color: #555;"), tags$code(range_n_text),',
        min_count=1, label="combined night label")

# results metric tabs UI
S = rep(S,
"""      period_title <- switch(period_key,
                             "day" = "日间（使用日间阈值）",
                             "night" = "夜间（使用夜间阈值）",
                             "24h" = "24h（日夜统一阈值）",
                             "24h_segmented" = "24h（日夜分段阈值）",
                             period_key) # Fallback
      
      if (length(metrics_available) == 0) {
        return(p(paste("没有计算出", period_title, "时段的有效指标结果 (可能是目标范围未设置或计算出错?)。")))
      }""",
"""      period_title <- switch(period_key,
                             "day" = chart_tr("results_day"),
                             "night" = chart_tr("results_night"),
                             "24h" = chart_tr("results_24h_unified"),
                             "24h_segmented" = chart_tr("results_24h_segmented"),
                             period_key) # Fallback

      if (length(metrics_available) == 0) {
        return(p(paste(chart_tr("no_results_period"), period_title, chart_tr("no_results_period2"))))
      }""",
label="results tabs titles")

# render_dt_table replacement
render_dt_old = """  render_dt_table <- function(data_reactive,caption = NULL) {
    renderDT({
      data_df <- data_reactive()
      if (is.null(data_df) || !is.data.frame(data_df) || nrow(data_df) == 0) {
        display_msg <- if (!is.null(values$calculation_error) && nzchar(values$calculation_error)) paste("指标计算失败:", values$calculation_error) else if (!is.null(values$processing_error) && nzchar(values$processing_error)) paste("数据处理失败:", values$processing_error) else if (is.null(values$raw_data_input)) "没有可显示的数据。请上传文件或使用内置数据。" else if (!values$data_processed_successfully && input$process_data_btn == 0) "请点击 '处理数据' 按钮。" else if (!values$data_processed_successfully) "数据处理步骤未成功完成或未运行。" else if (!values$metrics_calculated_successfully && input$calculate_metrics_btn == 0) "请点击 '计算指标' 按钮生成结果。" else if (!values$metrics_calculated_successfully) "指标计算步骤未成功完成或未运行。" else "此步骤无数据显示或结果为空 (检查目标范围是否已设置)。"
        return(datatable(data.frame(消息 = display_msg), options = list(dom = 't', searching = FALSE, ordering=FALSE), rownames = FALSE))
      }
      cols_to_round <- names(data_df)[sapply(data_df, is.numeric)]; cols_to_round <- setdiff(cols_to_round, "MASKID")
      if(length(cols_to_round) > 0) { tryCatch({ data_df <- data_df %>% mutate(across(where(is.numeric) & !matches("^MASKID$"), ~ round(.x, 2))) }, error = function(e) { warning(paste("Error during rounding columns:", e$message), call.=FALSE) }) }
      filename_default <- "abpm_results"
      if (!is.null(caption)) { filename_default <-gsub("[^A-Za-z0-9_]", "_", caption); filename_default <- gsub("_+", "_", filename_default); filename_default <- sub("^_|_$", "", filename_default); if (nchar(filename_default) == 0) filename_default <- "abpm_data_export" }
      datatable(data_df, caption = caption, extensions = c('Buttons', 'FixedColumns'), options = list(dom = 'Blfrtip', buttons = list(list(extend = 'copy', text = '<i class="fa fa-copy"></i> 复制'), list(extend = 'csv', text = '<i class="fa fa-file-csv"></i> 导出 CSV', filename = filename_default, titleAttr = '导出为CSV文件', bom = TRUE), list(extend = 'excel', text = '<i class="fa fa-file-excel"></i> 导出 Excel', filename = filename_default, titleAttr = '导出为Excel文件')), scrollX = TRUE, pageLength = 10, searchDelay = 500, search = list(regex = TRUE, caseInsensitive = TRUE), lengthMenu = list(c(10, 25, 50, 100, -1), c('10', '25', '50', '100', '全部')), columnDefs = list(list(className = 'dt-center', targets = '_all')), fixedColumns = list(leftColumns = 1), language = list(url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese.json"), processing = TRUE), filter = 'top', rownames = FALSE, class = 'cell-border stripe compact hover nowrap', escape = FALSE)
    })
  }"""
render_dt_new = """  render_dt_table <- function(data_reactive, caption = NULL) {
    renderDT({
      data_df <- data_reactive()
      if (is.null(data_df) || !is.data.frame(data_df) || nrow(data_df) == 0) {
        display_msg <- if (!is.null(values$calculation_error) && nzchar(values$calculation_error)) {
          paste(chart_tr("calc_fail"), ":", values$calculation_error)
        } else if (!is.null(values$processing_error) && nzchar(values$processing_error)) {
          paste(chart_tr("process_fail"), ":", values$processing_error)
        } else if (is.null(values$raw_data_input)) {
          chart_tr("no_data_show")
        } else if (!values$data_processed_successfully && input$process_data_btn == 0) {
          chart_tr("click_process")
        } else if (!values$data_processed_successfully) {
          chart_tr("process_not_run")
        } else if (!values$metrics_calculated_successfully && input$calculate_metrics_btn == 0) {
          chart_tr("click_calc")
        } else if (!values$metrics_calculated_successfully) {
          chart_tr("calc_not_run")
        } else {
          chart_tr("empty_results")
        }
        return(datatable(data.frame(Message = display_msg),
                         options = list(dom = 't', searching = FALSE, ordering = FALSE),
                         rownames = FALSE))
      }
      cols_to_round <- names(data_df)[sapply(data_df, is.numeric)]
      cols_to_round <- setdiff(cols_to_round, "MASKID")
      if (length(cols_to_round) > 0) {
        tryCatch({
          data_df <- data_df %>% mutate(across(where(is.numeric) & !matches("^MASKID$"), ~ round(.x, 2)))
        }, error = function(e) {
          warning(paste("Error during rounding columns:", e$message), call. = FALSE)
        })
      }
      filename_default <- "abpm_results"
      if (!is.null(caption)) {
        filename_default <- gsub("[^A-Za-z0-9_]", "_", caption)
        filename_default <- gsub("_+", "_", filename_default)
        filename_default <- sub("^_|_$", "", filename_default)
        if (nchar(filename_default) == 0) filename_default <- "abpm_data_export"
      }
      dt_language <- if (APP_LANG == "zh") {
        list(url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese.json")
      } else {
        list()
      }
      datatable(data_df, caption = caption, extensions = c('Buttons', 'FixedColumns'),
                options = list(dom = 'Blfrtip',
                               buttons = list(
                                 list(extend = 'copy', text = paste0('<i class="fa fa-copy"></i> ', chart_tr("dt_copy"))),
                                 list(extend = 'csv', text = paste0('<i class="fa fa-file-csv"></i> ', chart_tr("dt_csv")), filename = filename_default, titleAttr = 'CSV', bom = TRUE),
                                 list(extend = 'excel', text = paste0('<i class="fa fa-file-excel"></i> ', chart_tr("dt_excel")), filename = filename_default, titleAttr = 'Excel')
                               ),
                               scrollX = TRUE, pageLength = 10, searchDelay = 500,
                               search = list(regex = TRUE, caseInsensitive = TRUE),
                               lengthMenu = list(c(10, 25, 50, 100, -1),
                                                 c('10', '25', '50', '100', chart_tr("dt_all"))),
                               columnDefs = list(list(className = 'dt-center', targets = '_all')),
                               fixedColumns = list(leftColumns = 1),
                               language = dt_language,
                               processing = TRUE),
                filter = 'top', rownames = FALSE,
                class = 'cell-border stripe compact hover nowrap', escape = FALSE)
    })
  }"""
S = rep(S, render_dt_old, render_dt_new, label="render_dt_table replacement")

# results tables observer
S = rep(S,
"""              period_title <- switch(current_period_key,
                                     "day" = "日间（使用日间阈值）",
                                     "night" = "夜间（使用夜间阈值）",
                                     "24h" = "24h（日夜统一阈值）",
                                     "24h_segmented" = "24h（日夜分段阈值）",
                                     current_period_key)
              output[[output_id]] <- render_dt_table(data_reactive, caption = paste0(period_title, " 指标 - ", current_metric))""",
"""              period_title <- switch(current_period_key,
                                     "day" = chart_tr("results_day"),
                                     "night" = chart_tr("results_night"),
                                     "24h" = chart_tr("results_24h_unified"),
                                     "24h_segmented" = chart_tr("results_24h_segmented"),
                                     current_period_key)
              output[[output_id]] <- render_dt_table(data_reactive, caption = paste0(period_title, chart_tr("caption_results"), current_metric))""",
label="results observer titles")

# full export: localized assessment (second occurrence sits in the old xlsx
# handler that is removed further below)
S = rep_all(S, "assessments <- build_all_personalized_assessments(values$metric_results)",
        "assessments <- build_all_personalized_assessments(values$metric_results, lang = lang())",
        min_count=2, label="full export lang")
S = rep(S, "    if (nrow(assessments) > 0) metrics_wide <- left_join(metrics_wide, assessments, by = \"MASKID\")",
        """    if (nrow(assessments) > 0) metrics_wide <- left_join(metrics_wide, assessments, by = "MASKID")
    glu_assessments <- build_all_glucose_assessments(values$metric_results, lang = lang())
    if (nrow(glu_assessments) > 0) metrics_wide <- left_join(metrics_wide, glu_assessments, by = "MASKID")""",
        label="full export join glucose assessment")

# remove old download handlers (replaced by the selected-item export panel)
if "  output$download_all_csv <- downloadHandler(" not in S:
    raise SystemExit("PATCH FAILED [downloads]: download_all_csv anchor not found")
if "  # --- Personalized analysis page ---" not in S:
    raise SystemExit("PATCH FAILED [downloads]: personalized anchor not found")
i_dl = S.index("  output$download_all_csv <- downloadHandler(")
j_dl = S.index("  # --- Personalized analysis page ---", i_dl)
S = S[:i_dl] + S[j_dl:]

# personalized page
S = rep(S, "    build_personalized_assessment(values$metric_results, input$analysis_maskid)",
        "    build_personalized_assessment(values$metric_results, input$analysis_maskid, lang = lang())",
        label="personal lang arg")
S = rep(S,
"""    colour <- switch(assessment$followup,
                     "请尽快就医" = "#c62828",
                     "可择期就医" = "#ef6c00",
                     "定期随访" = "#2e7d32",
                     "#333333")""",
"""    colour <- switch(assessment$followup_key,
                     "urgent" = "#c62828",
                     "elective" = "#ef6c00",
                     "routine" = "#2e7d32",
                     "#333333")""",
label="followup colour")
S = rep(S, 'p("分级由平均血压、SD/ARV、TTR、Burden和重度血压信号共同生成。")',
        'p(chart_tr("followup_note"))', label="followup note")
S = rep(S, '"建议必须结合症状、年龄、妊娠状态、合并症、用药及靶器官损害由临床医生确认。"',
        'chart_tr("advice_note")', label="advice note")

# viz summary header
S = rep(S, 'tags$strong("患者:"), tags$code(data$patient_id), " | ",',
        'tags$strong(chart_tr("label_patient")), tags$code(data$patient_id), " | ",', label="viz patient label")
S = rep(S, 'tags$strong("指标:"), tags$code(data$metric_id)',
        'tags$strong(chart_tr("label_metric")), tags$code(data$metric_id)', label="viz metric label")
S = rep(S, 'tags$strong("24h(统一) TTR: "), format_perc(ttr_val)   # Clarified source',
        'tags$strong(chart_tr("label_ttr_24h")), format_perc(ttr_val)', label="viz ttr label")

# viz info lists
S = rep_all(S, 'tags$li(tags$span(style = "color: #D32F2F;", icon("tachometer-alt"), " 升高负担: "), tags$strong(format_perc(hyper_val))),',
        'tags$li(tags$span(style = "color: #D32F2F;", icon("tachometer-alt"), paste0(" ", chart_tr("burden_hyper"), ": ")), tags$strong(format_perc(hyper_val))),',
        min_count=1, label="viz hyper label")
S = rep_all(S, 'tags$li(tags$span(style = "color: #1A237E;", icon("tachometer-alt"), " 偏低负担: "), tags$strong(format_perc(hypo_val))),',
        'tags$li(tags$span(style = "color: #1A237E;", icon("tachometer-alt"), paste0(" ", chart_tr("burden_hypo"), ": ")), tags$strong(format_perc(hypo_val))),',
        min_count=1, label="viz hypo label")

# patient summary print block
summ_old = """      cat(sprintf("%-22s: %s\\n", "平均值 (Mean)", format_val_print(mean_val)))
      cat(sprintf("%-22s: %s\\n", "标准差 (SD)", format_val_print(sd_val)))
      cat(sprintf("%-22s: %s\\n", "变异系数 (CV %)", format_val_print(cv_val, suffix="%")))
      cat(sprintf("%-22s: %s\\n", "平均真实变异 (ARV)", format_val_print(arv_val)))
      cat(sprintf("%-22s: %s\\n", "均值独立变异 (VIM)", format_val_print(vim_val)))
      cat(sprintf("%-22s: %s\\n", "最大值 (Max)", format_val_print(max_val, 0)))
      cat(sprintf("%-22s: %s\\n", "最小值 (Min)", format_val_print(min_val, 0)))
      cat(sprintf("%-22s: %s\\n", "波动范围 (Delta)", format_val_print(delta_val, 0)))
      cat(sprintf("%-22s: %s\\n", "负荷 (Load %)", format_val_print(load_val, suffix="%")))
      cat(sprintf("%-22s: %s\\n", "累积负荷 (Cum. Load %)", format_val_print(cumload_val, suffix="%")))
      cat(sprintf("%-22s: %s\\n", "曲线下面积 (AUC)", format_val_print(auc_val)))"""
summ_new = """      metric_u <- paste0(" ", metric_unit(data$metric_id))
      summary_labels <- c(chart_tr("p_mean"), chart_tr("p_sd"), chart_tr("p_cv"),
                          chart_tr("p_arv"), chart_tr("p_vim"), chart_tr("p_max"),
                          chart_tr("p_min"), chart_tr("p_delta"), chart_tr("p_load"),
                          chart_tr("p_cumload"), chart_tr("p_auc"))
      summary_values <- list(mean_val, sd_val, cv_val, arv_val, vim_val,
                             max_val, min_val, delta_val, load_val, cumload_val, auc_val)
      summary_suffix <- c(metric_u, metric_u, "%", metric_u, metric_u, metric_u,
                          metric_u, metric_u, "%", "%", metric_u)
      summary_digits <- c(2, 2, 2, 2, 2, 0, 0, 0, 2, 2, 2)
      for (k in seq_along(summary_labels)) {
        cat(sprintf("%-22s: %s\\n", summary_labels[k],
                    format_val_print(summary_values[[k]], digits = summary_digits[k],
                                     suffix = summary_suffix[k])))
      }"""
S = rep(S, summ_old, summ_new, label="patient summary print")

server_rest = S

# ---------------------------------------------------------------- compose
final = "\n".join([
    part("01_header.R"),
    builtin,
    device_block,
    glucose_block,
    helpers_time,
    part("04_load_prepare.R"),
    helpers_wide,
    part("05_series.R"),
    helpers_after_series,
    part("06_vim.R"),
    region_D,
    region_charts,
    part("07_assessment.R"),
    part("13_glucose.R"),
    part("02_dict.R"),
    part("03_preprocess.R"),
    part("08_ui.R"),
    "# --- 4. Server Logic (integrated bilingual server) ---",
    part("09_server_head.R"),
    part("10_server_data.R"),
    server_rest,
    part("14_glucose_server.R"),
    part("11_server_exports.R"),
    "} # End server function",
    "",
    part("12_footer.R"),
])

Path(OUT).write_text(final, encoding="utf-8")

print("assembled OK ->", OUT)
print("total lines:", final.count("\n") + 1)
