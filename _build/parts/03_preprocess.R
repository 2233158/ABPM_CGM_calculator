# =============================================================================
# Bilingual helpers, column aliases and raw Mobil-O-Graph 24h PWA preprocessing
# =============================================================================

# Language of the currently rendered page; kept in sync by the server so that
# chart/table helpers can localize without a `lang` argument at every call site.
APP_LANG <- "en"
chart_tr <- function(key) tr(APP_LANG, key)

# Alias table for automatic column detection.
# Targets are the canonical post-preprocessing column names. Source columns
# may use unit suffixes, separators or Chinese punctuation - normalization
# removes all whitespace/punctuation and lower-cases ASCII, so
# "SBP (mmHg)", "SBP_MMHG", "sbpmmHg" and "收缩压(mmHg)" all match.
ABPM_ALIASES <- list(
  MASKID = c("MASKID", "PATIENTID", "PATIENT_ID", "PATIENT", "SUBJECT",
             "SUBJECTID", "SUBJECT_ID", "SUBJID", "SUBJ", "ID", "PID",
             "PTID", "PATIENT_NO", "PATIENTNO", "MEDICAL_RECORD_NO",
             "患者", "受试者", "病人编号", "患者编号", "受试者编号", "编号", "病历号",
             # Device exports label the running-index / study-number column
             # "Number" or "No." depending on the firmware version. These sit
             # last on purpose: alias lookups run in list order, so a file that
             # also carries a real MASKID/PATIENT_ID column always maps the ID
             # to that column instead of to a leading counter.
             "NUMBER", "NO", "NUM", "NR", "序号"),
  Time   = c("TIME", "TIME_STR", "TIMESTAMP", "DATE_TIME", "DATETIME",
             "DT", "READING_TIME", "MEASURE_TIME", "HHMM",
             "时间", "日期时间", "测量时间", "时间点"),
  SBP    = c("SBP", "SYS", "SYSTOLIC", "SBPSYS", "SYSTOLE",
             "SYSTOLICBP", "SYSTOLIC_BLOOD_PRESSURE",
             "SBP_MMHG", "SBP (mmHg)", "收缩压", "收缩压(mmHg)"),
  DBP    = c("DBP", "DIA", "DIASTOLIC", "DBPDIA", "DIASTOLE",
             "DIASTOLICBP", "DIASTOLIC_BLOOD_PRESSURE",
             "DBP_MMHG", "DBP (mmHg)", "舒张压", "舒张压(mmHg)"),
  HR     = c("HR", "PULSE", "PULSE_RATE", "HEART_RATE", "HEARTRATE",
             "HEARTBEAT", "PR", "HR_BPM", "HR (bpm)",
             "心率", "心率(次/分)", "脉搏"),
  PP     = c("PP", "PULSE_PRESSURE", "PULSEPRESSURE", "PPP",
             "PP_MMHG", "PP (mmHg)", "脉压", "脉压差", "脉压(mmHg)"),
  MAP    = c("MAP", "MEAN_ARTERIAL_PRESSURE", "MEANBP", "MBP",
             "MAP_MMHG", "MAP (mmHg)", "平均动脉压", "平均动脉压(mmHg)", "平均压"),
  GLU    = c("GLU", "GLUCOSE", "BG", "BLOOD_GLUCOSE", "SENSOR_GLUCOSE",
             "GLU_MMOL", "GLU (mmol/L)", "血糖", "血糖值", "血糖值(mmol/L)",
             "血糖(mmol/L)", "葡萄糖")
)

# Normalize a column name for alias matching: strip all whitespace and
# punctuation, then lower-case pure-ASCII names; CJK names keep their
# characters (punctuation removed, so 收缩压(mmHg) -> 收缩压mmHg).
# ASCII detection uses a perl regex because [\x20-\x7E] ranges behave
# unreliably across locales (e.g. GBK).
norm_col <- function(x) {
  x <- trimws(as.character(x))
  x <- gsub("[[:space:][:punct:]]", "", x)
  is_ascii <- !grepl("[^\\x00-\\x7F]", x, perl = TRUE)
  x[is_ascii] <- tolower(x[is_ascii])
  x
}
ABPM_ALIASES_NORM <- lapply(ABPM_ALIASES, function(v) vapply(v, norm_col, character(1)))

# Detect which source columns match the canonical targets. Each source column
# is assigned to at most one target, in priority order MASKID > Time > metrics.
# Every target key is always present in the returned list (NA when unmapped) so
# callers can safely test `is.na(mapping$GLU)` even when GLU is absent - a NULL
# element here used to crash the mapping panel with "missing value where
# TRUE/FALSE needed".
alias_lookup <- function(col_names) {
  col_names <- as.character(col_names)
  normed <- vapply(col_names, norm_col, character(1))
  taken <- character(0)
  mapping <- list(MASKID = NA_character_, Time = NA_character_, SBP = NA_character_,
                  DBP = NA_character_, HR = NA_character_, PP = NA_character_,
                  MAP = NA_character_, GLU = NA_character_)
  for (target in names(ABPM_ALIASES_NORM)) {
    # Walk each alias list in order so the most canonical name wins: a file
    # that carries both "MASKID" and a leading "No." counter still maps the ID
    # to "MASKID" instead of to whichever column happens to come first.
    for (alias in ABPM_ALIASES_NORM[[target]]) {
      hit <- which(normed == alias & !(col_names %in% taken))
      if (length(hit) > 0) {
        mapping[[target]] <- col_names[hit[1]]
        taken <- c(taken, col_names[hit[1]])
        break
      }
    }
  }
  mapping
}

# --------------------------------------------------------------------------
# Raw Mobil-O-Graph 24h PWA export parsing and conversion.
# Layout: single sheet, key/value metadata rows on top, header row containing
# "Number"/"Systole", then the measurement table.
# --------------------------------------------------------------------------

# Some device .xls exports carry a damaged OLE2 stream that readxl's libxls
# refuses to open ("libxls error: Unable to open file"), although Python's
# xlrd reads them fine. This bridge exports the first sheet to a temp CSV via
# Python/xlrd, which the parser then treats like a plain cell matrix.
XLS_BRIDGE_PY <- paste(c(
  "import sys, csv",
  "import xlrd",
  "path_in, path_out = sys.argv[1], sys.argv[2]",
  "wb = xlrd.open_workbook(path_in, on_demand=True)",
  "sh = wb.sheet_by_index(0)",
  "def fmt(cell):",
  "    if cell.ctype == xlrd.XL_CELL_DATE:",
  "        dt = xlrd.xldate_as_datetime(cell.value, wb.datemode)",
  "        return dt.strftime('%Y-%m-%d %H:%M:%S.%f')",
  "    if cell.ctype == xlrd.XL_CELL_NUMBER:",
  "        v = cell.value",
  "        return int(v) if v == int(v) else v",
  "    return cell.value",
  "with open(path_out, 'w', newline='', encoding='utf-8-sig') as f:",
  "    w = csv.writer(f)",
  "    for r in range(sh.nrows):",
  "        w.writerow([fmt(sh.cell(r, c)) for c in range(sh.ncols)])"
), collapse = "\n")

find_python <- function() {
  for (cmd in c("python", "python3", "py")) {
    p <- Sys.which(cmd)
    if (nzchar(p) && file.exists(p)) return(p)
  }
  base_dirs <- c(
    list.files("C:/", pattern = "^Python\\d+$", full.names = TRUE),
    list.files(file.path(Sys.getenv("LOCALAPPDATA"), "Programs", "Python"),
               full.names = TRUE, include.dirs = TRUE),
    list.files("C:/Program Files", pattern = "^Python\\d+$", full.names = TRUE)
  )
  for (d in base_dirs) {
    exe <- file.path(d, "python.exe")
    if (file.exists(exe)) return(exe)
  }
  NULL
}

# Character matrix of the first sheet: readxl first, Python/xlrd bridge as a
# fallback for damaged legacy .xls files.
read_sheet_cell_matrix <- function(path) {
  res <- tryCatch({
    sheets <- readxl::excel_sheets(path)
    raw <- suppressWarnings(readxl::read_excel(path, sheet = sheets[1], col_names = FALSE))
    as.matrix(raw)
  }, error = function(e) e)
  if (!inherits(res, "error")) return(res)

  if (!grepl("\\.xls$", tolower(path))) stop(res)

  py <- find_python()
  if (is.null(py)) {
    stop("Unable to read this file: readxl failed and no Python/xlrd fallback is available. ",
         "无法读取该文件：readxl 失败且没有可用的 Python/xlrd 回退方案。")
  }
  csv_out <- tempfile(fileext = ".csv")
  script <- tempfile(fileext = ".py")
  ok <- tryCatch({
    writeLines(XLS_BRIDGE_PY, script, useBytes = TRUE)
    status <- system2(py, c(shQuote(script), shQuote(path), shQuote(csv_out)),
                      stdout = FALSE, stderr = FALSE)
    isTRUE(status == 0) && file.exists(csv_out) && file.info(csv_out)$size > 0
  }, error = function(e) FALSE)
  if (!isTRUE(ok)) {
    unlink(c(script, csv_out))
    stop("Unable to read this file: readxl failed and the Python/xlrd bridge failed. ",
         "无法读取该文件：readxl 与 Python/xlrd 回退均失败。")
  }
  df <- tryCatch(
    suppressWarnings(read.csv(csv_out, header = FALSE, stringsAsFactors = FALSE,
                              na.strings = character(0), colClasses = "character",
                              fileEncoding = "UTF-8-BOM")),
    error = function(e) NULL)
  unlink(c(script, csv_out))
  if (is.null(df)) stop("Unable to parse the fallback CSV produced by the Python bridge.")
  as.matrix(df)
}

# Header cells of the data block differ between firmware/localisation versions:
# the running-index column is "Number" in most exports but "No." / "No" / "Nr."
# in others (and "序号"/"编号" in localized ones). Normalize case, whitespace
# and trailing punctuation before comparing so the header row is found either
# way. Only the measurement columns are read downstream, so the index column
# keeps whatever label the export happens to use.
header_cell_key <- function(x) {
  x <- trimws(as.character(x))
  x <- gsub("[[:space:][:punct:]]", "", x)
  is_ascii <- !grepl("[^\\x00-\\x7F]", x, perl = TRUE)
  x[is_ascii] <- tolower(x[is_ascii])
  x
}
ABPM_INDEX_LABELS <- c("number", "no", "nr", "num", "index", "序号", "编号")
ABPM_SYSTOLE_LABELS <- c("systole", "sbp", "systolic", "收缩压")

read_abpm_pwa_xls <- function(path) {
  if (!file.exists(path)) stop("File not found: ", path)
  vals_mat <- read_sheet_cell_matrix(path)
  sheet_name <- tryCatch(readxl::excel_sheets(path)[1], error = function(e) NA_character_)
  header_row <- NA_integer_
  for (i in seq_len(nrow(vals_mat))) {
    keys <- header_cell_key(vals_mat[i, ])
    has_systole <- any(keys %in% ABPM_SYSTOLE_LABELS, na.rm = TRUE)
    # Primary match: index column + Systole. Fallback: Systole + Date, so an
    # export whose index column uses an unknown label still parses.
    if (has_systole && (any(keys %in% ABPM_INDEX_LABELS, na.rm = TRUE) ||
                        any(keys %in% c("date", "datetime", "日期"), na.rm = TRUE))) {
      header_row <- i
      break
    }
  }
  if (is.na(header_row)) {
    stop("Could not locate the data header row ('Number'/'No.' + 'Systole') in: ", basename(path))
  }
  meta <- list()
  if (header_row > 1) {
    for (i in seq_len(header_row - 1)) {
      k <- as.character(vals_mat[i, 1])
      v <- as.character(vals_mat[i, 2])
      if (!is.na(k) && nzchar(trimws(k))) {
        meta[[trimws(k)]] <- if (is.na(v)) NA_character_ else trimws(v)
      }
    }
  }
  header <- as.character(vals_mat[header_row, ])
  data_raw <- as.data.frame(
    vals_mat[seq.int(header_row + 1L, nrow(vals_mat)), , drop = FALSE],
    stringsAsFactors = FALSE
  )
  names(data_raw) <- header
  data_raw[data_raw == ""] <- NA
  list(sheet = sheet_name, meta = meta, header_row = header_row, data = data_raw)
}

parse_abpm_datetime <- function(x) {
  if (inherits(x, "POSIXct")) return(as.POSIXct(x))
  if (inherits(x, "Date")) return(as.POSIXct(x))
  xc <- as.character(x)
  out <- rep(as.POSIXct(NA, tz = "UTC"), length(xc))
  for (fmt in c("%Y-%m-%d %H:%M:%OS", "%Y-%m-%d %H:%M:%S",
                "%d.%m.%Y %H:%M:%S", "%d.%m.%Y %H:%M", "%Y-%m-%d")) {
    nas <- is.na(out) & !is.na(xc)
    if (!any(nas)) break
    parsed <- suppressWarnings(as.POSIXct(xc[nas], format = fmt, tz = "UTC"))
    out[nas] <- parsed
  }
  out
}

# Convert one raw export into the canonical long table
# MASKID, Time, SBP, DBP, HR, PP, MAP  (Time = HHMM+XD, day offset relative to
# the first VALID reading). Device-measured pPP/MAP are kept; failed readings
# (SBP/DBP/HR <= 0 or missing) are dropped and counted.
# MASKID priority: maskid_override (user input) > metadata ID > the original
# file name (file_label, e.g. the uploaded file's name) > local path stem.
xls_to_abpm_long <- function(path, maskid_override = NULL, file_label = NULL) {
  parsed <- read_abpm_pwa_xls(path)
  d <- parsed$data
  need <- c("Date", "Systole", "Diastole", "Hr")
  missing_cols <- setdiff(need, names(d))
  if (length(missing_cols) > 0) {
    stop("Missing required columns (", paste(missing_cols, collapse = ", "),
         ") in: ", basename(path))
  }
  d$`_dt` <- parse_abpm_datetime(d$Date)
  d$SBP <- suppressWarnings(as.numeric(as.character(d$Systole)))
  d$DBP <- suppressWarnings(as.numeric(as.character(d$Diastole)))
  d$HR  <- suppressWarnings(as.numeric(as.character(d$Hr)))
  d$PP  <- if ("pPP" %in% names(d)) suppressWarnings(as.numeric(as.character(d$pPP))) else NA_real_
  d$MAP <- if ("MAP" %in% names(d)) suppressWarnings(as.numeric(as.character(d$MAP))) else NA_real_

  n_total <- nrow(d)
  bad_time <- is.na(d$`_dt`)
  valid <- !bad_time &
    is.finite(d$SBP) & is.finite(d$DBP) & is.finite(d$HR) &
    d$SBP > 0 & d$DBP > 0 & d$HR > 0
  n_bad_time <- sum(bad_time)
  n_zero <- sum(!bad_time & !valid)

  v <- d[valid, , drop = FALSE]
  v <- v[order(v$`_dt`), , drop = FALSE]
  out <- data.frame(
    MASKID = rep(NA_character_, nrow(v)),
    Time = rep(NA_character_, nrow(v)),
    SBP = v$SBP, DBP = v$DBP, HR = v$HR, PP = v$PP, MAP = v$MAP,
    stringsAsFactors = FALSE
  )
  auto_id <- NA_character_
  if (nrow(v) > 0) {
    first_date <- as.Date(v$`_dt`[1])
    day_off <- as.integer(as.Date(v$`_dt`) - first_date)
    out$Time <- sprintf("%02d%02d+%dD",
                        as.integer(format(v$`_dt`, "%H")),
                        as.integer(format(v$`_dt`, "%M")),
                        day_off)
    auto_id <- if (!is.null(maskid_override) && !is.na(maskid_override) &&
                   nzchar(trimws(maskid_override))) {
      trimws(maskid_override)
    } else {
      meta_id <- parsed$meta[["ID"]]
      if (!is.null(meta_id) && !is.na(meta_id) && nzchar(trimws(meta_id))) {
        trimws(meta_id)
      } else {
        label <- file_label %||% basename(path)
        tools::file_path_sans_ext(label)
      }
    }
    out$MASKID <- auto_id
  }
  list(
    data = out,
    meta = parsed$meta,
    sheet = parsed$sheet,
    n_total = n_total,
    n_valid = nrow(v),
    n_dropped_zero = n_zero,
    n_dropped_bad_time = n_bad_time,
    first_valid = if (nrow(v) > 0) format(v$`_dt`[1], "%Y-%m-%d %H:%M:%S") else NA_character_,
    last_valid = if (nrow(v) > 0) format(v$`_dt`[nrow(v)], "%Y-%m-%d %H:%M:%S") else NA_character_,
    auto_maskid = auto_id
  )
}

# Unit label for display purposes (charts, summaries, cards)
metric_unit <- function(metric) {
  switch(toupper(as.character(metric)),
         SBP = "mmHg", DBP = "mmHg", PP = "mmHg", MAP = "mmHg",
         HR = "bpm", GLU = "mmol/L",
         "")
}

sanitize_filename <- function(x) {
  x <- gsub("[^A-Za-z0-9_.-]", "_", x)
  x <- gsub("_+", "_", x)
  x <- sub("^_|_$", "", x)
  if (!nzchar(x)) "abpm_export"
  x
}

# Write the selected CSV export items into one zip archive at `file`.
# Returns TRUE when at least one table was packed. The `zip` package is
# preferred: it bundles libzip, so no external zip executable is needed and no
# setwd() is involved (utils::zip() needs zip.exe on Windows, which a plain R
# install does not ship - it then fails with '"zip"' not found and writes no
# archive). utils::zip() is kept only as a fallback for installations without
# the package.
write_export_zip <- function(items, file) {
  tmpd <- tempfile("abpm_export_")
  dir.create(tmpd, recursive = TRUE)
  paths <- character(0)
  for (item in items) {
    for (nm in names(item$csv)) {
      p <- file.path(tmpd, paste0(sanitize_filename(nm), ".csv"))
      con <- base::file(p, open = "wb")
      writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)   # UTF-8 BOM so Excel reads CJK
      write.table(item$csv[[nm]], con, sep = ",", row.names = FALSE,
                  col.names = TRUE, qmethod = "double", na = "")
      close(con)
      paths <- c(paths, p)
    }
  }
  if (length(paths) == 0) {
    unlink(tmpd, recursive = TRUE)
    return(FALSE)
  }
  if (isTRUE(has_zip)) {
    zip::zip(zipfile = file, files = basename(paths), root = tmpd,
             include_directories = FALSE)
  } else {
    old_wd <- setwd(tmpd)
    on.exit(setwd(old_wd), add = TRUE)
    utils::zip(zipfile = normalizePath(file, mustWork = FALSE), files = basename(paths))
  }
  TRUE
}

# --------------------------------------------------------------------------
# Glucose (CGM) raw export parsing.
# Typical layout: one sheet whose header row contains the glucose column name
# (血糖值/GLU/GLUCOSE) and a time column name (采集时间/TIME/DATE), plus
# metadata cells such as 机构名称：... 姓名：... 设备名称：... in the same
# row. Data rows: glucose value (mmol/L) and a full date-time. Readings may
# be in descending order and may span many days (+0D..+15D).
# MASKID priority: override > device serial (设备名称) > file label > path.
# --------------------------------------------------------------------------
glu_find_header_row <- function(vals_mat) {
  for (i in seq_len(nrow(vals_mat))) {
    vals <- as.character(vals_mat[i, ])
    has_glu <- any(grepl("GLU|GLUCOSE|血糖值|血糖", vals, ignore.case = TRUE))
    has_time <- any(grepl("时间|TIME|DATE", vals, ignore.case = TRUE))
    if (has_glu && has_time) return(i)
  }
  NA_integer_
}

glu_parse_datetime <- function(x) {
  if (inherits(x, "POSIXct")) return(as.POSIXct(x))
  xc <- as.character(x)
  out <- rep(as.POSIXct(NA, tz = "UTC"), length(xc))
  for (fmt in c("%Y-%m-%d %H:%M:%OS", "%Y-%m-%d %H:%M:%S",
                "%Y/%m/%d %H:%M:%S", "%Y/%m/%d %H:%M", "%Y-%m-%d")) {
    nas <- is.na(out) & !is.na(xc)
    if (!any(nas)) break
    parsed <- suppressWarnings(as.POSIXct(xc[nas], format = fmt, tz = "UTC"))
    out[nas] <- parsed
  }
  out
}

# Convert a glucose cell matrix (or raw CSV text) into the canonical long
# table MASKID,Time,GLU. Returns the same structure as xls_to_abpm_long.
glu_raw_to_long <- function(path = NULL, text = NULL,
                            maskid_override = NULL, file_label = NULL) {
  if (!is.null(path) && file.exists(path)) {
    vals_mat <- read_sheet_cell_matrix(path)
  } else if (!is.null(text) && nzchar(text)) {
    df <- suppressWarnings(read.csv(text = text, header = FALSE,
                                    stringsAsFactors = FALSE,
                                    na.strings = character(0),
                                    colClasses = "character"))
    vals_mat <- as.matrix(df)
  } else {
    stop("No glucose source provided (need a file path or CSV text).")
  }

  header_row <- glu_find_header_row(vals_mat)
  if (is.na(header_row)) {
    stop("Could not locate the glucose header row (GLU/血糖值 + time column).")
  }
  header <- as.character(vals_mat[header_row, ])
  meta_row <- as.character(vals_mat[header_row, ])
  device_serial <- NA_character_
  for (cell in meta_row) {
    if (!is.na(cell) && grepl("设备名称", cell)) {
      device_serial <- trimws(sub("^.*设备名称[:：]", "", cell))
    }
  }

  glu_col <- which(grepl("GLU|GLUCOSE|血糖值|血糖|葡萄糖", header, ignore.case = TRUE))
  time_col <- which(grepl("采集时间|时间|^TIME$|^DATE$|^DT$", header, ignore.case = TRUE))
  if (length(glu_col) == 0 || length(time_col) == 0) {
    stop("Glucose export must contain a glucose column and a time column.")
  }
  glu_col <- glu_col[1]
  time_col <- time_col[1]

  data_raw <- as.data.frame(
    vals_mat[seq.int(header_row + 1L, nrow(vals_mat)), , drop = FALSE],
    stringsAsFactors = FALSE
  )
  data_raw[data_raw == ""] <- NA

  n_total <- nrow(data_raw)
  d_glu <- suppressWarnings(as.numeric(as.character(data_raw[[glu_col]])))
  d_dt <- glu_parse_datetime(data_raw[[time_col]])
  valid <- is.finite(d_glu) & !is.na(d_dt)
  n_invalid <- sum(!valid)

  v_glu <- d_glu[valid]
  v_dt <- d_dt[valid]
  ord <- order(v_dt)
  v_glu <- v_glu[ord]
  v_dt <- v_dt[ord]

  out <- data.frame(MASKID = rep(NA_character_, length(v_glu)),
                    Time = rep(NA_character_, length(v_glu)),
                    GLU = v_glu, stringsAsFactors = FALSE)
  auto_id <- NA_character_
  if (length(v_glu) > 0) {
    first_date <- as.Date(v_dt[1])
    day_off <- as.integer(as.Date(v_dt) - first_date)
    out$Time <- sprintf("%02d%02d+%dD",
                        as.integer(format(v_dt, "%H")),
                        as.integer(format(v_dt, "%M")),
                        day_off)
    auto_id <- if (!is.null(maskid_override) && !is.na(maskid_override) &&
                   nzchar(trimws(maskid_override))) {
      trimws(maskid_override)
    } else if (!is.na(device_serial) && nzchar(device_serial)) {
      device_serial
    } else {
      label <- file_label %||% if (!is.null(path)) basename(path) else "glucose_sample"
      tools::file_path_sans_ext(label)
    }
    out$MASKID <- auto_id
  }
  list(
    data = out,
    meta = list(device_serial = device_serial),
    sheet = NA_character_,
    n_total = n_total,
    n_valid = length(v_glu),
    n_dropped_zero = 0,
    n_dropped_bad_time = n_invalid,
    first_valid = if (length(v_glu) > 0) format(v_dt[1], "%Y-%m-%d %H:%M:%S") else NA_character_,
    last_valid = if (length(v_glu) > 0) format(v_dt[length(v_dt)], "%Y-%m-%d %H:%M:%S") else NA_character_,
    auto_maskid = auto_id
  )
}
