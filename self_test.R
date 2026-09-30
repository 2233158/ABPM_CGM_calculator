# =============================================================================
# self_test.R - verification script for ABPM_calculator_integrated.R
# -----------------------------------------------------------------------------
# Converts the two raw Mobil-O-Graph 24h PWA test exports with the app's own
# R preprocessing functions and compares every value against the golden CSVs
# in converted_samples/.
#
# How to run (in R / RStudio, with the working directory set to this folder):
#     source("self_test.R")
# or from a terminal:
#     Rscript self_test.R
# =============================================================================

script_dir <- tryCatch({
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) == 0) {
    NA_character_
  } else {
    dirname(normalizePath(sub("^--file=", "", file_arg[1]), mustWork = FALSE))
  }
}, error = function(e) NA_character_)
if (is.na(script_dir) || !nzchar(script_dir) || !dir.exists(script_dir)) {
  # fall back to the working directory (e.g. when the script path contains
  # characters the terminal encoding cannot represent)
  script_dir <- getwd()
}
setwd(script_dir)

# Use a UTF-8-capable locale when available (silent on failure)
try(suppressWarnings(Sys.setlocale("LC_ALL", "en_US.UTF-8")), silent = TRUE)

app_file <- "ABPM_calculator_integrated.R"
if (!file.exists(app_file)) {
  stop("Could not find ", app_file, " in ", getwd(),
       ". Please run this script from the ABPM_eng_\u4ea4\u6d41\u7248 folder.")
}

cat("Loading app code (this also installs missing packages if needed)...\n")
app_lines <- readLines(app_file, encoding = "UTF-8", warn = FALSE)
# Evaluate everything except the final shinyApp() launch line
cut <- grep("^shinyApp\\(ui = ui, server = server\\)", app_lines)
if (length(cut) > 0) app_lines <- app_lines[seq_len(cut[1] - 1)]
env <- new.env(parent = globalenv())
eval(parse(text = paste(app_lines, collapse = "\n")), envir = env)

xls_files <- c(
  "test_data/2017-10-23_12-47_JL_50010_24hPWA.xls",
  "test_data/2017-10-10_13-30_GL_50001_24hPWA.xls"
)
golden_files <- c(
  "converted_samples/50010_24hPWA_converted.csv",
  "converted_samples/50001_24hPWA_converted.csv"
)

num_close <- function(a, b) all(abs(as.numeric(a) - as.numeric(b)) < 1e-6, na.rm = TRUE)

all_pass <- TRUE
for (i in seq_along(xls_files)) {
  name <- basename(xls_files[i])
  conv <- tryCatch(env$xls_to_abpm_long(xls_files[i]), error = function(e) e)
  if (inherits(conv, "error")) {
    cat(sprintf("FAIL  %-45s conversion error: %s\n", name, conv$message))
    all_pass <- FALSE
    next
  }
  got <- conv$data[, c("MASKID", "Time", "SBP", "DBP", "HR", "PP", "MAP")]
  exp <- read.csv(golden_files[i], stringsAsFactors = FALSE, check.names = FALSE)
  exp <- exp[, c("MASKID", "Time", "SBP", "DBP", "HR", "PP", "MAP")]

  checks <- c(
    rows   = nrow(got) == nrow(exp),
    MASKID = identical(as.character(got$MASKID), as.character(exp$MASKID)),
    Time   = identical(as.character(got$Time), as.character(exp$Time)),
    SBP    = num_close(got$SBP, exp$SBP),
    DBP    = num_close(got$DBP, exp$DBP),
    HR     = num_close(got$HR, exp$HR),
    PP     = num_close(got$PP, exp$PP),
    MAP    = num_close(got$MAP, exp$MAP)
  )
  ok <- all(checks)
  all_pass <- all_pass && ok
  cat(sprintf("%s  %-45s rows=%d/%d valid=%d dropped=%d\n",
              if (ok) "PASS" else "FAIL", name,
              nrow(got), nrow(exp), conv$n_valid,
              conv$n_dropped_zero + conv$n_dropped_bad_time))
  if (!ok) {
    bad <- names(checks)[!checks]
    cat("      mismatched fields:", paste(bad, collapse = ", "), "\n")
  }
}

cat("\n--- Alias detection (adaptive column-name matching) ---\n")
alias_cases <- list(
  list(cols = c("SubjectID", "TIME_STR", "SBP (mmHg)", "DBP_MMHG", "HR (bpm)",
                "Pulse_Pressure", "Mean_BP"),
       expect = list(MASKID = "SubjectID", Time = "TIME_STR", SBP = "SBP (mmHg)",
                     DBP = "DBP_MMHG", HR = "HR (bpm)", PP = "Pulse_Pressure",
                     MAP = "Mean_BP")),
  list(cols = c("\u60a3\u8005\u7f16\u53f7", "\u6d4b\u91cf\u65f6\u95f4",
                "\u6536\u7f29\u538b(mmHg)", "\u8212\u5f20\u538b(mmHg)",
                "\u5fc3\u7387(\u6b21/\u5206)", "\u8109\u538b(mmHg)",
                "\u5e73\u5747\u52a8\u8109\u538b(mmHg)"),
       expect = list(MASKID = "\u60a3\u8005\u7f16\u53f7", Time = "\u6d4b\u91cf\u65f6\u95f4",
                     SBP = "\u6536\u7f29\u538b(mmHg)", DBP = "\u8212\u5f20\u538b(mmHg)",
                     HR = "\u5fc3\u7387(\u6b21/\u5206)", PP = "\u8109\u538b(mmHg)",
                     MAP = "\u5e73\u5747\u52a8\u8109\u538b(mmHg)")),
  list(cols = c("ID", "TIME", "SYS", "DIA", "PULSE"),
       expect = list(MASKID = "ID", Time = "TIME", SBP = "SYS", DBP = "DIA",
                     HR = "PULSE", PP = NA_character_, MAP = NA_character_))
)
for (case in alias_cases) {
  got <- env$alias_lookup(case$cols)
  ok <- TRUE
  for (tgt in names(case$expect)) {
    g <- got[[tgt]]
    e <- case$expect[[tgt]]
    if (is.na(e) != is.na(g) || (!is.na(e) && !identical(as.character(g), as.character(e)))) {
      ok <- FALSE
    }
  }
  all_pass <- all_pass && ok
  cat(sprintf("%s  %s\n", if (ok) "PASS" else "FAIL",
              paste(case$cols, collapse = " | ")))
  if (!ok) {
    print(got)
    print(case$expect)
  }
}

cat("\n--- Glucose (CGM) domain ---\n")
gconv <- tryCatch(env$glu_raw_to_long(text = env$GLUCOSE_SAMPLE_RAW), error = function(e) e)
ok_g1 <- !inherits(gconv, "error") && gconv$n_valid == 4012 &&
  identical(gconv$auto_maskid, "LT2503SGHM") &&
  identical(names(gconv$data), c("MASKID", "Time", "GLU"))
all_pass <- all_pass && ok_g1
cat(sprintf("%s  embedded raw glucose sample -> 4012 rows, MASKID=LT2503SGHM\n", if (ok_g1) "PASS" else "FAIL"))

gcsv <- read.csv(text = env$GLUCOSE_SAMPLE_CSV, stringsAsFactors = FALSE, check.names = FALSE)
ok_g2 <- nrow(gcsv) == 4012 && identical(names(gcsv), c("MASKID", "Time", "GLU"))
all_pass <- all_pass && ok_g2
cat(sprintf("%s  embedded processed glucose sample -> 4012 rows\n", if (ok_g2) "PASS" else "FAIL"))

glong <- env$load_and_prepare_data(gconv$data, lang = "en")
gs <- env$create_individual_patient_series(glong, 7, 0, 22, 0, 7, 0, 22, 0, interp_mode = "valid")
gr <- env$calculate_abpm_metrics_for_period_individual(
  gs$GLU, "24h", 10.0, 3.9, 7, 0, 22, 0, 7, 0, 22, 0, vim_mode = "fixed")
ok_g3 <- is.finite(gr$TTR[1]) &&
  abs(gr$TTR[1] + gr$TOTR[1] + gr$TUTR[1] - 100) < 1e-6
all_pass <- all_pass && ok_g3
cat(sprintf("%s  14-day GLU pipeline (multi-day windows) runs, TIR/TOTR/TUTR sum to 100%%\n",
            if (ok_g3) "PASS" else "FAIL"))

# --- Analysis window (four modes) ---
cat("\n--- Analysis window ---\n")
ttw <- seq(1080, 3600, by = 15)  # day0 18:00 .. day2 06:00
valw <- ifelse(ttw >= 2760 & ttw < 3300, 110, 120)
long_w <- data.frame(
  MASKID = "W1", Time = vapply(ttw, env$minutes_to_time_string, character(1)),
  Total_Minutes = ttw, SBP = valw, stringsAsFactors = FALSE)
sw <- env$create_individual_patient_series(
  long_w, 7, 0, 22, 0, 7, 0, 22, 0,
  interp_mode = "valid", window_mode = "from_start",
  window_hours = 24, window_start_spec = 1980, edge_rule = "linear")
rw_night <- env$calculate_abpm_metrics_for_period_individual(
  sw$SBP, "night", 200, 50, 7, 0, 22, 0, 7, 0, 22, 0)
rw_day <- env$calculate_abpm_metrics_for_period_individual(
  sw$SBP, "day", 200, 50, 7, 0, 22, 0, 7, 0, 22, 0)
ok_w1 <- is.finite(rw_night$mean[1]) && abs(rw_night$mean[1] - 110) < 1e-9 &&
  abs(rw_day$mean[1] - 120) < 1e-9
all_pass <- all_pass && ok_w1
cat(sprintf("%s  day/night segmentation inside an arbitrary window (night no longer empty)\n",
            if (ok_w1) "PASS" else "FAIL"))

long_w2 <- data.frame(
  MASKID = "W2", Time = c("0000+0D", "0140+0D", "0320+0D", "0300+3D"),
  Total_Minutes = c(0, 100, 200, 4500), SBP = c(100, 100, 100, 999),
  stringsAsFactors = FALSE)
sw2 <- env$create_individual_patient_series(
  long_w2, 7, 0, 22, 0, 7, 0, 22, 0,
  interp_mode = "valid", window_mode = "calendar")$SBP$W2
ok_w2 <- nrow(sw2$raw) == 3 && sw2$window_end == 3 * 1440
all_pass <- all_pass && ok_w2
cat(sprintf("%s  BP calendar window = whole 0-3D (beyond-3D readings excluded)\n",
            if (ok_w2) "PASS" else "FAIL"))

long_w3 <- data.frame(
  MASKID = "W3", Time = c("0100+0D", "0100+15D", "0100+16D"),
  Total_Minutes = c(60, 15 * 1440 + 60, 16 * 1440 + 60), GLU = c(5, 6, 999),
  stringsAsFactors = FALSE)
sw3 <- env$create_individual_patient_series(
  long_w3, 7, 0, 22, 0, 7, 0, 22, 0,
  interp_mode = "valid", window_mode = "calendar")$GLU$W3
ok_w3 <- nrow(sw3$raw) == 2 && sw3$window_end == 16 * 1440
all_pass <- all_pass && ok_w3
cat(sprintf("%s  GLU calendar window = whole 0-15D (+15D kept, +16D excluded)\n",
            if (ok_w3) "PASS" else "FAIL"))

ttw4 <- seq(540, 1980, by = 15)
old_day <- with(list(d1s = 420, n1s = 1320, d2s = 1860, n2s = 2760),
                which((ttw4 >= d1s & ttw4 < n1s) | (ttw4 >= d2s & ttw4 < n2s)))
ok_w4 <- identical(old_day, env$individual_period_indices(ttw4, "day", 7, 0, 22, 0, 7, 0, 22, 0))
all_pass <- all_pass && ok_w4
cat(sprintf("%s  window segmentation matches the classic 2-day layout for default clocks\n",
            if (ok_w4) "PASS" else "FAIL"))

# Area/time metrics must partition the window exactly: with identical limits,
# day + night must reproduce the 24h results (no phantom trapezoids between
# non-adjacent axis points).
ttw5 <- seq(540, 1980, by = 15)
long_w5 <- data.frame(
  MASKID = "W5", Time = vapply(ttw5, env$minutes_to_time_string, character(1)),
  Total_Minutes = ttw5,
  SBP = ifelse(ttw5 >= 1320 & ttw5 < 1860, 100, 130), stringsAsFactors = FALSE)
sw5 <- env$create_individual_patient_series(
  long_w5, 7, 0, 22, 0, 7, 0, 22, 0,
  interp_mode = "valid", window_mode = "from_first", window_hours = 24)$SBP$W5
r5d <- env$calculate_abpm_metrics_for_period_individual(
  list(W5 = sw5), "day", 115, 95, 7, 0, 22, 0, 7, 0, 22, 0)
r5n <- env$calculate_abpm_metrics_for_period_individual(
  list(W5 = sw5), "night", 115, 95, 7, 0, 22, 0, 7, 0, 22, 0)
r5h <- env$calculate_abpm_metrics_for_period_individual(
  list(W5 = sw5), "24h", 115, 95, 7, 0, 22, 0, 7, 0, 22, 0)
ok_w5 <- abs((r5d$AUC + r5n$AUC) - r5h$AUC) < 1e-6 &&
  abs((r5d$Ts1_total + r5n$Ts1_total) - r5h$Ts1_total) < 1e-6 &&
  abs((r5d$Ts2_total + r5n$Ts2_total) - r5h$Ts2_total) < 1e-6 &&
  abs((r5d$Ts3_total + r5n$Ts3_total) - r5h$Ts3_total) < 1e-6 &&
  abs((r5d$Sa + r5n$Sa) - r5h$Sa) < 1e-6
all_pass <- all_pass && ok_w5
cat(sprintf("%s  day+night areas reproduce 24h exactly (window partition, no phantom trapezoids)\n",
            if (ok_w5) "PASS" else "FAIL"))

# The same analysis window expressed through different modes must give
# identical results, and every mode must keep day+night additivity.
long_w6 <- long_w5  # reuse the synthetic patient from the previous check
s_ff <- env$create_individual_patient_series(
  long_w6, 7, 0, 22, 0, 7, 0, 22, 0,
  interp_mode = "valid", window_mode = "from_first", window_hours = 24)
s_cu <- env$create_individual_patient_series(
  long_w6, 7, 0, 22, 0, 7, 0, 22, 0,
  interp_mode = "valid", window_mode = "custom",
  window_start_spec = 540, window_end_spec = 540 + 1440)
row_of <- function(series, period) {
  env$calculate_abpm_metrics_for_period_individual(
    series, period, 115, 95, 7, 0, 22, 0, 7, 0, 22, 0,
    vim_mode = "fixed", vim_ref_mean = 100)[1, ]
}
ok_w6 <- TRUE
for (p in c("day", "night", "24h")) {
  a <- row_of(s_ff$SBP, p); b <- row_of(s_cu$SBP, p)
  for (f in c("mean", "SD", "AUC", "Ts1_total", "Ts2_total", "Ts3_total", "TTR")) {
    ok_w6 <- ok_w6 && (is.na(a[[f]]) == is.na(b[[f]])) &&
      (is.na(a[[f]]) || abs(a[[f]] - b[[f]]) < 1e-6 * max(1, abs(a[[f]])))
  }
}
all_pass <- all_pass && ok_w6
cat(sprintf("%s  identical window via from_first vs custom gives identical results\n",
            if (ok_w6) "PASS" else "FAIL"))

ok_w7 <- TRUE
for (wmode in list(list(m = "calendar", ws = NULL, we = NULL, h = 24),
                   list(m = "from_first", ws = NULL, we = NULL, h = 24),
                   list(m = "from_start", ws = 780, we = NULL, h = 24),
                   list(m = "custom", ws = 1000, we = 1900, h = 24))) {
  s <- env$create_individual_patient_series(
    long_w6, 7, 0, 22, 0, 7, 0, 22, 0,
    interp_mode = "valid", window_mode = wmode$m, window_hours = wmode$h,
    window_start_spec = wmode$ws, window_end_spec = wmode$we, edge_rule = "linear")
  if (is.null(s$SBP) || length(s$SBP) == 0) { ok_w7 <- FALSE; next }
  d <- row_of(s$SBP, "day"); n <- row_of(s$SBP, "night"); h <- row_of(s$SBP, "24h")
  ok_w7 <- ok_w7 && abs((d$AUC + n$AUC) - h$AUC) < 1e-6 * max(1, h$AUC) &&
    abs((h$TTR + h$TOTR + h$TUTR) - 100) < 1e-9
}
all_pass <- all_pass && ok_w7
cat(sprintf("%s  all four window modes keep day+night additivity and TIR sums = 100%%\n",
            if (ok_w7) "PASS" else "FAIL"))

cat("\n")
if (all_pass) {
  cat("SELF TEST RESULT: PASS - the R converter reproduces the golden CSVs.\n")
} else {
  cat("SELF TEST RESULT: FAIL - see the fields reported above.\n")
  quit(status = 1)
}
