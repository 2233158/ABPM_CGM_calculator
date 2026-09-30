  # --- Data loading: built-in sample / prepared CSV (multi-file, with column
  #     mapping) / raw Mobil-O-Graph 24h PWA exports ---
  reset_pipeline_state <- function() {
    values$prepared_long_data <- NULL; values$wide_dfs <- list()
    values$individual_series <- list(); values$interpolated_dfs <- list()
    values$sorted_times <- NULL; values$sorted_minutes <- NULL
    values$split_data_wide <- list()
    values$processing_error <- NULL; values$calculation_error <- NULL
    values$metric_results <- list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list())
    values$data_processed_successfully <- FALSE
    values$metrics_calculated_successfully <- FALSE
    values$targets_used_day <- list(); values$targets_used_night <- list(); values$targets_used_24h <- list()
    values$available_patients_viz <- character(0)
    values$selected_patient_viz <- NULL
    values$targets_locked <- FALSE
    values$locked_targets <- NULL
    shinyjs::disable("calculate_metrics_btn")
    shinyjs::disable("save_custom_targets_btn")
    set_target_controls_locked(FALSE)
  }

  read_csv_smart <- function(path, name) {
    tryCatch(
      read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
               na.strings = c("", "NA", "NULL", " "), fileEncoding = "UTF-8-BOM"),
      error = function(e1) {
        tryCatch(
          read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                   na.strings = c("", "NA", "NULL", " ")),
          error = function(e2) {
            stop(tr(lang(), "err_csv_read"), ": ", name, " (", e2$message, ")")
          }
        )
      }
    )
  }

  # Built-in demo data (prepared-CSV path)
  observeEvent(input$use_builtin_data, {
    if (!isTRUE(input$use_builtin_data)) return()
    if (isTRUE(values$use_builtin_active) && !is.null(values$raw_data_input)) return()
    reset_pipeline_state()
    tryCatch({
      df <- read.csv(text = csv_data_string, check.names = FALSE,
                     stringsAsFactors = FALSE, na.strings = c("", "NA", "NULL", " "))
      if (!is.data.frame(df) || nrow(df) == 0) stop("built-in data is empty")
      values$raw_data_input <- df
      values$uploaded_csv_raw <- NULL
      values$raw_files_info <- list()
      values$use_builtin_active <- TRUE
      values$device_sample_active <- FALSE
      updateCheckboxInput(session, "use_device_sample", value = FALSE)
      values$glucose_sample_active <- FALSE
      updateCheckboxInput(session, "use_glucose_sample", value = FALSE)
      values$data_source_key <- "src_builtin"
      showNotification(tr(lang(), "builtin_loaded"), type = "message", duration = 4)
    }, error = function(e) {
      showNotification(paste(tr(lang(), "err_csv_read"), ":", e$message),
                       type = "error", duration = NULL)
      values$raw_data_input <- NULL
      values$data_source_key <- "src_none"
      values$processing_error <- e$message
    })
  }, ignoreInit = FALSE)

  # Built-in device samples: the "raw device export" path demo, seeded with
  # two anonymized real exports so the Convert workflow (review ID -> Convert
  # -> preview -> Load) can be practised without real files.
  observeEvent(input$use_device_sample, {
    if (!isTRUE(input$use_device_sample)) {
      if (isTRUE(values$device_sample_active)) {
        values$device_sample_active <- FALSE
        values$raw_files_info <- list()
        values$raw_maskids <- list()
        values$converted_raw_long <- NULL
        values$converted_raw_summary <- NULL
      }
      return()
    }
    if (isTRUE(values$device_sample_active) &&
        length(values$raw_files_info) == length(DEVICE_SAMPLE_CSVS)) return()
    reset_pipeline_state()
    values$raw_data_input <- NULL
    values$uploaded_csv_raw <- NULL
    values$uploaded_csv_files <- character(0)
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$raw_files_info <- lapply(names(DEVICE_SAMPLE_CSVS), function(id) {
      list(name = paste0(id, "_24hPWA (built-in sample)"),
           cached_path = NULL, ok = TRUE, demo = TRUE,
           demo_csv_text = DEVICE_SAMPLE_CSVS[[id]],
           conv = NULL, message = NULL)
    })
    values$raw_maskids <- as.list(names(DEVICE_SAMPLE_CSVS))
    values$converted_raw_long <- NULL
    values$converted_raw_summary <- NULL
    values$device_sample_active <- TRUE
    values$data_source_key <- "src_none"
    showNotification(tr(lang(), "device_sample_loaded"), type = "message", duration = 4)
  }, ignoreInit = FALSE)

  # Prepared CSV file(s): files with different column structures are merged
  # by column name (union); missing values stay empty.
  observeEvent(input$csv_files, {
    req(input$csv_files)
    dfs <- lapply(seq_len(nrow(input$csv_files)), function(i) {
      read_csv_smart(input$csv_files$datapath[i], input$csv_files$name[i])
    })
    if (length(dfs) > 1) {
      common <- Reduce(intersect, lapply(dfs, colnames))
      if (length(common) == 0) {
        showNotification(tr(lang(), "err_csv_cols_diff"), type = "error", duration = 10)
        values$uploaded_csv_raw <- NULL
        values$uploaded_csv_files <- character(0)
        return()
      }
    }
    reset_pipeline_state()
    values$raw_data_input <- NULL
    values$uploaded_csv_raw <- bind_rows(dfs)
    values$uploaded_csv_files <- input$csv_files$name
    values$raw_files_info <- list()
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$device_sample_active <- FALSE
    updateCheckboxInput(session, "use_device_sample", value = FALSE)
    values$glucose_sample_active <- FALSE
    updateCheckboxInput(session, "use_glucose_sample", value = FALSE)
    same_cols <- length(dfs) <= 1 ||
      all(vapply(dfs, function(d) identical(colnames(d), colnames(dfs[[1]])), logical(1)))
    if (!same_cols) {
      showNotification(tr(lang(), "csv_union_note"), type = "warning", duration = 8)
    }
    showNotification(tr(lang(), "csv_files_loaded"), type = "message", duration = 4)
  })

  # Column-mapping panel (rendered after CSV upload)
  output$mapping_panel <- renderUI({
    req(values$uploaded_csv_raw)
    src_cols <- colnames(values$uploaded_csv_raw)
    detected <- alias_lookup(src_cols)
    sel_input <- function(id, label, cur) {
      choices <- setNames(src_cols, src_cols)
      choices <- c(setNames("", tr(lang(), "map_not_used")), choices)
      # `cur` may be NULL/NA/length != 1 for an unmapped or undetected target;
      # only a single non-NA name that actually exists can be preselected.
      selected <- if (length(cur) == 1L && !is.na(cur) && cur %in% src_cols) cur else ""
      selectInput(id, label, choices = choices, selected = selected, width = "100%")
    }
    wellPanel(
      h5(icon("map-signs"), tr(lang(), "mapping_title")),
      p(tr(lang(), "mapping_hint"), style = "font-size:0.85em;color:#555;"),
      sel_input("map_id", tr(lang(), "map_id"), detected$MASKID),
      sel_input("map_time", tr(lang(), "map_time"), detected$Time),
      sel_input("map_sbp", tr(lang(), "map_sbp"), detected$SBP),
      sel_input("map_dbp", tr(lang(), "map_dbp"), detected$DBP),
      sel_input("map_hr", tr(lang(), "map_hr"), detected$HR),
      sel_input("map_pp", tr(lang(), "map_pp"), detected$PP),
      sel_input("map_map", tr(lang(), "map_map"), detected$MAP),
      sel_input("map_glu", tr(lang(), "map_glu"), detected$GLU),
      actionButton("apply_mapping_btn", tr(lang(), "map_apply"), icon = icon("check"),
                   class = "btn-sm btn-primary btn-block")
    )
  })

  observeEvent(input$apply_mapping_btn, {
    req(values$uploaded_csv_raw)
    src <- values$uploaded_csv_raw
    pick <- function(v) if (is.null(v) || length(v) == 0L || v == "") NA_character_ else v
    mapping <- list(MASKID = pick(input$map_id), Time = pick(input$map_time),
                    SBP = pick(input$map_sbp), DBP = pick(input$map_dbp),
                    HR = pick(input$map_hr), PP = pick(input$map_pp),
                    MAP = pick(input$map_map), GLU = pick(input$map_glu))
    if (is.na(mapping$MASKID)) {
      showNotification(tr(lang(), "err_map_no_id"), type = "error", duration = 7); return()
    }
    if (is.na(mapping$Time)) {
      showNotification(tr(lang(), "err_map_no_time"), type = "error", duration = 7); return()
    }
    mapped_measures <- mapping[c("SBP", "DBP", "HR", "PP", "MAP", "GLU")]
    if (all(is.na(unlist(mapped_measures)))) {
      # Only ID and Time are strictly required; proceed with a warning.
      showNotification(tr(lang(), "warn_map_no_measure"), type = "warning", duration = 7)
    }
    out <- data.frame(MASKID = src[[mapping$MASKID]], Time = src[[mapping$Time]],
                      stringsAsFactors = FALSE)
    for (m in names(mapped_measures)) {
      col <- mapped_measures[[m]]
      # Only include mapped measurement columns; unmapped metrics are simply
      # absent instead of phantom all-NA columns (all-NA columns would make
      # every row look invalid downstream).
      if (!is.na(col)) out[[m]] <- src[[col]]
    }
    reset_pipeline_state()
    values$raw_data_input <- out
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$data_source_key <- "src_csv"
    showNotification(tr(lang(), "map_ok"), type = "message", duration = 4)
  })

  # Prepared glucose CSV file(s) (processed glucose path)
  observeEvent(input$glu_csv_files, {
    req(input$glu_csv_files)
    dfs <- lapply(seq_len(nrow(input$glu_csv_files)), function(i) {
      read_csv_smart(input$glu_csv_files$datapath[i], input$glu_csv_files$name[i])
    })
    if (length(dfs) > 1) {
      common <- Reduce(intersect, lapply(dfs, colnames))
      if (length(common) == 0) {
        showNotification(tr(lang(), "err_csv_cols_diff"), type = "error", duration = 10)
        values$uploaded_csv_raw <- NULL
        values$uploaded_csv_files <- character(0)
        return()
      }
    }
    reset_pipeline_state()
    values$raw_data_input <- NULL
    values$uploaded_csv_raw <- bind_rows(dfs)
    values$uploaded_csv_files <- input$glu_csv_files$name
    values$raw_files_info <- list()
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$device_sample_active <- FALSE
    updateCheckboxInput(session, "use_device_sample", value = FALSE)
    values$glucose_sample_active <- FALSE
    updateCheckboxInput(session, "use_glucose_sample", value = FALSE)
    values$glucose_sample_active <- FALSE
    updateCheckboxInput(session, "use_glucose_sample", value = FALSE)
    same_cols <- length(dfs) <= 1 ||
      all(vapply(dfs, function(d) identical(colnames(d), colnames(dfs[[1]])), logical(1)))
    if (!same_cols) {
      showNotification(tr(lang(), "csv_union_note"), type = "warning", duration = 8)
    }
    showNotification(tr(lang(), "csv_files_loaded"), type = "message", duration = 4)
  })

  # Raw glucose export file(s) (raw CGM path)
  observeEvent(input$glu_raw_files, {
    req(input$glu_raw_files)
    n <- nrow(input$glu_raw_files)
    infos <- vector("list", n)
    for (i in seq_len(n)) {
      name <- input$glu_raw_files$name[i]
      cached <- file.path(tempdir(), paste0("abpm_glu_", i, "_", basename(name)))
      tryCatch(file.copy(input$glu_raw_files$datapath[i], cached, overwrite = TRUE),
               error = function(e) NULL)
      infos[[i]] <- tryCatch({
        conv <- glu_raw_to_long(path = input$glu_raw_files$datapath[i],
                                file_label = name)
        list(name = name, cached_path = cached, ok = TRUE, demo = FALSE,
             parser = "glu", conv = conv, message = NULL)
      }, error = function(e) {
        list(name = name, cached_path = cached, ok = FALSE, demo = FALSE,
             parser = "glu", conv = NULL, message = conditionMessage(e))
      })
    }
    reset_pipeline_state()
    values$raw_data_input <- NULL
    values$uploaded_csv_raw <- NULL
    values$uploaded_csv_files <- character(0)
    values$raw_files_info <- infos
    values$raw_maskids <- lapply(infos, function(z) if (isTRUE(z$ok)) z$conv$auto_maskid else "")
    values$converted_raw_long <- NULL
    values$converted_raw_summary <- NULL
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$device_sample_active <- FALSE
    updateCheckboxInput(session, "use_device_sample", value = FALSE)
    values$glucose_sample_active <- FALSE
    updateCheckboxInput(session, "use_glucose_sample", value = FALSE)
    values$glucose_sample_active <- FALSE
    updateCheckboxInput(session, "use_glucose_sample", value = FALSE)
    failed <- infos[!vapply(infos, function(z) isTRUE(z$ok), logical(1))]
    if (length(failed) > 0) {
      showNotification(paste0(length(failed), " file(s) could not be parsed: ",
                              failed[[1]]$message %||% ""),
                       type = "error", duration = 10)
    }
    showNotification(tr(lang(), "raw_parsed"), type = "message", duration = 4)
  })

  # Built-in glucose sample: the raw-glucose path demo (14-day CGM).
  observeEvent(input$use_glucose_sample, {
    if (!isTRUE(input$use_glucose_sample)) {
      if (isTRUE(values$glucose_sample_active)) {
        values$glucose_sample_active <- FALSE
        values$raw_files_info <- list()
        values$raw_maskids <- list()
        values$converted_raw_long <- NULL
        values$converted_raw_summary <- NULL
      }
      return()
    }
    if (isTRUE(values$glucose_sample_active) && length(values$raw_files_info) == 1) return()
    reset_pipeline_state()
    values$raw_data_input <- NULL
    values$uploaded_csv_raw <- NULL
    values$uploaded_csv_files <- character(0)
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$device_sample_active <- FALSE
    updateCheckboxInput(session, "use_device_sample", value = FALSE)
    values$raw_files_info <- list(list(
      name = "LT2503SGHM_14d_CGM (built-in glucose sample)",
      cached_path = NULL, ok = TRUE, demo = TRUE, parser = "glu",
      demo_csv_text = GLUCOSE_SAMPLE_RAW, conv = NULL, message = NULL))
    values$raw_maskids <- list("LT2503SGHM")
    values$converted_raw_long <- NULL
    values$converted_raw_summary <- NULL
    values$glucose_sample_active <- TRUE
    values$data_source_key <- "src_none"
    showNotification(tr(lang(), "glucose_sample_loaded"), type = "message", duration = 4)
  }, ignoreInit = FALSE)
  observeEvent(input$raw_files, {
    req(input$raw_files)
    n <- nrow(input$raw_files)
    infos <- vector("list", n)
    for (i in seq_len(n)) {
      name <- input$raw_files$name[i]
      cached <- file.path(tempdir(), paste0("abpm_raw_", i, "_", basename(name)))
      tryCatch(file.copy(input$raw_files$datapath[i], cached, overwrite = TRUE),
               error = function(e) NULL)
      infos[[i]] <- tryCatch({
        conv <- xls_to_abpm_long(input$raw_files$datapath[i], maskid_override = NULL,
                                 file_label = input$raw_files$name[i])
        list(name = name, cached_path = cached, ok = TRUE, conv = conv, message = NULL)
      }, error = function(e) {
        list(name = name, cached_path = cached, ok = FALSE, conv = NULL, message = conditionMessage(e))
      })
    }
    reset_pipeline_state()
    values$raw_data_input <- NULL
    values$uploaded_csv_raw <- NULL
    values$uploaded_csv_files <- character(0)
    values$raw_files_info <- infos
    values$raw_maskids <- lapply(infos, function(z) if (isTRUE(z$ok)) z$conv$auto_maskid else "")
    values$converted_raw_long <- NULL
    values$converted_raw_summary <- NULL
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$device_sample_active <- FALSE
    updateCheckboxInput(session, "use_device_sample", value = FALSE)
    values$glucose_sample_active <- FALSE
    updateCheckboxInput(session, "use_glucose_sample", value = FALSE)
    failed <- infos[!vapply(infos, function(z) isTRUE(z$ok), logical(1))]
    if (length(failed) > 0) {
      first_msg <- failed[[1]]$message %||% ""
      showNotification(
        paste0(length(failed), " file(s) could not be parsed: ", first_msg),
        type = "error", duration = 10)
    }
    showNotification(tr(lang(), "raw_parsed"), type = "message", duration = 4)
  })

  # NOTE: edited per-file MASKIDs are read at Convert-click time only. A
  # generic "persist on every input change" observer is deliberately NOT used
  # here: it races with the sample-seeding observers and could write a stale
  # previous sample's ID back over the freshly seeded one (wrong-ID risk).
  # Consequently, edits are reset if the page is re-rendered (language switch)
  # before Convert is clicked.

  output$raw_convert_panel <- renderUI({
    infos <- values$raw_files_info
    req(length(infos) > 0)
    maskid_inputs <- lapply(seq_along(infos), function(i) {
      textInput(paste0("raw_maskid_", i),
                label = paste0(basename(infos[[i]]$name), " — ", tr(lang(), "raw_maskid_label")),
                value = values$raw_maskids[[i]] %||% "")
    })
    wellPanel(
      h5(icon("file-import"), tr(lang(), "raw_panel_title")),
      p(tr(lang(), "raw_hint"), style = "font-size:0.85em;color:#555;"),
      do.call(tagList, maskid_inputs),
      fluidRow(
        column(6, actionButton("convert_raw_btn", tr(lang(), "raw_convert_btn"),
                               icon = icon("cogs"), class = "btn-sm btn-info btn-block")),
        column(6, actionButton("load_converted_btn", tr(lang(), "raw_load_btn"),
                               icon = icon("check"), class = "btn-sm btn-primary btn-block"))
      ),
      downloadButton("download_converted_csv", tr(lang(), "raw_download_btn"),
                     class = "btn-sm btn-success btn-block", style = "margin-top:8px;")
    )
  })

  observeEvent(input$convert_raw_btn, {
    infos <- values$raw_files_info
    req(length(infos) > 0)
    parts <- vector("list", length(infos))
    summary_rows <- list()
    for (i in seq_along(infos)) {
      info <- infos[[i]]
      if (!isTRUE(info$ok)) {
        summary_rows[[i]] <- data.frame(
          File = info$name, MASKID = NA_character_, Start = NA_character_,
          Total = 0, Valid = 0, Dropped_zero = 0, Dropped_bad_time = 0,
          Error = info$message %||% "", stringsAsFactors = FALSE)
        next
      }
      values$raw_maskids[[i]] <- input[[paste0("raw_maskid_", i)]] %||% ""
      conv <- if (isTRUE(info$demo) && identical(info$parser, "glu")) {
        # built-in glucose sample: parse the embedded raw-layout text
        tryCatch(glu_raw_to_long(text = info$demo_csv_text,
                                 maskid_override = values$raw_maskids[[i]],
                                 file_label = info$name),
                 error = function(e) e)
      } else if (isTRUE(info$demo)) {
        # built-in device sample: the CSV is already in canonical form;
        # apply the (possibly edited) MASKID and fake the conversion report
        demo_csv <- read.csv(text = info$demo_csv_text, stringsAsFactors = FALSE,
                             check.names = FALSE)
        new_id <- trimws(as.character(values$raw_maskids[[i]]))
        if (nzchar(new_id)) demo_csv$MASKID <- as.character(new_id)
        list(
          data = demo_csv,
          meta = list(),
          sheet = NA_character_,
          n_total = nrow(demo_csv),
          n_valid = nrow(demo_csv),
          n_dropped_zero = 0,
          n_dropped_bad_time = 0,
          first_valid = if (nrow(demo_csv) > 0) as.character(demo_csv$Time[1]) else NA_character_,
          last_valid = if (nrow(demo_csv) > 0) as.character(demo_csv$Time[nrow(demo_csv)]) else NA_character_,
          auto_maskid = if (nrow(demo_csv) > 0) as.character(demo_csv$MASKID[1]) else NA_character_
        )
      } else if (identical(info$parser, "glu")) {
        tryCatch(glu_raw_to_long(path = info$cached_path,
                                 maskid_override = values$raw_maskids[[i]],
                                 file_label = info$name),
                 error = function(e) e)
      } else {
        tryCatch(xls_to_abpm_long(info$cached_path,
                                  maskid_override = values$raw_maskids[[i]],
                                  file_label = info$name),
                 error = function(e) e)
      }
      if (inherits(conv, "error")) {
        summary_rows[[i]] <- data.frame(
          File = info$name, MASKID = NA_character_, Start = NA_character_,
          Total = 0, Valid = 0, Dropped_zero = 0, Dropped_bad_time = 0,
          Error = conditionMessage(conv), stringsAsFactors = FALSE)
        next
      }
      parts[[i]] <- conv$data
      summary_rows[[i]] <- data.frame(
        File = info$name,
        MASKID = if (nrow(conv$data) > 0) conv$data$MASKID[1] else conv$auto_maskid,
        Start = conv$first_valid,
        Total = conv$n_total,
        Valid = conv$n_valid,
        Dropped_zero = conv$n_dropped_zero,
        Dropped_bad_time = conv$n_dropped_bad_time,
        Error = "", stringsAsFactors = FALSE)
    }
    parts_ok <- parts[!vapply(parts, is.null, logical(1))]
    merged <- if (length(parts_ok) > 0) bind_rows(parts_ok) else NULL
    values$converted_raw_long <- if (!is.null(merged) && nrow(merged) > 0) merged else NULL
    values$converted_raw_summary <- bind_rows(summary_rows)
    if (is.null(values$converted_raw_long)) {
      err_msgs <- unique(c(
        vapply(infos, function(z) if (isTRUE(z$ok)) "" else z$message %||% "", character(1)),
        as.character(values$converted_raw_summary$Error)
      ))
      err_msgs <- unique(err_msgs[nzchar(err_msgs)])
      if (length(err_msgs) > 0) {
        showNotification(err_msgs[1], type = "error", duration = 10)
      } else {
        showNotification(tr(lang(), "err_no_valid_readings"), type = "error", duration = 7)
      }
    } else {
      showNotification(tr(lang(), "raw_converted_ok"), type = "message", duration = 5)
    }
  })

  observeEvent(input$load_converted_btn, {
    req(values$converted_raw_long)
    reset_pipeline_state()
    values$raw_data_input <- values$converted_raw_long
    values$use_builtin_active <- FALSE
    updateCheckboxInput(session, "use_builtin_data", value = FALSE)
    values$data_source_key <- "src_raw"
    showNotification(tr(lang(), "raw_loaded"), type = "message", duration = 4)
  })

  output$download_converted_csv <- downloadHandler(
    filename = function() paste0("ABPM_preprocessed_", Sys.Date(), ".csv"),
    content = function(file) {
      req(values$converted_raw_long)
      con <- base::file(file, open = "wb")
      on.exit(close(con), add = TRUE)
      writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
      write.table(values$converted_raw_long, con, sep = ",", row.names = FALSE,
                  col.names = TRUE, qmethod = "double", na = "")
    }
  )

  # --- Input tab outputs ---
  output$data_source_title <- renderText({
    paste(tr(lang(), "data_preview_title"), "(", tr(lang(), values$data_source_key), ")")
  })

  output$data_status_line <- renderUI({
    items <- list()
    if (length(values$uploaded_csv_files) > 0) {
      items[[length(items) + 1]] <- tags$li(tr(lang(), "status_csv_files"), ": ",
                                            paste(values$uploaded_csv_files, collapse = ", "))
    }
    if (length(values$raw_files_info) > 0) {
      names_raw <- vapply(values$raw_files_info, function(z) z$name, character(1))
      items[[length(items) + 1]] <- tags$li(tr(lang(), "status_raw_files"), ": ",
                                            paste(names_raw, collapse = ", "))
    }
    if (!is.null(values$raw_data_input)) {
      items[[length(items) + 1]] <- tags$li(tr(lang(), "status_working_rows"), ": ",
                                            nrow(values$raw_data_input))
    }
    if (length(items) == 0) return(NULL)
    tags$ul(style = "font-size:0.85em;color:#555;", do.call(tagList, items))
  })

  output$raw_data_table <- renderDT({
    req(values$raw_data_input)
    datatable(head(values$raw_data_input, 200),
              caption = tr(lang(), "caption_raw"),
              options = list(scrollX = TRUE, pageLength = 5, lengthMenu = c(5, 10, 20)),
              rownames = FALSE)
  })

  output$raw_convert_summary <- renderDT({
    req(values$converted_raw_summary)
    datatable(values$converted_raw_summary, caption = tr(lang(), "raw_summary_title"),
              options = list(scrollX = TRUE, pageLength = 5, dom = "t"),
              rownames = FALSE)
  })

  output$raw_convert_preview <- renderDT({
    req(values$converted_raw_long)
    datatable(head(values$converted_raw_long, 200), caption = tr(lang(), "raw_preview_title"),
              options = list(scrollX = TRUE, pageLength = 5, lengthMenu = c(5, 10, 20)),
              rownames = FALSE)
  })

  output$field_defs_table <- renderDT({
    datatable(FIELD_DEFS, caption = tr(lang(), "field_defs_title"),
              options = list(scrollX = TRUE, pageLength = 15, searchDelay = 500),
              rownames = FALSE, filter = "top")
  })

  output$guide_metric_defs_table <- renderDT({
    datatable(METRIC_DEFS, options = list(scrollX = TRUE, pageLength = 12, dom = "t"),
              rownames = FALSE)
  })
