# --- 4. Server Logic (bilingual shell, target helpers, pipeline state) ---
server <- function(input, output, session) {

  # ---------------- Bilingual state ----------------
  lang <- reactiveVal("en")
  observeEvent(input$lang_radio, { lang(input$lang_radio) }, ignoreNULL = TRUE)
  observe({ APP_LANG <<- lang() }) # chart/table helpers read this

  # Snapshot of user settings so a language switch re-renders the page without
  # losing inputs. build_ui() reads this snapshot (isolated), so the page only
  # re-renders when the language changes.
  settings <- reactiveValues()
  SNAPSHOT_INPUT_IDS <- c(
    "domain", "use_builtin_data", "use_device_sample", "use_glucose_sample", "upload_mode",
    "day1_start_h", "day1_start_m", "day1_night_start_h", "day1_night_start_m",
    "day2_start_h", "day2_start_m", "day2_night_start_h", "day2_night_start_m",
    "interp_mode", "vim_mode", "vim_ref_mean",
    "window_mode", "window_hours", "window_start_spec", "window_end_spec",
    unlist(lapply(c("sbp", "dbp", "hr", "pp", "map"), function(m) {
      unlist(lapply(c("day", "night", "24h"), function(p) {
        paste0(m, "_", p, "_", c("lower", "upper"))
      }), use.names = FALSE)
    }), use.names = FALSE),
    "map_id", "map_time", "map_sbp", "map_dbp", "map_hr", "map_pp", "map_map",
    "export_items", "main_tabset", "viz_metric_select"
  )
  observe({
    for (id in SNAPSHOT_INPUT_IDS) {
      val <- input[[id]]
      if (!is.null(val)) settings[[id]] <- val
    }
  })

  output$page <- renderUI({
    build_ui(lang(), isolate(reactiveValuesToList(settings)))
  })

  output$header_title <- renderUI({
    div(
      icon("heart-pulse"),
      tr(lang(), "app_title"),
      span(tr(lang(), "app_title_sub"), style = "font-size: 0.7em; color: #555; margin-left: 8px;")
    )
  })

  output$footer_text <- renderUI({
    tagList(
      div(tr(lang(), "footer_copyright")),
      div(tr(lang(), "footer_contact"), " ",
          a("morethanlee@163.com", href = "mailto:morethanlee@163.com"))
    )
  })

  observe({
    updateActionButton(session, "tour_btn", label = tr(lang(), "tour_start"))
  })

  # ---------------- Guided tour (rintrojs) ----------------
  observeEvent(input$tour_btn, {
    if (!has_introjs) {
      showNotification(tr(lang(), "tour_unavailable"), type = "warning", duration = 5)
      updateTabsetPanel(session, "main_tabset", selected = "guide_tab")
      return()
    }
    tour_elements <- c("#lang_radio", "#domain", "#use_builtin_data", "#use_device_sample")
    tour_intros <- c(tr(lang(), "tour_step_lang"),
                     tr(lang(), "tour_step_domain"),
                     tr(lang(), "tour_step_builtin"),
                     tr(lang(), "tour_step_device_sample"))
    if (!DEMO_MODE) {
      tour_elements <- c(tour_elements, "#upload_mode")
      tour_intros <- c(tour_intros, tr(lang(), "tour_step_mode"))
    }
    tour_elements <- c(tour_elements,
                       "#day1_start_h", "#interp_mode", "#window_mode", "#vim_mode",
                       "#sbp_day_lower", "#process_data_btn", "#calculate_metrics_btn",
                       "#main_tabset", "#export_items", "#download_sel_csv")
    tour_intros <- c(tour_intros,
                     tr(lang(), "tour_step_daynight"), tr(lang(), "tour_step_interp"),
                     tr(lang(), "tour_step_window"), tr(lang(), "tour_step_vim"),
                     tr(lang(), "tour_step_targets"),
                     tr(lang(), "tour_step_process"), tr(lang(), "tour_step_calc"),
                     tr(lang(), "tour_step_tabs"), tr(lang(), "tour_step_export"),
                     tr(lang(), "tour_step_download"))
    steps <- data.frame(element = tour_elements, intro = tour_intros,
                        stringsAsFactors = FALSE)
    rintrojs::introjs(session, options = list(
      steps = steps,
      nextLabel = tr(lang(), "tour_next"),
      prevLabel = tr(lang(), "tour_prev"),
      skipLabel = tr(lang(), "tour_skip"),
      doneLabel = tr(lang(), "tour_done")
    ))
  }, ignoreInit = TRUE)

  # ---------------- Reactive values ----------------
  values <- reactiveValues(
    raw_data_input = NULL,
    prepared_long_data = NULL,
    wide_dfs = list(),
    individual_series = list(),
    interpolated_dfs = list(),
    sorted_times = NULL,
    sorted_minutes = NULL,
    split_data_wide = list(),
    metric_results = list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list()),
    processing_error = NULL,
    calculation_error = NULL,
    data_processed_successfully = FALSE,
    metrics_calculated_successfully = FALSE,
    data_source_key = "src_none",
    targets_used_day = list(),
    targets_used_night = list(),
    targets_used_24h = list(),
    available_patients_viz = character(0),
    selected_patient_viz = NULL,
    selected_metric_viz = "SBP",
    targets_locked = FALSE,
    locked_targets = NULL,
    # new import-related state
    use_builtin_active = FALSE,
    device_sample_active = FALSE,
    glucose_sample_active = FALSE,
    # analysis window state
    edge_rule = "linear",
    pending_window_args = NULL,
    uploaded_csv_raw = NULL,
    uploaded_csv_files = character(0),
    raw_files_info = list(),
    raw_maskids = list(),
    converted_raw_long = NULL,
    converted_raw_summary = NULL
  )

  # --- Target-range state helpers ---
  # Keep every target input in one place so the lock button controls the full
  # target set consistently (including PP/MAP).
  TARGET_INPUT_IDS <- unlist(lapply(c("sbp", "dbp", "hr", "pp", "map", "glu"), function(metric_name) {
    unlist(lapply(c("day", "night", "24h"), function(period_name) {
      paste0(metric_name, "_", period_name, "_", c("lower", "upper"))
    }), use.names = FALSE)
  }), use.names = FALSE)

  read_current_targets <- function() {
    list(
      sbp_day_lower = input$sbp_day_lower, sbp_day_upper = input$sbp_day_upper,
      dbp_day_lower = input$dbp_day_lower, dbp_day_upper = input$dbp_day_upper,
      hr_day_lower = input$hr_day_lower, hr_day_upper = input$hr_day_upper,
      pp_day_lower = input$pp_day_lower, pp_day_upper = input$pp_day_upper,
      map_day_lower = input$map_day_lower, map_day_upper = input$map_day_upper,
      sbp_night_lower = input$sbp_night_lower, sbp_night_upper = input$sbp_night_upper,
      dbp_night_lower = input$dbp_night_lower, dbp_night_upper = input$dbp_night_upper,
      hr_night_lower = input$hr_night_lower, hr_night_upper = input$hr_night_upper,
      pp_night_lower = input$pp_night_lower, pp_night_upper = input$pp_night_upper,
      map_night_lower = input$map_night_lower, map_night_upper = input$map_night_upper,
      sbp_24h_lower = input$sbp_24h_lower, sbp_24h_upper = input$sbp_24h_upper,
      dbp_24h_lower = input$dbp_24h_lower, dbp_24h_upper = input$dbp_24h_upper,
      hr_24h_lower = input$hr_24h_lower, hr_24h_upper = input$hr_24h_upper,
      pp_24h_lower = input$pp_24h_lower, pp_24h_upper = input$pp_24h_upper,
      map_24h_lower = input$map_24h_lower, map_24h_upper = input$map_24h_upper,
      glu_day_lower = input$glu_day_lower, glu_day_upper = input$glu_day_upper,
      glu_night_lower = input$glu_night_lower, glu_night_upper = input$glu_night_upper,
      glu_24h_lower = input$glu_24h_lower, glu_24h_upper = input$glu_24h_upper
    )
  }

  target_is_missing <- function(x) {
    length(x) == 0L || (length(x) == 1L && is.na(x))
  }

  target_is_finite_number <- function(x) {
    length(x) == 1L && is.numeric(x) && !is.na(x) && is.finite(x)
  }

  period_label <- function(period) tr(APP_LANG, paste0("tab_", period))

  validate_optional_target_pairs <- function(targets) {
    for (metric_name in c("pp", "map")) {
      for (period_name in c("day", "night", "24h")) {
        lower <- targets[[paste0(metric_name, "_", period_name, "_lower")]]
        upper <- targets[[paste0(metric_name, "_", period_name, "_upper")]]
        lower_missing <- target_is_missing(lower)
        upper_missing <- target_is_missing(upper)
        label <- paste(period_label(period_name), toupper(metric_name))

        if (xor(lower_missing, upper_missing)) {
          return(list(valid = FALSE,
                      message = paste0(label, tr(APP_LANG, "pair_err"))))
        }
        if (!lower_missing &&
            (!target_is_finite_number(lower) || !target_is_finite_number(upper))) {
          return(list(valid = FALSE,
                      message = paste0(label, tr(APP_LANG, "pair_err_num"))))
        }
      }
    }
    list(valid = TRUE, message = NULL)
  }

  validate_target_snapshot <- function(targets) {
    required_names <- grep("^(sbp|dbp|hr|glu)_.*_(lower|upper)$", names(targets), value = TRUE)
    invalid_required <- vapply(targets[required_names], function(x) {
      length(x) != 1L || !is.numeric(x) || is.na(x) || !is.finite(x)
    }, logical(1))
    if (any(invalid_required)) {
      return(list(valid = FALSE, message = tr(APP_LANG, "lock_err_required")))
    }

    optional_names <- grep("^(pp|map)_.*_(lower|upper)$", names(targets), value = TRUE)
    invalid_optional <- vapply(targets[optional_names], function(x) {
      length(x) > 1L || (length(x) == 1L && !is.na(x) && (!is.numeric(x) || !is.finite(x)))
    }, logical(1))
    if (any(invalid_optional)) {
      return(list(valid = FALSE, message = tr(APP_LANG, "lock_err_optional")))
    }

    optional_pair_validation <- validate_optional_target_pairs(targets)
    if (!isTRUE(optional_pair_validation$valid)) return(optional_pair_validation)

    for (metric_name in c("sbp", "dbp", "hr", "pp", "map", "glu")) {
      for (period_name in c("day", "night", "24h")) {
        lower <- targets[[paste0(metric_name, "_", period_name, "_lower")]]
        upper <- targets[[paste0(metric_name, "_", period_name, "_upper")]]
        if (length(lower) == 1L && length(upper) == 1L &&
            is.numeric(lower) && !is.na(lower) && is.numeric(upper) && !is.na(upper) &&
            upper <= lower) {
          label <- paste(period_label(period_name), toupper(metric_name))
          return(list(valid = FALSE,
                      message = paste0(label, tr(APP_LANG, "lock_err_order"))))
        }
      }
    }

    list(valid = TRUE, message = NULL)
  }

  set_target_controls_locked <- function(locked) {
    for (target_id in TARGET_INPUT_IDS) {
      if (isTRUE(locked)) shinyjs::disable(target_id) else shinyjs::enable(target_id)
    }

    if (isTRUE(locked)) {
      shinyjs::disable("apply_targets_btn")
      shinyjs::disable("preset_targets")
      shinyjs::disable("preset_glu_normal")
      shinyjs::disable("preset_glu_diabetes")
      updateActionButton(session, "save_custom_targets_btn",
                         label = tr(APP_LANG, "unlock_targets_btn"), icon = icon("unlock"))
    } else {
      shinyjs::enable("apply_targets_btn")
      shinyjs::enable("preset_targets")
      shinyjs::enable("preset_glu_normal")
      shinyjs::enable("preset_glu_diabetes")
      updateActionButton(session, "save_custom_targets_btn",
                         label = tr(APP_LANG, "save_targets_btn"), icon = icon("lock"))
    }
  }

  # --- Placeholder Variability Reference Values ---
  VARIABILITY_REFERENCE_VALUES <- list(
    "SBP" = list(sd = 15, arv = 12),
    "DBP" = list(sd = 12, arv = 10),
    "HR" = list(sd = 10, arv = 8),
    "PP" = list(sd = 8, arv = 6), # Example values, adjust as needed
    "MAP" = list(sd = 10, arv = 8), # Example values, adjust as needed
    "GLU" = list(sd = 2.0, arv = 0.6) # Example values (mmol/L), adjust as needed
  )
