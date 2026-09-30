# VIM = SD / mean^beta * k
#   "cohort" : beta = slope of ln(SD) ~ ln(mean) across the cohort,
#              k = cohort_mean^beta            (default; original behaviour)
#   "fixed"  : beta = 1, k = reference mean (default 100 mmHg)
add_vim_from_observed_results <- function(results_df, vim_mode = "cohort", vim_ref_mean = 100) {
  results_df$VIM <- NA_real_
  if (!all(c("mean", "SD") %in% names(results_df))) return(results_df)
  valid <- is.finite(results_df$mean) & results_df$mean > 0 &
    is.finite(results_df$SD) & results_df$SD > 0
  if (sum(valid) == 0) return(results_df)

  if (identical(vim_mode, "fixed")) {
    ref <- suppressWarnings(as.numeric(vim_ref_mean))
    if (length(ref) != 1L || is.na(ref) || !is.finite(ref) || ref <= 0) return(results_df)
    results_df$VIM[valid] <- results_df$SD[valid] / (results_df$mean[valid] ^ 1) * ref
    return(results_df)
  }

  # cohort mode
  if (sum(valid) < 2 || length(unique(results_df$mean[valid])) < 2) return(results_df)
  fit <- tryCatch(lm(log(SD) ~ log(mean), data = results_df[valid, , drop = FALSE]),
                  error = function(e) NULL)
  if (is.null(fit)) return(results_df)
  beta <- suppressWarnings(as.numeric(coef(fit)[2]))
  cohort_mean <- mean(results_df$mean[valid])
  if (!is.finite(beta) || !is.finite(cohort_mean) || cohort_mean <= 0) return(results_df)
  results_df$VIM[valid] <- results_df$SD[valid] /
    (results_df$mean[valid] ^ beta) * (cohort_mean ^ beta)
  results_df
}
