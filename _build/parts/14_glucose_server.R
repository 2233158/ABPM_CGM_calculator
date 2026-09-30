  # --- Glucose target presets: normal range / diabetes management range ---
  apply_glu_preset <- function(lo, hi, msg_key) {
    for (p in c("day", "night", "24h")) {
      updateNumericInput(session, paste0("glu_", p, "_lower"), value = lo)
      updateNumericInput(session, paste0("glu_", p, "_upper"), value = hi)
    }
    showNotification(tr(lang(), msg_key), type = "message", duration = 5)
  }
  observeEvent(input$preset_glu_normal, {
    if (isTRUE(values$targets_locked)) {
      showNotification(chart_tr("locked_warn"), type = "warning", duration = 5)
      return()
    }
    apply_glu_preset(3.9, 7.8, "glu_preset_normal_msg")
  }, ignoreInit = TRUE)
  observeEvent(input$preset_glu_diabetes, {
    if (isTRUE(values$targets_locked)) {
      showNotification(chart_tr("locked_warn"), type = "warning", duration = 5)
      return()
    }
    apply_glu_preset(3.9, 10.0, "glu_preset_diabetes_msg")
  }, ignoreInit = TRUE)

  # --- Glucose (CGM) personalized analysis block ---
  has_glu_results <- reactive({
    isTRUE(values$metrics_calculated_successfully) &&
      !is.null(values$metric_results$`24h`$GLU) &&
      is.data.frame(values$metric_results$`24h`$GLU) &&
      nrow(values$metric_results$`24h`$GLU) > 0
  })

  output$personal_glu_block <- renderUI({
    req(has_glu_results())
    tagList(
      h4(icon("notes-medical"), tr(lang(), "glu_followup_title")),
      uiOutput("glu_personal_followup_level"),
      h4(icon("project-diagram"), tr(lang(), "glu_dims_title")),
      DTOutput("glu_personal_dimension_table"),
      br(),
      h4(icon("book-medical"), tr(lang(), "glu_guidelines_title")),
      DTOutput("glu_personal_guideline_table"),
      p(style = "font-size:0.85em;color:#666;", tr(lang(), "glu_note")),
      br(),
      h4(icon("comment-medical"), tr(lang(), "advice_title")),
      uiOutput("glu_personal_advice")
    )
  })

  glu_assessment_reactive <- reactive({
    req(has_glu_results(), input$analysis_maskid)
    build_glucose_assessment(values$metric_results, input$analysis_maskid, lang = lang())
  })

  output$glu_personal_followup_level <- renderUI({
    assessment <- glu_assessment_reactive()
    colour <- switch(assessment$followup_key,
                     "urgent" = "#c62828",
                     "elective" = "#ef6c00",
                     "routine" = "#2e7d32",
                     "#333333")
    tagList(
      h3(style = paste0("color:", colour, ";margin-top:5px;"), icon("stethoscope"), assessment$followup),
      p(chart_tr("followup_note"))
    )
  })

  output$glu_personal_dimension_table <- renderDT({
    assessment <- glu_assessment_reactive()
    datatable(assessment$dimensions, rownames = FALSE, escape = FALSE,
              options = list(dom = "t", paging = FALSE, searching = FALSE,
                             ordering = FALSE, scrollX = TRUE))
  })

  output$glu_personal_guideline_table <- renderDT({
    assessment <- glu_assessment_reactive()
    datatable(assessment$guidelines, rownames = FALSE,
              options = list(dom = "t", paging = FALSE, searching = FALSE,
                             ordering = FALSE, scrollX = TRUE))
  })

  output$glu_personal_advice <- renderUI({
    assessment <- glu_assessment_reactive()
    wellPanel(
      tags$ul(lapply(assessment$suggestions, tags$li)),
      p(style = "font-size:0.85em;color:#666;margin-bottom:0;",
        chart_tr("advice_note"))
    )
  })
