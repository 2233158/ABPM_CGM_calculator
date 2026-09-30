# Cross-check extractor: run the app's R engine over the same cases as the
# independent Python reference and dump every metric field to xcheck_r.json.
.libPaths(c("D:/R/packages", "C:/Users/MSI/.R/library", .libPaths()))
try(suppressWarnings(Sys.setlocale("LC_ALL", "en_US.UTF-8")), silent = TRUE)
suppressPackageStartupMessages({library(shiny); library(dplyr); library(jsonlite)})

app_file <- "ABPM_calculator_integrated.R"
lines <- readLines(app_file, encoding = "UTF-8", warn = FALSE)
idx <- which(grepl("^shinyApp\\(", trimws(lines)))
stopifnot(length(idx) == 1)
tmp <- tempfile(fileext = ".R")
writeLines(paste(lines[seq_len(idx - 1)], collapse = "\n"), tmp, useBytes = TRUE)
env <- new.env(parent = globalenv())
sys.source(tmp, envir = env, keep.source = FALSE)
E <- function(nm) get(nm, envir = env)

FIELDS <- c("max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "VIM",
            "Sa", "Sc", "AUC", "Ts1_total", "Ts2_total", "Ts3_total", "Load",
            "cumulative_Load", "TTR", "TOTR", "TUTR",
            "hyper_Burden", "hypo_Burden", "Se", "Sf")

bp_limits <- list(
  SBP = list(day = c(90, 120), night = c(90, 110), h24 = c(90, 115)),
  DBP = list(day = c(55, 70), night = c(55, 60), h24 = c(55, 65)),
  HR  = list(day = c(60, 100), night = c(50, 90), h24 = c(55, 95)),
  PP  = list(day = c(NA, NA), night = c(NA, NA), h24 = c(NA, NA)),
  MAP = list(day = c(NA, NA), night = c(NA, NA), h24 = c(NA, NA)))
glu_limits <- list(GLU = list(day = c(3.9, 10), night = c(3.9, 10), h24 = c(3.9, 10)))

bp_csv <- read.csv("xcheck_bp_synth.csv", stringsAsFactors = FALSE, check.names = FALSE)
bp_long <- E("load_and_prepare_data")(bp_csv, lang = "en")
glu_csv <- read.csv(text = env$GLUCOSE_SAMPLE_CSV, stringsAsFactors = FALSE, check.names = FALSE)
glu_long <- E("load_and_prepare_data")(glu_csv, lang = "en")

targets_for <- function(lims_table, day_table, night_table) {
  out <- list()
  for (m in names(lims_table)) {
    out[[paste0(tolower(m), "_day_lower")]] <- day_table[[m]][1]
    out[[paste0(tolower(m), "_day_upper")]] <- day_table[[m]][2]
    out[[paste0(tolower(m), "_night_lower")]] <- night_table[[m]][1]
    out[[paste0(tolower(m), "_night_upper")]] <- night_table[[m]][2]
  }
  out
}
bp_targets <- targets_for(bp_limits,
                          lapply(bp_limits, `[[`, "day"),
                          lapply(bp_limits, `[[`, "night"))
glu_targets <- targets_for(glu_limits,
                           lapply(glu_limits, `[[`, "day"),
                           lapply(glu_limits, `[[`, "night"))

records <- list()

run_one <- function(data_key, long, ws, we, interp, calendar, wmode, whours,
                    lims_table, targets, key_mode, edge = "linear") {
  series <- E("create_individual_patient_series")(
    long, 7, 0, 22, 0, 7, 0, 22, 0,
    interp_mode = interp, window_mode = wmode, window_hours = whours,
    window_start_spec = ws, window_end_spec = we, edge_rule = edge)
  for (metric in names(lims_table)) {
    ser <- series[[metric]]
    if (is.null(ser) || length(ser) == 0) next
    lims <- lims_table[[metric]]
    for (period in c("day", "night", "h24")) {
      lim <- lims[[period]]
      pkey <- if (period == "h24") "24h" else period
      r <- if (metric %in% c("PP", "MAP")) {
        E("calculate_abpm_metrics_without_limits_individual")(
          ser, pkey, 7, 0, 22, 0, 7, 0, 22, 0,
          vim_mode = "fixed", vim_ref_mean = 100)
      } else {
        E("calculate_abpm_metrics_for_period_individual")(
          ser, pkey, lim[2], lim[1], 7, 0, 22, 0, 7, 0, 22, 0,
          vim_mode = "fixed", vim_ref_mean = 100)
      }
      key <- sprintf("%s|%s|%s|%s", data_key, metric, pkey, key_mode)
      records[[key]] <<- as.list(r[1, FIELDS])
    }
    rs <- E("calculate_abpm_metrics_24h_segmented_individual")(
      stats::setNames(list(ser), metric), targets$day, targets$night,
      7, 0, 22, 0, 7, 0, 22, 0,
      vim_mode = "fixed", vim_ref_mean = 100, multi_day = metric == "GLU")[[metric]]
    key <- sprintf("%s|%s|segmented|%s", data_key, metric, key_mode)
    rs_row <- as.list(rs[1, paste0(metric, "_", FIELDS)])
    names(rs_row) <- FIELDS
    records[[key]] <<- rs_row
  }
}

bp_tmin <- min(bp_long$Total_Minutes, na.rm = TRUE)
bp_tmax <- max(bp_long$Total_Minutes, na.rm = TRUE)
run_one("bp", bp_long, 0, 3 * 1440, "valid", TRUE, "calendar", 24, bp_limits,
        list(day = bp_targets, night = bp_targets), "cal_valid")
run_one("bp", bp_long, 0, 3 * 1440, "full", TRUE, "calendar", 24, bp_limits,
        list(day = bp_targets, night = bp_targets), "cal_full")
run_one("bp", bp_long, NA, NA, "valid", FALSE, "from_first", 48, bp_limits,
        list(day = bp_targets, night = bp_targets), "win_valid")
run_one("bp", bp_long, 3 * 1440 + 540, 4 * 1440 + 540, "valid", FALSE, "custom", 24,
        bp_limits, list(day = bp_targets, night = bp_targets), "win2_valid")
run_one("bp", bp_long, 2 * 1440 + 780, NA, "valid", FALSE, "from_start", 24,
        bp_limits, list(day = bp_targets, night = bp_targets), "win3_valid")
run_one("bp", bp_long, 4 * 1440 + 1320, 5 * 1440 + 1320, "valid", FALSE, "custom", 24,
        bp_limits, list(day = bp_targets, night = bp_targets), "win4_valid")
run_one("bp", bp_long, NA, NA, "valid", FALSE, "from_first", 24, bp_limits,
        list(day = bp_targets, night = bp_targets), "win5_valid")
run_one("bp", bp_long, 2 * 1440 + 100, 2 * 1440 + 100 + 1440, "valid", FALSE, "custom", 24,
        bp_limits, list(day = bp_targets, night = bp_targets), "win6_valid", edge = "nearest")
run_one("bp", bp_long, 2 * 1440 + 100, 2 * 1440 + 100 + 1440, "valid", FALSE, "custom", 24,
        bp_limits, list(day = bp_targets, night = bp_targets), "win7_valid", edge = "none")

glu_tmin <- min(glu_long$Total_Minutes, na.rm = TRUE)
glu_tmax <- max(glu_long$Total_Minutes, na.rm = TRUE)
run_one("glu", glu_long, 0, 16 * 1440, "valid", TRUE, "calendar", 24, glu_limits,
        list(day = glu_targets, night = glu_targets), "cal_valid")
run_one("glu", glu_long, 0, 16 * 1440, "full", TRUE, "calendar", 24, glu_limits,
        list(day = glu_targets, night = glu_targets), "cal_full")
run_one("glu", glu_long, NA, NA, "valid", FALSE, "from_first", 72, glu_limits,
        list(day = glu_targets, night = glu_targets), "win_valid")
run_one("glu", glu_long, 4 * 1440 + 22 * 60, 6 * 1440 + 22 * 60, "valid", FALSE, "custom", 24,
        glu_limits, list(day = glu_targets, night = glu_targets), "win2_valid")

writeLines(toJSON(records, na = "null", digits = 17, auto_unbox = TRUE),
           "xcheck_r.json")
cat("R records:", length(records), "\n")
cat("bp tmin/tmax:", bp_tmin, bp_tmax, " glu tmin/tmax:", glu_tmin, glu_tmax, "\n")
