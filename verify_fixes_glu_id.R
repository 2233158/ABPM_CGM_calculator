# =============================================================================
# verify_fixes_glu_id.R
# -----------------------------------------------------------------------------
# Regression checks for three fixed defects:
#   1) "missing value where TRUE/FALSE needed" when a prepared CSV has no GLU
#      column (alias_lookup() used to omit the GLU key, so mapping_panel's
#      `if (is.na(cur) || ...)` was evaluated on a zero-length value);
#   2) raw Mobil-O-Graph exports whose index column is labelled "No." / "Nr." /
#      "序号" instead of "Number" (header row was not found);
#   3) CSV export packing used utils::zip(), which shells out to a zip
#      executable that a plain Windows R install and shinyapps.io do not have.
#
# Runs the real Shiny server through shiny::testServer(), so it exercises the
# upload -> map -> process -> calculate -> export path end to end.
#
# Requirements: run from this folder; the packages used by the app, plus
# writexl (only for the synthetic raw-export cases in section 3).
#     Rscript verify_fixes_glu_id.R
# =============================================================================
options(warn = 1)
# Without a UTF-8 locale, pasting the app source back together mangles its CJK
# string literals into "\uXXXX" text and every Chinese column alias stops
# matching - the same guard self_test.R / diag_export_csv.R use.
try(suppressWarnings(Sys.setlocale("LC_ALL", "en_US.UTF-8")), silent = TRUE)
app_file <- "ABPM_calculator_integrated.R"
app_lines <- readLines(app_file, encoding = "UTF-8", warn = FALSE)
cut <- grep("^shinyApp\\(ui = ui, server = server\\)", app_lines)
if (length(cut) > 0) app_lines <- app_lines[seq_len(cut[1] - 1)]
env <- new.env(parent = globalenv())
eval(parse(text = paste(app_lines, collapse = "\n")), envir = env)

pass <- 0L; fail <- 0L
check <- function(label, ok, detail = "") {
  if (isTRUE(ok)) { pass <<- pass + 1L; cat(sprintf("  PASS  %s\n", label)) }
  else { fail <<- fail + 1L; cat(sprintf("  FAIL  %s  %s\n", label, detail)) }
}

# ---------------------------------------------------------------------------
cat("\n[1] alias_lookup always returns every target key\n")
m <- env$alias_lookup(c("MASKID", "Time", "SBP", "DBP", "HR", "PP", "MAP"))
check("all 8 target keys present", length(m) == 8 &&
        all(c("MASKID","Time","SBP","DBP","HR","PP","MAP","GLU") %in% names(m)),
      paste(names(m), collapse = ","))
check("unmapped GLU is NA, not NULL", length(m$GLU) == 1L && is.na(m$GLU))

cat("\n[2] 'No.' / 'Number' / '序号' as an ID column\n")
m2 <- env$alias_lookup(c("No.", "Time", "SBP", "DBP", "HR"))
check("'No.' detected as MASKID when it is the only ID", identical(m2$MASKID, "No."),
      paste0("got ", m2$MASKID))
m3 <- env$alias_lookup(c("No.", "MASKID", "Time", "SBP", "DBP", "HR"))
check("real MASKID wins over a leading 'No.' counter", identical(m3$MASKID, "MASKID"),
      paste0("got ", m3$MASKID))
m4 <- env$alias_lookup(c("Number", "MASKID", "Time", "SBP"))
check("real MASKID wins over a leading 'Number' counter", identical(m4$MASKID, "MASKID"),
      paste0("got ", m4$MASKID))
m5 <- env$alias_lookup(c("序号", "时间", "收缩压", "舒张压", "心率"))
check("Chinese '序号' id + CJK metric names detected",
      identical(m5$MASKID, "序号") && identical(m5$SBP, "收缩压") &&
        identical(m5$DBP, "舒张压") && identical(m5$HR, "心率"))
m6 <- env$alias_lookup(c("Patient No.", "Time", "SBP"))
check("'Patient No.' still maps via PATIENT_NO", identical(m6$MASKID, "Patient No."),
      paste0("got ", m6$MASKID))

# ---------------------------------------------------------------------------
cat("\n[3] raw device export: header row with 'Number' and with 'No.'\n")
base_mat <- env$read_sheet_cell_matrix("test_data/2017-10-10_13-30_GL_50001_24hPWA.xls")
hdr <- which(apply(base_mat, 1, function(r) any(as.character(r) == "Number", na.rm = TRUE)))[1]
mk_export <- function(index_label, path) {
  m <- base_mat
  m[hdr, 1] <- index_label
  writexl::write_xlsx(as.data.frame(m), path)
  path
}
if (!requireNamespace("writexl", quietly = TRUE)) {
  cat("  SKIP  synthetic raw exports (package 'writexl' not installed)\n")
} else {
  for (lbl in c("Number", "No.", "No", "Nr.", "序号")) {
    p <- mk_export(lbl, file.path(tempdir(), paste0("raw_", gsub("[^A-Za-z0-9]", "", lbl), ".xlsx")))
    conv <- tryCatch(env$xls_to_abpm_long(p), error = function(e) e)
    ok <- !inherits(conv, "error") && nrow(conv$data) > 0
    check(sprintf("index column %-7s parses (%d valid rows)", paste0("'", lbl, "'"),
                  if (inherits(conv, "error")) 0L else nrow(conv$data)),
          ok, if (inherits(conv, "error")) conditionMessage(conv) else "")
  }
}
# baseline: the untouched real exports still convert identically
conv_now <- env$xls_to_abpm_long("test_data/2017-10-10_13-30_GL_50001_24hPWA.xls")
golden <- read.csv("converted_samples/50001_24hPWA_converted.csv",
                   stringsAsFactors = FALSE, check.names = FALSE)
check("unchanged real export matches golden CSV",
      { a <- conv_now$data[, c("MASKID","Time","SBP","DBP","HR","PP","MAP")]
        b <- golden[, c("MASKID","Time","SBP","DBP","HR","PP","MAP")]
        for (cl in names(b)) b[[cl]] <- as.character(b[[cl]])
        for (cl in names(a)) a[[cl]] <- as.character(a[[cl]])
        isTRUE(all.equal(a, b, check.attributes = FALSE)) })

# ---------------------------------------------------------------------------
cat("\n[3b] CSV export packing (write_export_zip)\n")
check("'zip' package is available", isTRUE(env$has_zip))
items_ok <- list(
  list(csv = list(full_wide_table = data.frame(MASKID = "P001", SBP = 120))),
  list(csv = list(period_24h_SBP = data.frame(MASKID = "P001", mean = 118)))
)
z <- tempfile(fileext = ".zip")
ok <- env$write_export_zip(items_ok, z)
check("write_export_zip creates an archive",
      isTRUE(ok) && file.exists(z) && file.info(z)$size > 0)
entries <- utils::unzip(z, list = TRUE)$Name
check("archive contains every selected CSV",
      all(c("full_wide_table.csv", "period_24h_SBP.csv") %in% entries),
      paste(entries, collapse = ","))
exdir <- file.path(tempdir(), "unz_check")
utils::unzip(z, exdir = exdir)
d <- read.csv(file.path(exdir, "full_wide_table.csv"), stringsAsFactors = FALSE)
check("packed CSV keeps its header and values",
      identical(names(d), c("MASKID", "SBP")) && identical(d$MASKID, "P001"))
check("empty item list returns FALSE (no archive written)",
      identical(env$write_export_zip(list(), tempfile(fileext = ".zip")), FALSE))

# The actual defect: utils::zip() shells out to a zip executable that a plain
# Windows R install does not ship. Packing must keep working with one absent.
path_parts <- strsplit(Sys.getenv("PATH"), ";")[[1]]
path_parts <- path_parts[!grepl("rtools", path_parts, ignore.case = TRUE)]
old_path <- Sys.getenv("PATH")
Sys.setenv(PATH = paste(path_parts, collapse = ";"))
z2 <- tempfile(fileext = ".zip")
res2 <- tryCatch({ env$write_export_zip(items_ok, z2); "done" },
                 error = function(e) conditionMessage(e))
size2 <- if (file.exists(z2)) file.info(z2)$size else 0L
check("packs with no external zip executable on PATH (Rtools removed)",
      identical(res2, "done") && size2 > 0,
      paste0("result=", res2, " size=", size2, " zip-on-path=", nzchar(Sys.which("zip"))))
Sys.setenv(PATH = old_path)

# ---------------------------------------------------------------------------
# Full server round-trip: upload -> map -> process -> calculate -> assess
run_server <- function(label, df, with_glu) {
  cat("\n[4]", label, "\n")
  p <- file.path(tempdir(), paste0(gsub("[^A-Za-z0-9]", "_", label), ".csv"))
  write.csv(df, p, row.names = FALSE, na = "")
  up <- data.frame(datapath = p, name = basename(p), size = file.info(p)$size,
                   type = "text/csv", stringsAsFactors = FALSE)
  shiny::testServer(env$server, {
    do.call(session$setInputs, list(
      domain = "bp", upload_mode = "csv", csv_files = up,
      use_builtin_data = FALSE, use_device_sample = FALSE,
      day1_start_h = 7, day1_start_m = 0,
      day1_night_start_h = 22, day1_night_start_m = 0,
      day2_start_h = 7, day2_start_m = 0,
      day2_night_start_h = 22, day2_night_start_m = 0,
      window_mode = "from_first", window_hours = 24,
      interp_mode = "valid", vim_mode = "cohort", vim_ref_mean = 100))
    mapp <- list(map_id = "MASKID", map_time = "Time", map_sbp = "SBP",
                 map_dbp = "DBP", map_hr = "HR", map_pp = "PP", map_map = "MAP",
                 map_glu = if (with_glu) "GLU" else "")
    # target ranges used by the calculation
    tg <- list()
    for (per in c("day", "night", "24h")) {
      tg[[paste0("sbp_", per, "_lower")]] <- 90; tg[[paste0("sbp_", per, "_upper")]] <- 130
      tg[[paste0("dbp_", per, "_lower")]] <- 55; tg[[paste0("dbp_", per, "_upper")]] <- 80
      tg[[paste0("hr_",  per, "_lower")]] <- 50; tg[[paste0("hr_",  per, "_upper")]] <- 100
      tg[[paste0("pp_",  per, "_lower")]] <- 30; tg[[paste0("pp_",  per, "_upper")]] <- 60
      tg[[paste0("map_", per, "_lower")]] <- 70; tg[[paste0("map_", per, "_upper")]] <- 100
      tg[[paste0("glu_", per, "_lower")]] <- 3.9; tg[[paste0("glu_", per, "_upper")]] <- 10
    }
    do.call(session$setInputs, c(mapp, tg, list(apply_mapping_btn = 1)))
    session$setInputs(process_data_btn = 1)
    check("processing succeeds", isTRUE(values$data_processed_successfully),
          if (is.null(values$processing_error)) "" else values$processing_error)
    session$setInputs(calculate_metrics_btn = 1)
    check("metric calculation succeeds", isTRUE(values$metrics_calculated_successfully),
          if (is.null(values$calculation_error)) "" else values$calculation_error)
    cats <- names(values$metric_results$`24h`)
    check("24h results present", length(cats) > 0, paste(cats, collapse = ","))
    if (with_glu) check("GLU results present", "GLU" %in% cats, paste(cats, collapse = ","))
    else check("no GLU results (none expected)", !("GLU" %in% cats), paste(cats, collapse = ","))

    mp <- tryCatch({ force(output$mapping_panel); "ok" },
                   error = function(e) paste("ERR:", conditionMessage(e)))
    check("mapping panel renders", identical(mp, "ok"), mp)
    for (nm in c("personal_followup_level", "personal_advice", "personal_dimension_table",
                 "personal_guideline_table", "personal_glu_block",
                 "viz_summary_header", "data_status_line")) {
      r <- tryCatch({ force(output[[nm]]); "ok" },
                    error = function(e) {
                      if (inherits(e, "shiny.silent.error")) "ok (req)" else paste("ERR:", conditionMessage(e))
                    })
      check(paste0("output$", nm), identical(r, "ok") || identical(r, "ok (req)"), r)
    }
    # export path (what the "Export selected items" buttons run)
    fx <- tryCatch({ force(full_export_reactive()); "ok" },
                   error = function(e) paste("ERR:", conditionMessage(e)))
    check("full_export_reactive", identical(fx, "ok"), fx)
    ex <- tryCatch({ force(export_items_reactive()); "ok" },
                   error = function(e) paste("ERR:", conditionMessage(e)))
    check("export_items_reactive", identical(ex, "ok"), ex)
    # the same packing the "download selected CSV" button performs
    session$setInputs(export_items = c("wide", "period", "personal",
                                       "prepared", "interp", "split"))
    zf <- tempfile(fileext = ".zip")
    pk <- tryCatch(env$write_export_zip(export_items_reactive(), zf),
                   error = function(e) e)
    check("selected-item zip export packs real results",
          isTRUE(pk) && file.exists(zf) && file.info(zf)$size > 0,
          if (inherits(pk, "error")) conditionMessage(pk) else paste("packed =", pk))
    if (isTRUE(pk)) {
      chk <- tryCatch(env$build_full_results_wide(values$metric_results), error = function(e) NULL)
      check("exported zip is readable and holds the result tables",
            length(utils::unzip(zf, list = TRUE)$Name) >= 3 && !is.null(chk),
            paste(utils::unzip(zf, list = TRUE)$Name, collapse = ","))
    }
    wide <- tryCatch(env$build_full_results_wide(values$metric_results), error = function(e) e)
    check("build_full_results_wide", !inherits(wide, "error"),
          if (inherits(wide, "error")) conditionMessage(wide) else
            paste0(nrow(wide), " rows x ", ncol(wide), " cols"))
    pa <- tryCatch(env$build_all_personalized_assessments(values$metric_results, lang = "zh"),
                   error = function(e) e)
    check("build_all_personalized_assessments", !inherits(pa, "error") && nrow(pa) > 0,
          if (inherits(pa, "error")) conditionMessage(pa) else paste(nrow(pa), "rows"))
    ga <- tryCatch(env$build_all_glucose_assessments(values$metric_results, lang = "zh"),
                   error = function(e) e)
    check("build_all_glucose_assessments", !inherits(ga, "error"),
          if (inherits(ga, "error")) conditionMessage(ga) else "ok")
  })
}

prep_no_glu <- read.csv("converted_samples/50001_24hPWA_converted.csv",
                        stringsAsFactors = FALSE, check.names = FALSE)
run_server("A. prepared CSV WITHOUT GLU", prep_no_glu, FALSE)
run_server("B. prepared CSV WITH GLU", transform(prep_no_glu, GLU = 6.5), TRUE)
run_server("C. prepared CSV with leading 'No.' counter + MASKID",
           cbind(`No.` = seq_len(nrow(prep_no_glu)), prep_no_glu), FALSE)
run_server("D. prepared CSV with an EMPTY GLU column",
           transform(prep_no_glu, GLU = NA_real_), FALSE)
run_server("E. prepared CSV with a single GLU reading",
           transform(prep_no_glu, GLU = c(6.5, rep(NA_real_, nrow(prep_no_glu) - 1))), TRUE)

cat(sprintf("\n===== %d passed, %d failed =====\n", pass, fail))
if (fail > 0) quit(status = 1)
