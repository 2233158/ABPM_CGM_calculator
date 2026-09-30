# --- 2.10 Glucose (CGM) assessment: ADA 2025 & China CDS guidelines ---
# Targets (mmol/L): TIR 3.9-10.0, TAR > 10.0, TBR < 3.9, CV <= 36%,
# mean <= 8.6 (~A1c 7.0% eAG). Both the ADA Standards of Care and the China
# diabetes guideline use these consensus targets. Note: the engine uses a
# single target range per period, so the stricter TBR<3.0 level is not
# computed separately (see the help note).
GLUCOSE_TARGETS <- list(
  mean_upper = 8.6,
  cv_upper = 36,
  tir_lower = 70,
  tar_upper = 25,
  tbr_upper = 4,
  urgent_mean = 11.1,
  urgent_max = 16.7,
  urgent_min = 2.8
)

glu_scalar <- function(metric_results, period_key, field, patient_id) {
  result_scalar(metric_results, period_key, "GLU", field, patient_id)
}

fmt_glu_num <- function(x, digits = 1, suffix = "") {
  if (length(x) != 1 || is.na(x) || !is.finite(x)) return("N/A")
  paste0(format(round(x, digits), nsmall = digits), suffix)
}

build_glucose_assessment <- function(metric_results, patient_id, lang = "en") {
  period_labels <- c(tr(lang, "period_24h"), tr(lang, "period_day"), tr(lang, "period_night"))
  period_keys <- setNames(c("24h", "day", "night"), period_labels)

  g_mean <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "mean", patient_id), numeric(1))
  g_tir <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "TTR", patient_id), numeric(1))
  g_tar <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "TOTR", patient_id), numeric(1))
  g_tbr <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "TUTR", patient_id), numeric(1))
  g_cv <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "CV", patient_id), numeric(1))
  g_sd <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "SD", patient_id), numeric(1))
  g_max <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "max_value", patient_id), numeric(1))
  g_min <- vapply(period_keys, function(pk) glu_scalar(metric_results, pk, "min_value", patient_id), numeric(1))

  guideline_names <- c("ADA 2025", tr(lang, "glu_guideline_cn"))
  guideline_rows <- list()
  for (gn in guideline_names) {
    for (pn in period_labels) {
      m <- g_mean[[pn]]; ti <- g_tir[[pn]]; cv <- g_cv[[pn]]
      avail <- c(is.finite(m), is.finite(ti), is.finite(cv))
      if (!any(avail)) {
        st <- tr(lang, "status_insufficient")
      } else {
        ok_m <- !is.finite(m) || m <= GLUCOSE_TARGETS$mean_upper
        ok_t <- !is.finite(ti) || ti >= GLUCOSE_TARGETS$tir_lower
        ok_c <- !is.finite(cv) || cv <= GLUCOSE_TARGETS$cv_upper
        st <- if (ok_m && ok_t && ok_c) tr(lang, "glu_status_reached") else tr(lang, "glu_status_below")
      }
      guideline_rows[[length(guideline_rows) + 1]] <- data.frame(
        GL = gn, PR = pn,
        ME = paste0(fmt_glu_num(m, 1), " mmol/L (\u2264", GLUCOSE_TARGETS$mean_upper, ")"),
        TI = paste0(fmt_glu_num(ti, 1), "% (\u2265", GLUCOSE_TARGETS$tir_lower, "%)"),
        CV = paste0(fmt_glu_num(cv, 1), "% (\u2264", GLUCOSE_TARGETS$cv_upper, "%)"),
        JU = st, stringsAsFactors = FALSE)
    }
  }
  guideline_table <- bind_rows(guideline_rows)
  names(guideline_table) <- c(tr(lang, "col_guideline"), tr(lang, "col_period"),
                              tr(lang, "glu_col_mean"), tr(lang, "glu_col_tir"),
                              tr(lang, "glu_col_cv"), tr(lang, "glu_col_judgment"))

  overall <- period_labels[1]
  mean_bad <- any(is.finite(g_mean) & g_mean > GLUCOSE_TARGETS$mean_upper)
  cv_worst <- finite_max(g_cv)
  var_bad <- is.finite(cv_worst) && cv_worst > GLUCOSE_TARGETS$cv_upper
  tir_overall <- g_tir[[overall]]
  tir_status <- if (!is.finite(tir_overall)) {
    tr(lang, "status_insufficient")
  } else if (tir_overall >= GLUCOSE_TARGETS$tir_lower) {
    tr(lang, "ttr_good")
  } else if (tir_overall >= 50) {
    tr(lang, "ttr_fair")
  } else {
    tr(lang, "ttr_poor")
  }
  tar_overall <- g_tar[[overall]]
  tbr_overall <- g_tbr[[overall]]
  burden_bad <- (is.finite(tar_overall) && tar_overall > GLUCOSE_TARGETS$tar_upper) ||
    (is.finite(tbr_overall) && tbr_overall > GLUCOSE_TARGETS$tbr_upper)

  urgent_flag <- (is.finite(g_max[[overall]]) && g_max[[overall]] >= GLUCOSE_TARGETS$urgent_max) ||
    (is.finite(g_min[[overall]]) && g_min[[overall]] <= GLUCOSE_TARGETS$urgent_min) ||
    (is.finite(g_mean[[overall]]) && g_mean[[overall]] >= GLUCOSE_TARGETS$urgent_mean) ||
    (is.finite(tbr_overall) && tbr_overall >= GLUCOSE_TARGETS$tbr_upper)

  followup_key <- if (urgent_flag) {
    "urgent"
  } else if (mean_bad || var_bad ||
             (!is.na(tir_status) && tir_status %in% c(tr(lang, "ttr_fair"), tr(lang, "ttr_poor"))) ||
             burden_bad) {
    "elective"
  } else {
    "routine"
  }

  # Advice is anchored strictly to the computed values (no invented content).
  suggestions <- character(0)
  if (mean_bad) {
    suggestions <- c(suggestions, sprintf(tr(lang, "glu_sugg_mean"),
                                          fmt_glu_num(g_mean[[overall]], 1, " mmol/L")))
  }
  if (var_bad) {
    suggestions <- c(suggestions, sprintf(tr(lang, "glu_sugg_var"),
                                          fmt_glu_num(cv_worst, 1, "%")))
  }
  if (is.finite(tir_overall) && tir_overall < GLUCOSE_TARGETS$tir_lower) {
    suggestions <- c(suggestions, sprintf(
      tr(lang, if (tir_overall < 50) "glu_sugg_tir_low" else "glu_sugg_tir_mid"),
      fmt_glu_num(tir_overall, 1, "%")))
  }
  if (burden_bad) {
    suggestions <- c(suggestions, sprintf(tr(lang, "glu_sugg_burden"),
                                          fmt_glu_num(tar_overall, 1, "%"),
                                          fmt_glu_num(tbr_overall, 1, "%")))
  }
  if (length(suggestions) == 0) suggestions <- c(suggestions, tr(lang, "glu_sugg_ok"))
  suggestions <- c(suggestions, tr(lang, "glu_sugg_emergency"))

  dimension_table <- data.frame(
    DIM = c(tr(lang, "glu_dim_mean"), tr(lang, "glu_dim_var"),
            tr(lang, "glu_dim_tir"), tr(lang, "glu_dim_burden")),
    CUR = c(
      fmt_glu_num(g_mean[[overall]], 1, " mmol/L"),
      paste0("CV: ", fmt_glu_num(cv_worst, 1, "%"), " | SD: ", fmt_glu_num(g_sd[[overall]], 2, " mmol/L")),
      fmt_glu_num(tir_overall, 1, "%"),
      paste0("TAR: ", fmt_glu_num(tar_overall, 1, "%"), " | TBR: ", fmt_glu_num(tbr_overall, 1, "%"))
    ),
    CRI = c(tr(lang, "glu_crit_mean"), tr(lang, "glu_crit_var"),
            tr(lang, "glu_crit_tir"), tr(lang, "glu_crit_burden")),
    JUD = c(
      if (mean_bad) tr(lang, "glu_dim_bad_mean") else tr(lang, "glu_dim_ok_mean"),
      if (var_bad) tr(lang, "dim_bad_var") else tr(lang, "dim_ok_var"),
      tir_status,
      if (burden_bad) tr(lang, "dim_bad_burden") else if (is.finite(tar_overall) || is.finite(tbr_overall)) tr(lang, "dim_ok_burden") else tr(lang, "status_insufficient")
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
      Glucose_Followup = tr(lang, paste0("followup_", followup_key)),
      Glucose_Mean_Assessment = dimension_table[[tr(lang, "col_judgment")]][1],
      Glucose_CV_Assessment = dimension_table[[tr(lang, "col_judgment")]][2],
      Glucose_TIR_Assessment = dimension_table[[tr(lang, "col_judgment")]][3],
      Glucose_Burden_Assessment = dimension_table[[tr(lang, "col_judgment")]][4],
      Glucose_Advice = paste(suggestions, collapse = "; "),
      stringsAsFactors = FALSE
    )
  )
}

build_all_glucose_assessments <- function(metric_results, lang = "en") {
  ids <- collect_result_patients(metric_results)
  has_glu <- !is.null(metric_results$`24h`$GLU) && nrow(metric_results$`24h`$GLU) > 0
  if (length(ids) == 0 || !has_glu) return(data.frame())
  bind_rows(lapply(ids, function(id) build_glucose_assessment(metric_results, id, lang = lang)$export_row))
}
