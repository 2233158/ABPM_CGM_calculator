  # --- Selected-item exports (tick boxes in the sidebar) ---
  export_period_results <- function() {
    out <- list()
    period_prefix <- c(day = "day", night = "night", `24h` = "24h_unified",
                       `24h_segmented` = "24h_segmented")
    for (pk in names(period_prefix)) {
      for (metric in names(values$metric_results[[pk]])) {
        df <- values$metric_results[[pk]][[metric]]
        if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
          out[[paste0(period_prefix[[pk]], "_", metric)]] <- df
        }
      }
    }
    out
  }

  export_split_tables <- function() {
    out <- list()
    for (pname in names(values$split_data_wide)) {
      if (is.null(values$split_data_wide[[pname]])) next
      for (metric in names(values$split_data_wide[[pname]])) {
        df <- values$split_data_wide[[pname]][[metric]]
        if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
          out[[paste0("split_", pname, "_", metric)]] <- df
        }
      }
    }
    out
  }

  export_interp_tables <- function() {
    out <- list()
    for (metric in names(values$interpolated_dfs)) {
      df <- values$interpolated_dfs[[metric]]
      if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
        out[[paste0("interp_", metric)]] <- df
      }
    }
    out
  }

  # Each selected item is a list(id, csv = named list, xlsx = named list).
  export_items_reactive <- function() {
    sel <- input$export_items
    if (is.null(sel) || length(sel) == 0) return(list())
    items <- list()
    if ("wide" %in% sel) {
      items[["wide"]] <- list(
        csv = list(full_wide_table = full_export_reactive()),
        xlsx = list(`Full Wide Table` = full_export_reactive()))
    }
    if ("period" %in% sel) {
      p <- export_period_results()
      if (length(p) > 0) items[["period"]] <- list(csv = p, xlsx = p)
    }
    if ("personal" %in% sel) {
      a <- build_all_personalized_assessments(values$metric_results, lang = lang())
      if (nrow(a) > 0) {
        items[["personal"]] <- list(csv = list(personalized_analysis = a),
                                    xlsx = list(`Personalized Analysis` = a))
      }
    }
    if ("prepared" %in% sel && !is.null(values$prepared_long_data)) {
      items[["prepared"]] <- list(csv = list(prepared_long_data = values$prepared_long_data),
                                  xlsx = list(`Prepared Long Data` = values$prepared_long_data))
    }
    if ("interp" %in% sel) {
      p <- export_interp_tables()
      if (length(p) > 0) items[["interp"]] <- list(csv = p, xlsx = p)
    }
    if ("split" %in% sel) {
      p <- export_split_tables()
      if (length(p) > 0) items[["split"]] <- list(csv = p, xlsx = p)
    }
    items
  }

  output$download_sel_csv <- downloadHandler(
    filename = function() paste0("ABPM_selected_results_", Sys.Date(), ".zip"),
    content = function(file) {
      items <- export_items_reactive()
      packed <- length(items) > 0 && isTRUE(write_export_zip(items, file))
      if (!packed) {
        showNotification(tr(lang(), "export_empty_warn"), type = "warning", duration = 5)
        return(invisible(NULL))
      }
    },
    contentType = "application/zip"
  )

  output$download_sel_xlsx <- downloadHandler(
    filename = function() paste0("ABPM_selected_results_", Sys.Date(), ".xlsx"),
    content = function(file) {
      items <- export_items_reactive()
      if (length(items) == 0) {
        showNotification(tr(lang(), "export_empty_warn"), type = "warning", duration = 5)
        return(NULL)
      }
      sheets <- unlist(lapply(items, function(it) it$xlsx), recursive = FALSE)
      sheet_names <- substr(vapply(names(sheets), sanitize_filename, character(1)), 1, 31)
      # de-duplicate sheet names defensively
      if (any(duplicated(sheet_names))) {
        sheet_names <- make.unique(sheet_names, sep = "_")
        sheet_names <- substr(sheet_names, 1, 31)
      }
      names(sheets) <- sheet_names
      openxlsx::write.xlsx(sheets, file = file, overwrite = TRUE, asTable = TRUE)
    }
  )
