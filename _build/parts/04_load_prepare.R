# --- 2.2 Data Loading and Preparation (relaxed required columns, bilingual) ---
# Required: MASKID + Time and at least one of SBP/DBP/HR/PP/MAP.
# PP/MAP are derived only where missing; imported (device-measured) values
# are kept untouched.
load_and_prepare_data <- function(df, lang = "en") {
  required_cols <- c("MASKID", "Time")
  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0) {
    stop(tr(lang, "err_missing_cols"), ": ", paste(missing_cols, collapse = ", "))
  }
  measurement_cols <- intersect(c("SBP", "DBP", "HR", "PP", "MAP", "GLU"), colnames(df))
  if (length(measurement_cols) == 0) {
    warning(tr(lang, "warn_no_measurement"), call. = FALSE)
  }

  df$MASKID <- as.character(df$MASKID)
  df$Time <- as.character(df$Time)

  # Convert measurement columns to numeric, warning about introduced NAs
  for (col in measurement_cols) {
    if (!is.numeric(df[[col]])) {
      original_values <- df[[col]]
      suppressWarnings({ df[[col]] <- as.numeric(as.character(df[[col]])) })
      na_introduced <- is.na(df[[col]]) & !is.na(original_values) & original_values != ""
      if (any(na_introduced)) {
        warning(tr(lang, "warn_na_introduced"), " '", col, "'. ",
                tr(lang, "warn_check_data"), call. = FALSE)
      }
    }
  }

  # Derive PP/MAP only where missing, and only when SBP/DBP are available
  if ("SBP" %in% names(df) && "DBP" %in% names(df) &&
      is.numeric(df$SBP) && is.numeric(df$DBP)) {
    if (!"PP" %in% names(df)) df$PP <- NA_real_
    df <- df %>% mutate(PP = ifelse(is.na(PP) & !is.na(SBP) & !is.na(DBP), SBP - DBP, PP))
    if (!"MAP" %in% names(df)) df$MAP <- NA_real_
    df <- df %>% mutate(MAP = ifelse(is.na(MAP) & !is.na(SBP) & !is.na(DBP), DBP + (1/3) * (SBP - DBP), MAP))
  }

  # Parse time and add derived time columns
  df <- df %>%
    mutate(
      Total_Minutes = sapply(Time, time_string_to_minutes),
      Day = ifelse(!is.na(Total_Minutes), Total_Minutes %/% (24*60), NA_integer_),
      Hour = ifelse(!is.na(Total_Minutes), (Total_Minutes %% (24*60)) %/% 60, NA_integer_)
    )
  if (any(is.na(df$Total_Minutes))) warning(tr(lang, "warn_bad_time"), call. = FALSE)

  # Remove rows with a missing ID/time, or with no usable measurement at all.
  # Rows are kept whenever at least one mapped measurement has a value, so
  # SBP-only inputs (e.g. a 3-column CSV) survive even though other metric
  # columns are absent.
  essential <- c("MASKID", "Total_Minutes")
  rows_before <- nrow(df)
  drop_core <- rowSums(is.na(df[, essential, drop = FALSE])) > 0
  if (length(measurement_cols) > 0) {
    any_measure <- rowSums(!is.na(df[, measurement_cols, drop = FALSE])) > 0
  } else {
    # No measurement columns at all: keep every row (only ID/Time required).
    any_measure <- rep(TRUE, nrow(df))
  }
  drop <- drop_core | !any_measure
  if (any(drop)) df <- df[!drop, , drop = FALSE]
  if (nrow(df) < rows_before) {
    warning(rows_before - nrow(df), " ", tr(lang, "warn_rows_removed"), call. = FALSE)
  }

  # Select and order columns
  cols_order <- c("MASKID", "Time", "Total_Minutes", "Day", "Hour",
                  "SBP", "DBP", "HR", "PP", "MAP")
  other_cols <- setdiff(colnames(df), cols_order)
  cols_order_present <- intersect(cols_order, colnames(df))
  df %>% select(all_of(cols_order_present), all_of(other_cols))
}
