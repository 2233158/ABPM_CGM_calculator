# --- 2.7c Patient-specific calculation pipeline (batch-invariant interpolation,
#      with selectable interpolation mode and analysis window) ---
# Existing metric formulae are intentionally retained. This layer only
# separates the data source: traditional statistics use observed readings,
# whereas time/area metrics use a patient-specific interpolated time axis.
#
# interp_mode:
#   "valid" - interpolate only between the first and the last valid reading;
#             missing edges are NOT filled. (v1.2 mode 2 behaviour)
#   "full"  - full axis with nearest-observation edge clamping. (v1.2 mode 1)
#
# window_mode (ALL downstream metrics - raw statistics AND area/time metrics -
# are computed strictly inside the analysis window):
#   "calendar"   - the whole calendar span of the domain:
#                  BP  = [0, 3D)  (fits a 24h ABPM recording)
#                  GLU = [0, 15D] (day offsets +0D..+15D, a 15-day CGM)
#   "from_first" - window = [first valid reading, first + window_hours]
#   "from_start" - window = [window_start_spec, start + window_hours]
#   "custom"     - window = [window_start_spec, window_end_spec]
# Day/night segmentation applies the configured clock times as a repeating
# daily pattern anchored at recording day 0 (day 0 uses the Day-1 clocks,
# every later day uses the Day-2 clocks) - never the old fixed Day1/Day2
# 0-3D layout, so a window starting on any day is segmented correctly.
#
# edge_rule (only for user-specified window endpoints in "valid" mode; applied
# when an endpoint has no exact observed reading):
#   "linear"  - linear interpolation between the neighbouring readings
#   "nearest" - nearest observation (clamping)
#   "none"    - leave the endpoint empty (no interpolation)
# Interpolated boundary values only affect area/time metrics (AUC/TTR/burden);
# raw statistics (mean/SD/CV/ARV/VIM/Load) use windowed observations only.
create_individual_patient_series <- function(long_data,
                                             day_start1_h, day_start1_m,
                                             night_start1_h, night_start1_m,
                                             day_start2_h, day_start2_m,
                                             night_start2_h, night_start2_m,
                                             interp_mode = "valid",
                                             window_mode = "calendar",
                                             window_hours = 24,
                                             window_start_spec = NULL,
                                             window_end_spec = NULL,
                                             edge_rule = "linear") {
  d1_day_clock <- day_start1_h * 60 + day_start1_m
  d1_night_clock <- night_start1_h * 60 + night_start1_m
  d2_day_clock <- day_start2_h * 60 + day_start2_m
  d2_night_clock <- night_start2_h * 60 + night_start2_m
  metrics <- intersect(c("SBP", "DBP", "HR", "PP", "MAP", "GLU"), names(long_data))
  output <- list()

  # Day/night clock boundaries (the repeating daily pattern) that fall inside
  # the analysis window. Day 0 uses the Day-1 clocks; later days use Day-2.
  window_boundaries <- function(win_start, win_end) {
    if (!is.finite(win_start) || !is.finite(win_end) || win_end <= win_start) {
      return(numeric(0))
    }
    k_from <- max(0, floor(win_start / (24 * 60)) - 1)
    k_to <- floor(win_end / (24 * 60)) + 1
    pts <- numeric(0)
    for (k in k_from:k_to) {
      base <- k * 24 * 60
      ds <- if (k == 0) d1_day_clock else d2_day_clock
      ns <- if (k == 0) d1_night_clock else d2_night_clock
      pts <- c(pts, base + ds, base + ns)
    }
    unique(pts[pts >= win_start & pts <= win_end])
  }

  fill_endpoint_value <- function(t_target, obs_t, obs_v) {
    # returns the endpoint value for one target minute under edge_rule
    if (!is.finite(t_target)) return(NA_real_)
    hit <- which(obs_t == t_target)
    if (length(hit) > 0) return(obs_v[hit[1]])
    if (identical(edge_rule, "none")) return(NA_real_)
    below <- max(obs_t[obs_t <= t_target])
    above <- min(obs_t[obs_t >= t_target])
    has_b <- is.finite(below)
    has_a <- is.finite(above)
    if (!has_b && !has_a) return(NA_real_)
    if (!has_b) return(obs_v[which(obs_t == above)[1]])
    if (!has_a) return(obs_v[which(obs_t == below)[1]])
    if (identical(edge_rule, "nearest")) {
      if (t_target - below <= above - t_target) {
        return(obs_v[which(obs_t == below)[1]])
      } else {
        return(obs_v[which(obs_t == above)[1]])
      }
    }
    # linear
    vb <- obs_v[which(obs_t == below)[1]]
    va <- obs_v[which(obs_t == above)[1]]
    vb + (va - vb) * (t_target - below) / (above - below)
  }

  for (metric in metrics) {
    # The domain's whole-calendar span: BP 0-3D, GLU 0-15D (day offsets
    # +0D..+15D are all inside the GLU window).
    domain_end <- if (identical(metric, "GLU")) 16 * 24 * 60 else 3 * 24 * 60
    metric_patients <- list()
    patient_ids <- sort(unique(as.character(long_data$MASKID)))
    for (patient_id in patient_ids) {
      # Keep every observed row for Mean/SD/CV/ARV/VIM/Max/Min/Delta and
      # count-based Load. Duplicate timestamps are real observations and must
      # not be collapsed for these traditional statistics.
      raw_all <- long_data %>%
        filter(MASKID == patient_id, is.finite(Total_Minutes), is.finite(.data[[metric]])) %>%
        transmute(MASKID = as.character(MASKID),
                  Time = as.character(Time),
                  Total_Minutes = as.numeric(Total_Minutes),
                  Value = as.numeric(.data[[metric]]),
                  .source_order = dplyr::row_number()) %>%
        arrange(Total_Minutes, .source_order) %>%
        select(-.source_order)

      if (nrow(raw_all) == 0) next

      # Interpolation requires a unique x-axis. Only this interpolation source
      # averages duplicate timestamps; the raw observations above stay intact.
      interpolation_source <- raw_all %>%
        group_by(Total_Minutes) %>%
        summarise(Value = mean(Value), .groups = "drop") %>%
        arrange(Total_Minutes)

      data_min <- min(interpolation_source$Total_Minutes)
      data_max <- max(interpolation_source$Total_Minutes)

      # --- analysis window (per patient) ---
      if (identical(window_mode, "from_first")) {
        window_start <- data_min
        window_end <- min(data_min + as.numeric(window_hours) * 60, data_max)
      } else if (identical(window_mode, "from_start")) {
        window_start <- as.numeric(window_start_spec)
        window_end <- min(window_start + as.numeric(window_hours) * 60, data_max)
      } else if (identical(window_mode, "custom")) {
        window_start <- as.numeric(window_start_spec)
        window_end <- as.numeric(window_end_spec)
      } else {
        # calendar: the whole domain span (BP 0-3D / GLU 0-15D)
        window_start <- 0
        window_end <- domain_end
      }

      # --- raw statistics use windowed observations only ---
      raw <- raw_all %>%
        filter(Total_Minutes >= window_start & Total_Minutes <= window_end)
      if (nrow(raw) == 0) next
      raw <- raw %>% select(MASKID, Time, Total_Minutes, Value)

      # --- interpolated axis: window endpoints + in-window observations +
      #     the day/night clock boundaries inside the window, so area/time
      #     metrics attribute day/night exactly at the segment boundaries ---
      internal_points <- interpolation_source$Total_Minutes[
        interpolation_source$Total_Minutes >= window_start &
          interpolation_source$Total_Minutes <= window_end]
      patient_axis <- sort(unique(c(window_start, window_end, internal_points,
                                    window_boundaries(window_start, window_end))))

      axis_rule <- if (identical(interp_mode, "full")) 2 else 1
      if (nrow(interpolation_source) >= 2) {
        interpolated_values <- approx(
          x = interpolation_source$Total_Minutes,
          y = interpolation_source$Value,
          xout = patient_axis,
          method = "linear",
          rule = axis_rule,
          ties = "ordered"
        )$y
      } else {
        interpolated_values <- rep(NA_real_, length(patient_axis))
        interpolated_values[match(interpolation_source$Total_Minutes, patient_axis)] <-
          interpolation_source$Value
        if (axis_rule == 2) {
          interpolated_values[is.na(interpolated_values)] <- interpolation_source$Value[1]
        }
      }

      # User-specified window endpoints (valid mode) follow the chosen
      # edge_rule when they have no exact observed reading. Calendar endpoints
      # are artificial span markers and are left to the interpolation rule
      # ("full" mode clamps them via rule=2; "valid" drops them via rule=1).
      if (!identical(window_mode, "calendar") && identical(interp_mode, "valid")) {
        obs_t <- interpolation_source$Total_Minutes
        obs_v <- interpolation_source$Value
        i_start <- match(window_start, patient_axis)
        i_end <- match(window_end, patient_axis)
        if (!is.na(i_start)) {
          interpolated_values[i_start] <- fill_endpoint_value(window_start, obs_t, obs_v)
        }
        if (!is.na(i_end)) {
          interpolated_values[i_end] <- fill_endpoint_value(window_end, obs_t, obs_v)
        }
      }

      interpolated <- data.frame(
        MASKID = patient_id,
        Time = vapply(patient_axis, minutes_to_time_string, character(1)),
        Total_Minutes = patient_axis,
        Value = interpolated_values,
        Is_Observed = patient_axis %in% interpolation_source$Total_Minutes,
        stringsAsFactors = FALSE
      ) %>% filter(is.finite(Value))

      metric_patients[[patient_id]] <- list(
        raw = raw,
        interpolated = interpolated,
        window_start = window_start,
        window_end = window_end
      )
    }
    if (length(metric_patients) > 0) output[[metric]] <- metric_patients
  }
  output
}
