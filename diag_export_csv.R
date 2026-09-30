# Reproduce the CSV-export content function (write.table + write_export_zip) with
# both the GLU 14-day sample and the builtin BP data, exactly as the app does.
# Extra library locations are appended AFTER the default ones: putting a stale
# rlang from an extra library first makes library(shiny) fail to load.
extra_libs <- c("D:/R/packages", "C:/Users/MSI/.R/library")
extra_libs <- extra_libs[dir.exists(extra_libs)]
.libPaths(c(.libPaths(), extra_libs))
try(suppressWarnings(Sys.setlocale("LC_ALL", "en_US.UTF-8")), silent = TRUE)
suppressPackageStartupMessages({library(shiny); library(dplyr)})
app_file <- "ABPM_calculator_integrated.R"
lines <- readLines(app_file, encoding = "UTF-8", warn = FALSE)
idx <- which(grepl("^shinyApp\\(", trimws(lines)))
tmp <- tempfile(fileext = ".R")
writeLines(paste(lines[seq_len(idx - 1)], collapse = "\n"), tmp, useBytes = TRUE)
env <- new.env(parent = globalenv())
sys.source(tmp, envir = env, keep.source = FALSE)
E <- function(nm) get(nm, envir = env)

build_glu_state <- function() {
  gcsv <- read.csv(text = env$GLUCOSE_SAMPLE_CSV, stringsAsFactors = FALSE, check.names = FALSE)
  glong <- E("load_and_prepare_data")(gcsv, lang = "en")
  gs <- E("create_individual_patient_series")(glong, 7, 0, 22, 0, 7, 0, 22, 0,
                                              interp_mode = "valid", window_mode = "calendar")
  mk <- function(period, u, l) E("calculate_abpm_metrics_for_period_individual")(
    gs$GLU, period, u, l, 7, 0, 22, 0, 7, 0, 22, 0, vim_mode = "fixed")
  seg <- E("calculate_abpm_metrics_24h_segmented_individual")(
    list(GLU = gs$GLU), list(glu_day_lower = 3.9, glu_day_upper = 10.0),
    list(glu_night_lower = 3.9, glu_night_upper = 10.0),
    7, 0, 22, 0, 7, 0, 22, 0, vim_mode = "fixed", multi_day = TRUE)$GLU
  mr <- list(day = list(GLU = mk("day", 10.0, 3.9)),
             night = list(GLU = mk("night", 10.0, 3.9)),
             `24h` = list(GLU = mk("24h", 10.0, 3.9)),
             `24h_segmented` = list(GLU = seg))
  wide <- E("individual_series_to_wide")(gs)
  long_wide <- E("create_wide_data_per_metric")(glong, 7, 0, 22, 0, 7, 0, 22, 0)
  split <- E("split_wide_data_day_night")(wide$wide_dfs, wide$sorted_times, wide$sorted_minutes,
                                          7, 0, 22, 0, 7, 0, 22, 0)
  list(metric_results = mr, prepared_long_data = glong,
       interpolated_dfs = wide$wide_dfs, split_data_wide = split)
}

run_export <- function(tag, state, which_items) {
  # replicate the app's export content function for the selected items
  items <- list()
  if ("wide" %in% which_items) {
    w <- E("build_full_results_wide")(state$metric_results)
    a <- E("build_all_personalized_assessments")(state$metric_results, lang = "en")
    if (nrow(a) > 0) w <- left_join(w, a, by = "MASKID")
    g <- E("build_all_glucose_assessments")(state$metric_results, lang = "en")
    if (nrow(g) > 0) w <- left_join(w, g, by = "MASKID")
    items[["wide"]] <- list(full_wide_table = w)
  }
  if ("period" %in% which_items) {
    for (pk in names(state$metric_results)) {
      for (metric in names(state$metric_results[[pk]])) {
        items[[paste0("period_", pk, "_", metric)]] <- state$metric_results[[pk]][[metric]]
      }
    }
  }
  if ("prepared" %in% which_items) items[["prepared_long_data"]] <- state$prepared_long_data
  if ("interp" %in% which_items) {
    for (metric in names(state$interpolated_dfs)) {
      items[[paste0("interp_", metric)]] <- state$interpolated_dfs[[metric]]
    }
  }
  if ("split" %in% which_items) {
    for (pname in names(state$split_data_wide)) {
      if (is.null(state$split_data_wide[[pname]])) next
      for (metric in names(state$split_data_wide[[pname]])) {
        items[[paste0("split_", pname, "_", metric)]] <- state$split_data_wide[[pname]][[metric]]
      }
    }
  }
  # Pack through the app's own helper so this diagnostic cannot drift from the
  # real export path (zip package with a utils::zip fallback).
  app_items <- lapply(names(items), function(nm) list(csv = setNames(list(items[[nm]]), nm)))
  out_zip <- tempfile(fileext = ".zip")
  ok <- E("write_export_zip")(app_items, out_zip)
  size <- if (file.exists(out_zip)) file.info(out_zip)$size else NA_integer_
  cat(sprintf("%-14s items=%d packed=%s zip_size=%s files=[%s]\n",
              tag, length(items), ok, size,
              if (isTRUE(ok)) paste(utils::unzip(out_zip, list = TRUE)$Name, collapse = ",") else ""))
  invisible(out_zip)
}

glu <- build_glu_state()
run_export("GLU all", glu, c("wide", "period", "prepared", "interp", "split"))
run_export("GLU wide+period", glu, c("wide", "period"))
run_export("GLU interp+split", glu, c("interp", "split"))
