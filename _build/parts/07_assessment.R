# --- 2.9 Full export and four-dimensional personalized assessment (bilingual) ---
result_scalar <- function(metric_results, period_key, metric, field, patient_id) {
  table <- metric_results[[period_key]][[metric]]
  column <- paste0(metric, "_", field)
  if (is.null(table) || !is.data.frame(table) || !all(c("MASKID", column) %in% names(table))) return(NA_real_)
  value <- table[table$MASKID == patient_id, column, drop = TRUE]
  if (length(value) != 1) return(NA_real_)
  suppressWarnings(as.numeric(value))
}

collect_result_patients <- function(metric_results) {
  ids <- unlist(lapply(metric_results, function(period) {
    unlist(lapply(period, function(table) if (is.data.frame(table) && "MASKID" %in% names(table)) as.character(table$MASKID) else character(0)))
  }))
  sort(unique(ids))
}

build_full_results_wide <- function(metric_results) {
  patient_ids <- collect_result_patients(metric_results)
  result <- data.frame(MASKID = patient_ids, stringsAsFactors = FALSE)
  period_prefix <- c(day = "day", night = "night", `24h` = "24h_unified", `24h_segmented` = "24h_segmented")
  for (period_key in names(period_prefix)) {
    for (metric in names(metric_results[[period_key]])) {
      table <- metric_results[[period_key]][[metric]]
      if (is.null(table) || !is.data.frame(table) || !"MASKID" %in% names(table)) next
      renamed <- table
      metric_columns <- setdiff(names(renamed), "MASKID")
      names(renamed)[match(metric_columns, names(renamed))] <- paste0(period_prefix[[period_key]], "_", metric_columns)
      result <- full_join(result, renamed, by = "MASKID")
    }
  }
  result %>% arrange(MASKID)
}

finite_min <- function(x) if (any(is.finite(x))) min(x[is.finite(x)]) else NA_real_
finite_max <- function(x) if (any(is.finite(x))) max(x[is.finite(x)]) else NA_real_
format_pair <- function(a, b, digits = 1, suffix = "") {
  fmt <- function(x) if (is.finite(x)) paste0(format(round(x, digits), nsmall = digits), suffix) else "N/A"
  paste0("SBP ", fmt(a), " / DBP ", fmt(b))
}

build_personalized_assessment <- function(metric_results, patient_id, lang = "en") {
  period_labels <- c(tr(lang, "period_24h"), tr(lang, "period_day"), tr(lang, "period_night"))
  periods <- setNames(c("24h_segmented", "day", "night"), period_labels)
  period_means <- lapply(periods, function(period_key) c(
    SBP = result_scalar(metric_results, period_key, "SBP", "mean", patient_id),
    DBP = result_scalar(metric_results, period_key, "DBP", "mean", patient_id)
  ))
  cn <- tr(lang, "guideline_cn")
  guideline_profiles <- list(
    `ESC 2024` = list(`24h` = c(130, 80), `day` = c(135, 85), `night` = c(120, 70)),
    `AHA/ACC 2025` = list(`24h` = c(125, 75), `day` = c(130, 80), `night` = c(110, 65)),
    `China 2024` = list(`24h` = c(130, 80), `day` = c(135, 85), `night` = c(120, 70))
  )
  names(guideline_profiles) <- c("ESC 2024", "AHA/ACC 2025", cn)
  # profile period keys must match the localized period labels
  profile_period_key <- setNames(c("24h", "day", "night"), period_labels)

  guideline_rows <- list()
  for (guideline_name in names(guideline_profiles)) {
    for (period_name in period_labels) {
      observed <- period_means[[period_name]]
      threshold <- guideline_profiles[[guideline_name]][[profile_period_key[[period_name]]]]
      avail_sbp <- is.finite(observed[["SBP"]])
      avail_dbp <- is.finite(observed[["DBP"]])
      # Judge whether this period meets the guideline's hypertension
      # definition, using whichever metrics are available. "Insufficient
      # data" is only reported when neither SBP nor DBP exists.
      status <- if (!avail_sbp && !avail_dbp) {
        tr(lang, "status_insufficient")
      } else if ((avail_sbp && observed[["SBP"]] >= threshold[1]) ||
                 (avail_dbp && observed[["DBP"]] >= threshold[2])) {
        tr(lang, "status_ht_yes")
      } else {
        tr(lang, "status_ht_no")
      }
      guideline_rows[[length(guideline_rows) + 1]] <- data.frame(
        GL = guideline_name,
        PR = period_name,
        OB = format_pair(observed[["SBP"]], observed[["DBP"]], digits = 1, suffix = " mmHg"),
        TH = paste0(threshold[1], "/", threshold[2], " mmHg"),
        JU = status,
        stringsAsFactors = FALSE
      )
    }
  }
  guideline_table <- bind_rows(guideline_rows)
  names(guideline_table) <- c(tr(lang, "col_guideline"), tr(lang, "col_period"),
                              tr(lang, "col_observed"), tr(lang, "col_threshold"),
                              tr(lang, "col_ht_judgment"))

  mean_primary_bad <- any(vapply(period_labels, function(period_name) {
    observed <- period_means[[period_name]]
    threshold <- guideline_profiles[[cn]][[profile_period_key[[period_name]]]]
    avail_sbp <- is.finite(observed[["SBP"]])
    avail_dbp <- is.finite(observed[["DBP"]])
    (avail_sbp || avail_dbp) &&
      ((avail_sbp && observed[["SBP"]] >= threshold[1]) ||
         (avail_dbp && observed[["DBP"]] >= threshold[2]))
  }, logical(1)))

  sbp_sd <- result_scalar(metric_results, "24h_segmented", "SBP", "SD", patient_id)
  dbp_sd <- result_scalar(metric_results, "24h_segmented", "DBP", "SD", patient_id)
  sbp_arv <- result_scalar(metric_results, "24h_segmented", "SBP", "ARV", patient_id)
  dbp_arv <- result_scalar(metric_results, "24h_segmented", "DBP", "ARV", patient_id)
  variability_bad <- finite_max(c(sbp_sd, dbp_sd, sbp_arv, dbp_arv)) >= 10

  sbp_ttr <- result_scalar(metric_results, "24h_segmented", "SBP", "TTR", patient_id)
  dbp_ttr <- result_scalar(metric_results, "24h_segmented", "DBP", "TTR", patient_id)
  ttr_worst <- finite_min(c(sbp_ttr, dbp_ttr))
  ttr_status <- if (!is.finite(ttr_worst)) {
    tr(lang, "status_insufficient")
  } else if (ttr_worst >= 75) {
    tr(lang, "ttr_good")
  } else if (ttr_worst >= 50) {
    tr(lang, "ttr_fair")
  } else {
    tr(lang, "ttr_poor")
  }

  burden_values <- c(
    result_scalar(metric_results, "24h_segmented", "SBP", "hyper_Burden", patient_id),
    result_scalar(metric_results, "24h_segmented", "DBP", "hyper_Burden", patient_id),
    result_scalar(metric_results, "24h_segmented", "SBP", "hypo_Burden", patient_id),
    result_scalar(metric_results, "24h_segmented", "DBP", "hypo_Burden", patient_id)
  )
  burden_worst <- finite_max(burden_values)
  burden_bad <- is.finite(burden_worst) && burden_worst > 5

  mean_24_sbp <- period_means[[tr(lang, "period_24h")]][["SBP"]]
  mean_24_dbp <- period_means[[tr(lang, "period_24h")]][["DBP"]]
  max_sbp <- result_scalar(metric_results, "24h_segmented", "SBP", "max_value", patient_id)
  max_dbp <- result_scalar(metric_results, "24h_segmented", "DBP", "max_value", patient_id)
  urgent_flag <- (is.finite(max_sbp) && max_sbp >= 180) || (is.finite(max_dbp) && max_dbp >= 120) ||
    (is.finite(mean_24_sbp) && mean_24_sbp >= 145) || (is.finite(mean_24_dbp) && mean_24_dbp >= 90)

  followup_key <- if (urgent_flag) {
    "urgent"
  } else if (mean_primary_bad || isTRUE(variability_bad) ||
             (!is.na(ttr_status) && ttr_status %in% c(tr(lang, "ttr_fair"), tr(lang, "ttr_poor"))) ||
             burden_bad) {
    "elective"
  } else {
    "routine"
  }

  suggestions <- character(0)
  if (mean_primary_bad) suggestions <- c(suggestions, tr(lang, "sugg_mean"))
  if (isTRUE(variability_bad)) suggestions <- c(suggestions, tr(lang, "sugg_var"))
  if (is.finite(ttr_worst) && ttr_worst < 75) {
    suggestions <- c(suggestions, if (ttr_worst < 50) tr(lang, "sugg_ttr_low") else tr(lang, "sugg_ttr_mid"))
  }
  if (burden_bad) suggestions <- c(suggestions, tr(lang, "sugg_burden"))
  if (length(suggestions) == 0) suggestions <- c(suggestions, tr(lang, "sugg_ok"))
  suggestions <- c(suggestions, tr(lang, "sugg_emergency"))

  dimension_table <- data.frame(
    DIM = c(tr(lang, "dim_mean"), tr(lang, "dim_sdarv"), tr(lang, "dim_ttr"), tr(lang, "dim_burden")),
    CUR = c(
      format_pair(mean_24_sbp, mean_24_dbp, 1, " mmHg (24h)"),
      paste0("SD: ", format_pair(sbp_sd, dbp_sd, 1, " mmHg"), "; ARV: ", format_pair(sbp_arv, dbp_arv, 1, " mmHg")),
      format_pair(sbp_ttr, dbp_ttr, 1, "%"),
      if (is.finite(burden_worst)) paste0(tr(lang, "worst_value"), " ", round(burden_worst, 1), "%") else "N/A"
    ),
    CRI = c(tr(lang, "crit_mean"), tr(lang, "crit_var"), tr(lang, "crit_ttr"), tr(lang, "crit_burden")),
    JUD = c(
      if (mean_primary_bad) tr(lang, "dim_bad_mean") else tr(lang, "dim_ok_mean"),
      if (isTRUE(variability_bad)) tr(lang, "dim_bad_var") else tr(lang, "dim_ok_var"),
      ttr_status,
      if (burden_bad) tr(lang, "dim_bad_burden") else if (is.finite(burden_worst)) tr(lang, "dim_ok_burden") else tr(lang, "status_insufficient")
    ),
    stringsAsFactors = FALSE
  )
  names(dimension_table) <- c(tr(lang, "col_dimension"), tr(lang, "col_current"),
                              tr(lang, "col_criteria"), tr(lang, "col_judgment"))

  list(
    MASKID = patient_id,
    followup = tr(lang, paste0("followup_", followup_key)),
    followup_key = followup_key,
    dimensions = dimension_table,
    guidelines = guideline_table,
    suggestions = suggestions,
    export_row = data.frame(
      MASKID = patient_id,
      Followup_Recommendation = tr(lang, paste0("followup_", followup_key)),
      Mean_Assessment = dimension_table[[tr(lang, "col_judgment")]][1],
      SD_ARV_Assessment = dimension_table[[tr(lang, "col_judgment")]][2],
      TTR_Assessment = dimension_table[[tr(lang, "col_judgment")]][3],
      Burden_Assessment = dimension_table[[tr(lang, "col_judgment")]][4],
      Personalized_Advice = paste(suggestions, collapse = "; "),
      stringsAsFactors = FALSE
    )
  )
}

build_all_personalized_assessments <- function(metric_results, lang = "en") {
  ids <- collect_result_patients(metric_results)
  if (length(ids) == 0) return(data.frame())
  bind_rows(lapply(ids, function(id) build_personalized_assessment(metric_results, id, lang = lang)$export_row))
}
