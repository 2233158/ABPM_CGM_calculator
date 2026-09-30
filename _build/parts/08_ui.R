# --- 3. UI Definition (bilingual; built by build_ui(lang, settings)) ---
# The page is re-rendered on language switch; input values are restored from
# the `settings` snapshot so no settings are lost.

build_guide_ui <- function(lang) {
  tr2 <- function(key) tr(lang, key)
  steps <- tr(lang, "guide")
  step_blocks <- lapply(seq_along(steps), function(i) {
    tagList(
      h5(tags$strong(paste0(i, ". ", steps[[i]]$title))),
      tags$ul(lapply(steps[[i]]$items, tags$li)),
      br()
    )
  })
  faq_items <- lapply(tr(lang, "faq"), function(f) tags$li(f))
  tagList(
    div(class = "panel panel-default",
        div(class = "panel-heading", style = "background-color: #f5f5f5;",
            h4(icon("book-reader"), tr2("guide_title"), style = "text-align: center; margin: 5px 0;")),
        div(class = "panel-body", style = "font-size: 0.95em;",
            p(tags$em(tr2("guide_intro"))),
            do.call(tagList, step_blocks),
            h5(tags$strong(icon("question"), " ", tr2("faq_title"))),
            tags$ul(faq_items)
        )),
    div(style = "max-height: 420px; overflow-y: auto;",
        h5(tags$strong(icon("tag"), " ", tr2("field_defs_title"), " / ", tr("en", "field_defs_title"))),
        DTOutput("guide_metric_defs_table"))
  )
}

build_author_panel <- function(lang) {
  tr2 <- function(key) tr(lang, key)
  div(class = "panel panel-info", style = "margin-top: 20px;",
      div(class = "panel-heading", style = "text-align: center;",
          h5(icon("user-md"), tr2("about_author"), style = "margin: 5px 0;")),
      div(class = "panel-body", style = "text-align: center; font-size: 0.95em;",
          p(strong(tr2("about_name"))),
          p(tr2("about_affil")),
          p(style = "color: #666;", tr2("app_version")),
          p(tr2("about_contact"), " ", a("morethanlee@163.com", href = "mailto:morethanlee@163.com")),
          hr(),
          p(strong(icon("copyright"), " ", tr2("footer_copyright")))
      ))
}

build_ui <- function(lang, settings) {
  tr2 <- function(key) tr(lang, key)
  s <- function(id, default) {
    v <- settings[[id]]
    if (is.null(v)) default else v
  }
  time_row <- function(id_h, id_m, label, def_h, def_m) {
    tagList(
      tags$label(label),
      fluidRow(
        column(5, style = "padding-right:1px;",
               numericInput(id_h, NULL, value = s(id_h, def_h), min = 0, max = 23, step = 1)),
        column(2, style = "padding-left:1px; padding-right:1px; text-align: center; line-height: 34px;",
               tags$strong(":")),
        column(5, style = "padding-left:1px;",
               numericInput(id_m, NULL, value = s(id_m, def_m), min = 0, max = 59, step = 1))
      )
    )
  }
  target_tab <- function(period) {
    m <- function(metric, def_l, def_u) {
      fluidRow(
        column(6, numericInput(paste0(tolower(metric), "_", period, "_lower"),
                               paste0(metric, " ", tr2("lower")),
                               value = s(paste0(tolower(metric), "_", period, "_lower"), def_l))),
        column(6, numericInput(paste0(tolower(metric), "_", period, "_upper"),
                               paste0(metric, " ", tr2("upper")),
                               value = s(paste0(tolower(metric), "_", period, "_upper"), def_u)))
      )
    }
    if (period == "day") {
      tagList(m("SBP", 90, 120), m("DBP", 55, 70), m("HR", 60, 100),
              m("PP", NA, NA), m("MAP", NA, NA))
    } else if (period == "night") {
      tagList(m("SBP", 90, 110), m("DBP", 55, 60), m("HR", 50, 90),
              m("PP", NA, NA), m("MAP", NA, NA))
    } else {
      tagList(m("SBP", 90, 115), m("DBP", 55, 65), m("HR", 55, 95),
              m("PP", NA, NA), m("MAP", NA, NA))
    }
  }

  sidebar <- sidebarPanel(
    width = 3,

    h4(icon("database"), tr2("data_source_title")),
    radioButtons("domain", tr2("domain_label"),
                 choiceNames = list(tr2("domain_bp"), tr2("domain_glu")),
                 choiceValues = list("bp", "glu"),
                 selected = s("domain", "bp"), inline = TRUE),
    conditionalPanel(
      condition = "input.domain == 'bp'",
      checkboxInput("use_builtin_data", tr2("use_builtin"), value = s("use_builtin_data", FALSE)),
      checkboxInput("use_device_sample", tr2("use_device_sample"), value = s("use_device_sample", TRUE)),
      p(tr2("device_sample_hint"), style = "font-size:0.85em;color:#555;"),
      if (!DEMO_MODE) {
        tagList(
          radioButtons("upload_mode", tr2("upload_mode_label"),
                       choiceNames = list(tr2("upload_mode_csv"), tr2("upload_mode_raw")),
                       choiceValues = list("csv", "raw"),
                       selected = s("upload_mode", "csv")),
          conditionalPanel(
            condition = "input.upload_mode == 'csv'",
            fileInput("csv_files", tr2("choose_csv_files"), multiple = TRUE,
                      accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
            p(tr2("csv_hint"), style = "font-size:0.85em;color:#555;")
          ),
          conditionalPanel(
            condition = "input.upload_mode == 'raw'",
            fileInput("raw_files", tr2("choose_raw_files"), multiple = TRUE,
                      accept = c(".xls", ".xlsx", "application/vnd.ms-excel")),
            p(tr2("raw_hint"), style = "font-size:0.85em;color:#555;")
          )
        )
      } else {
        p(icon("lock"), tr2("demo_mode_note"), style = "font-size:0.85em;color:#666;")
      }
    ),
    conditionalPanel(
      condition = "input.domain == 'glu'",
      checkboxInput("use_glucose_sample", tr2("use_glucose_sample"),
                    value = s("use_glucose_sample", FALSE)),
      if (!DEMO_MODE) {
        tagList(
          fileInput("glu_csv_files", tr2("choose_glu_csv_files"), multiple = TRUE,
                    accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
          p(tr2("glu_csv_hint"), style = "font-size:0.85em;color:#555;"),
          fileInput("glu_raw_files", tr2("choose_glu_raw_files"), multiple = TRUE,
                    accept = c(".xlsx", ".xls", "application/vnd.ms-excel")),
          p(tr2("glu_raw_hint"), style = "font-size:0.85em;color:#555;")
        )
      } else {
        p(icon("lock"), tr2("demo_mode_note"), style = "font-size:0.85em;color:#666;")
      }
    ),
    uiOutput("mapping_panel"),
    uiOutput("raw_convert_panel"),
    wellPanel(
      style = "padding: 10px; background-color: #f8f9fa;",
      p(icon("info-circle"), tags$strong(tr2("format_help_title"))),
      tags$ul(style = "font-size: 0.85em; padding-left: 20px; color: #333;",
              tags$li(tr2("format_help_1")),
              tags$li(tr2("format_help_2")),
              tags$li(tr2("format_help_3")),
              tags$li(tr2("format_help_4")),
              tags$li(tr2("format_help_5")),
              tags$li(tr2("format_help_6")),
              tags$li(tr2("format_help_7")))
    ),
    hr(),

    h4(icon("clock"), tr2("daynight_title")),
    time_row("day1_start_h", "day1_start_m", tr2("day1_start"), 7, 0),
    time_row("day1_night_start_h", "day1_night_start_m", tr2("night1_start"), 22, 0),
    time_row("day2_start_h", "day2_start_m", tr2("day2_start"), 7, 0),
    time_row("day2_night_start_h", "day2_night_start_m", tr2("night2_start"), 22, 0),
    h5(tr2("preset_title"), style = "margin-top: 15px; margin-bottom: 5px;"),
    fluidRow(
      column(6, actionButton("preset_east_asia", tr2("preset_east"), class = "btn-sm btn-block btn-info")),
      column(6, actionButton("preset_western", tr2("preset_west"), class = "btn-sm btn-block btn-primary"))
    ),
    hr(),

    h4(icon("chart-line"), tr2("interp_title")),
    radioButtons("interp_mode", NULL,
                 choiceNames = list(
                   HTML(paste0("<b>", tr2("interp_mode_valid_name"), "</b><br><small>",
                               tr2("interp_valid_desc"), "</small>")),
                   HTML(paste0("<b>", tr2("interp_mode_full_name"), "</b><br><small>",
                               tr2("interp_full_desc"), "</small>"))
                 ),
                 choiceValues = list("valid", "full"),
                 selected = s("interp_mode", "valid")),
    p(tr2("interp_note"), style = "font-size:0.85em;color:#555;"),
    hr(),

    h4(icon("crop-alt"), tr2("window_title")),
    radioButtons("window_mode", NULL,
                 choiceNames = list(tr2("window_mode_calendar"),
                                    tr2("window_mode_from_first"),
                                    tr2("window_mode_from_start"),
                                    tr2("window_mode_custom")),
                 choiceValues = list("calendar", "from_first", "from_start", "custom"),
                 selected = s("window_mode", "from_first")),
    conditionalPanel(
      condition = "input.window_mode == 'from_first'",
      numericInput("window_hours", tr2("window_hours"),
                   value = s("window_hours", 24), min = 1, max = 168, step = 1)
    ),
    conditionalPanel(
      condition = "input.window_mode == 'from_start'",
      textInput("window_start_spec", tr2("window_start_spec"),
                value = s("window_start_spec", ""), placeholder = "HHMM+XD, e.g. 0800+0D"),
      numericInput("window_hours", tr2("window_hours"),
                   value = s("window_hours", 24), min = 1, max = 168, step = 1)
    ),
    conditionalPanel(
      condition = "input.window_mode == 'custom'",
      textInput("window_start_spec", tr2("window_start_spec"),
                value = s("window_start_spec", ""), placeholder = "HHMM+XD, e.g. 0800+0D"),
      textInput("window_end_spec", tr2("window_end_spec"),
                value = s("window_end_spec", ""), placeholder = "HHMM+XD, e.g. 0800+1D")
    ),
    p(tr2("window_hint"), style = "font-size:0.85em;color:#555;"),
    hr(),

    h4(icon("wave-square"), tr2("vim_title")),
    radioButtons("vim_mode", NULL,
                 choiceNames = list(tr2("vim_mode_cohort"), tr2("vim_mode_fixed")),
                 choiceValues = list("cohort", "fixed"),
                 selected = s("vim_mode", "cohort")),
    conditionalPanel(
      condition = "input.vim_mode == 'fixed'",
      numericInput("vim_ref_mean", tr2("vim_ref_mean"),
                   value = s("vim_ref_mean", 100), min = 1, max = 400, step = 1)
    ),
    wellPanel(
      style = "padding: 10px; background-color: #f8f9fa;",
      h5(tags$strong(tr2("vim_formula_title")), style = "margin-top:0;"),
      withMathJax(helpText("$$VIM = \\frac{SD}{\\bar{x}^{\\beta}} \\times k$$")),
      tags$ul(style = "font-size: 0.85em; padding-left: 20px;",
              tags$li(tags$strong(tr2("vim_mode_cohort"), ": "), tr2("vim_cohort_text")),
              tags$li(tags$strong(tr2("vim_mode_fixed"), ": "), tr2("vim_fixed_text")),
              tags$li(tags$strong(tr2("key_overview"), ": "), tr2("vim_meaning_text")),
              tags$li(tags$strong(tr2("vim_params_text")), tr2("vim_insufficient")))
    ),
    hr(),

    div(style = "margin-bottom: 10px;",
        actionButton("process_data_btn", tr2("process_btn"), icon = icon("cogs"),
                     class = "btn-primary btn-lg btn-block")),
    hr(),

    h4(icon("bullseye"), tr2("targets_title")),
    div(class = "alert alert-info",
        style = "padding:8px 10px; margin-bottom:10px; font-size:0.9em;",
        tr2("targets_hint")),
    tabsetPanel(
      id = "target_tabs",
      tabPanel(tr2("tab_day"), target_tab("day")),
      tabPanel(tr2("tab_night"), target_tab("night")),
      tabPanel(tr2("tab_24h"), target_tab("24h")),
      tabPanel(tr2("tab_glu"),
               p(tr2("glu_targets_hint"), style = "font-size:0.85em;color:#555;"),
               fluidRow(column(6, numericInput("glu_day_lower", paste0("GLU ", tr2("lower"), " (mmol/L)"),
                                               value = s("glu_day_lower", 3.9))),
                        column(6, numericInput("glu_day_upper", paste0("GLU ", tr2("upper"), " (mmol/L)"),
                                               value = s("glu_day_upper", 10.0)))),
               fluidRow(column(6, numericInput("glu_night_lower", paste0("GLU ", tr2("lower"), " (mmol/L)"),
                                               value = s("glu_night_lower", 3.9))),
                        column(6, numericInput("glu_night_upper", paste0("GLU ", tr2("upper"), " (mmol/L)"),
                                               value = s("glu_night_upper", 10.0)))),
               fluidRow(column(6, numericInput("glu_24h_lower", paste0("GLU ", tr2("lower"), " (mmol/L)"),
                                               value = s("glu_24h_lower", 3.9))),
                        column(6, numericInput("glu_24h_upper", paste0("GLU ", tr2("upper"), " (mmol/L)"),
                                               value = s("glu_24h_upper", 10.0)))),
               fluidRow(
                 column(6, actionButton("preset_glu_normal", tr2("glu_preset_normal"),
                                        class = "btn-sm btn-block btn-info",
                                        style = "margin-top: 6px;")),
                 column(6, actionButton("preset_glu_diabetes", tr2("glu_preset_diabetes"),
                                        class = "btn-sm btn-block btn-warning",
                                        style = "margin-top: 6px;"))
               ))
    ),
    actionButton("apply_targets_btn", tr2("apply_targets_btn"), icon = icon("magic"),
                 class = "btn-sm btn-info btn-block", style = "margin-top: 10px;"),
    actionButton("preset_targets", tr2("preset_targets_btn"), icon = icon("bullseye"),
                 class = "btn-sm btn-warning btn-block", style = "margin-top: 5px;"),
    shinyjs::disabled(
      actionButton("save_custom_targets_btn", tr2("save_targets_btn"), icon = icon("lock"),
                   class = "btn-sm btn-success btn-block", style = "margin-top: 5px; margin-bottom: 10px;")
    ),
    hr(),

    div(style = "margin-bottom: 10px;",
        shinyjs::disabled(
          actionButton("calculate_metrics_btn", tr2("calc_btn"), icon = icon("calculator"),
                       class = "btn-success btn-lg btn-block")
        )),
    hr(),

    h4(icon("download"), tr2("export_title")),
    checkboxGroupInput("export_items", tr2("export_select"),
                       choices = setNames(
                         c("wide", "period", "personal", "prepared", "interp", "split"),
                         c(tr2("export_wide"), tr2("export_period"), tr2("export_personal"),
                           tr2("export_prepared"), tr2("export_interp"), tr2("export_split"))),
                       selected = s("export_items", c("wide", "period", "personal"))),
    downloadButton("download_sel_csv", tr2("export_csv_btn"), class = "btn-info btn-block"),
    downloadButton("download_sel_xlsx", tr2("export_xlsx_btn"), class = "btn-success btn-block",
                   style = "margin-top: 5px;")
  ) # end sidebarPanel

  main <- mainPanel(
    width = 9,
    tabsetPanel(id = "main_tabset", type = "tabs",
                selected = s("main_tabset", "raw_data_tab"),

                # ---- View input data ----
                tabPanel(title = span(icon("file-alt"), tr2("tab_input")), value = "raw_data_tab",
                         br(), h4(textOutput("data_source_title")),
                         uiOutput("data_status_line"),
                         DTOutput("raw_data_table"),
                         hr(),
                         h5(tr2("raw_summary_title")), DTOutput("raw_convert_summary"),
                         h5(tr2("raw_preview_title")), DTOutput("raw_convert_preview")),

                # ---- Processed data ----
                tabPanel(title = span(icon("wrench"), tr2("tab_processed")), value = "processed_data_tab",
                         br(),
                         tabsetPanel(id = "processing_subtabs",
                                     tabPanel(title = tr2("subtab_prepared"), value = "prepared_long",
                                              br(), h5(tr2("caption_prepared")), DTOutput("prepared_long_table"),
                                              hr(), h5(paste0(tr2("caption_wide"), "(pre-interpolation)")),
                                              uiOutput("wide_data_tabs")),
                                     tabPanel(title = tr2("subtab_interp"), value = "wide_interpolated",
                                              br(), h5(tr2("caption_interp")),
                                              uiOutput("interpolated_data_tabs")))),

                # ---- Segmented data ----
                tabPanel(title = span(icon("columns"), tr2("tab_split")), value = "split_data_tab",
                         br(), h5(tr2("progress_split")),
                         tabsetPanel(id = "split_period_tabs",
                                     tabPanel(title = span(icon("cloud-moon"), tr2("split_day0night")), value = "day0_night",
                                              br(), uiOutput("split_day0_night_metric_tabs")),
                                     tabPanel(title = span(icon("sun"), tr2("split_day1day")), value = "day1_day",
                                              br(), uiOutput("split_day1_day_metric_tabs")),
                                     tabPanel(title = span(icon("moon"), tr2("split_day1night")), value = "day1_night",
                                              br(), uiOutput("split_day1_night_metric_tabs")),
                                     tabPanel(title = span(icon("cloud-sun"), tr2("split_day2day")), value = "day2_day",
                                              br(), uiOutput("split_day2_day_metric_tabs")),
                                     tabPanel(title = span(icon("hourglass-half"), tr2("split_24h_interp")), value = "full_24h_interp",
                                              br(), h5(tr2("caption_full_interp")),
                                              uiOutput("full_24h_interpolated_data_tabs")))),

                # ---- Metric results ----
                tabPanel(title = span(icon("table"), tr2("tab_results")), value = "results_tab",
                         br(),
                         fluidRow(
                           column(12,
                                  tags$p(paste0(tr2("export_title"), " → ",
                                                tr2("export_csv_btn"), " / ", tr2("export_xlsx_btn")),
                                         style = "text-align:right; color:#666; margin-bottom:8px; font-size:0.9em;"))
                         ),
                         tabsetPanel(id = "results_period_tabs",
                                     tabPanel(title = tr2("results_day"), value = "day_results",
                                              br(), uiOutput("target_ranges_day_display"),
                                              hr(style = "border-top: 1px solid #ccc;"),
                                              uiOutput("day_metric_tabs")),
                                     tabPanel(title = tr2("results_night"), value = "night_results",
                                              br(), uiOutput("target_ranges_night_display"),
                                              hr(style = "border-top: 1px solid #ccc;"),
                                              uiOutput("night_metric_tabs")),
                                     tabPanel(title = tr2("results_24h_unified"), value = "results_24h_unified",
                                              br(), uiOutput("target_ranges_24h_unified_display"),
                                              hr(style = "border-top: 1px solid #ccc;"),
                                              uiOutput("24h_unified_metric_tabs")),
                                     tabPanel(title = tr2("results_24h_segmented"), value = "results_24h_segmented",
                                              br(), uiOutput("target_ranges_daynight_display_combined"),
                                              hr(style = "border-top: 1px solid #ccc;"),
                                              uiOutput("segmented_24h_metric_tabs")))),

                # ---- Visualization ----
                tabPanel(title = span(icon("chart-area"), tr2("tab_viz")), value = "viz_tab",
                         br(),
                         fluidRow(
                           column(4,
                                  wellPanel(
                                    style = "background-color: #f8f9fa; border-radius: 5px; padding: 15px; border: 1px solid #ddd;",
                                    selectInput("viz_maskid", label = tagList(icon("user"), tr2("choose_patient")),
                                                choices = NULL, width = "100%"),
                                    selectInput("viz_metric_select", label = tagList(icon("stethoscope"), tr2("choose_metric")),
                                                choices = c("SBP", "DBP", "HR", "PP", "MAP", "GLU"),
                                                selected = s("viz_metric_select", "SBP"), width = "100%")
                                  )),
                           column(8,
                                  wellPanel(
                                    class = "summary-well",
                                    h5(icon("binoculars"), tr2("viz_overview_title"), style = "color: #0056b3;"),
                                    uiOutput("viz_summary_header")))
                         ),
                         hr(),
                         tabsetPanel(id = "viz_sub_tabset", type = "pills",
                                     tabPanel(title = span(icon("hourglass-half"), tr2("viz_24h_unified")), value = "viz_24h_unified",
                                              br(),
                                              fluidRow(
                                                column(6, wellPanel(class = "summary-well",
                                                                    h5(icon("clipboard-check"), paste0(tr2("key_overview"), " (", tr2("viz_24h_unified"), ")")),
                                                                    uiOutput("viz_info_24h_unified"))),
                                                column(6, wellPanel(class = "stats-well",
                                                                    h5(icon("clipboard-list"), paste0(tr2("stats_summary"), " (", tr2("viz_24h_unified"), ")")),
                                                                    verbatimTextOutput("patient_summary_24h_unified")))
                                              ),
                                              fluidRow(
                                                column(12, div(class = "plot-well",
                                                               div(class = "plot-well-header", icon("chart-line"), tr2("trend_title")),
                                                               div(class = "plot-well-body", plotlyOutput("bp_trend_chart_24h_unified_limit", height = "450px"))))
                                              ),
                                              br(),
                                              fluidRow(
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("chart-pie"), tr2("donut_title")),
                                                              div(class = "plot-well-body", plotlyOutput("time_in_range_donut_24h_unified", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("tachometer-alt"), tr2("burden_title")),
                                                              div(class = "plot-well-body", plotlyOutput("burden_chart_24h_unified", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("wave-square"), tr2("variability_title")),
                                                              div(class = "plot-well-body", plotlyOutput("variability_chart_24h_unified", height = "350px"))))
                                              )),
                                     tabPanel(title = span(icon("adjust"), tr2("viz_24h_segmented")), value = "viz_24h_segmented",
                                              br(),
                                              fluidRow(
                                                column(12, div(class = "plot-well",
                                                               div(class = "plot-well-header", icon("chart-line"), tr2("trend_title")),
                                                               div(class = "plot-well-body", plotlyOutput("bp_trend_chart_24h_segmented_limits", height = "450px"))))
                                              ),
                                              br(),
                                              p(tags$strong(tr2("seg_results_title")), style = "font-size: 1.1em; color: #286090;"),
                                              p(em(tr2("seg_results_note")), style = "font-style: italic;"),
                                              fluidRow(
                                                column(6, wellPanel(class = "summary-well", style = "background-color: #e8f5e9; border-color: #c8e6c9;",
                                                                    h5(icon("clipboard-check"), paste0(tr2("key_overview"), " (", tr2("viz_24h_segmented"), ")")),
                                                                    uiOutput("viz_info_24h_segmented"))),
                                                column(6, wellPanel(class = "stats-well",
                                                                    h5(icon("clipboard-list"), paste0(tr2("stats_summary"), " (", tr2("viz_24h_segmented"), ")")),
                                                                    verbatimTextOutput("patient_summary_24h_segmented")))
                                              ),
                                              fluidRow(
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("chart-pie"), tr2("donut_title")),
                                                              div(class = "plot-well-body", plotlyOutput("time_in_range_donut_24h_segmented", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("tachometer-alt"), tr2("burden_title")),
                                                              div(class = "plot-well-body", plotlyOutput("burden_chart_24h_segmented", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("wave-square"), tr2("variability_title")),
                                                              div(class = "plot-well-body", plotlyOutput("variability_chart_24h_segmented", height = "350px"))))
                                              )),
                                     tabPanel(title = span(icon("sun"), tr2("viz_day")), value = "viz_day",
                                              br(),
                                              fluidRow(
                                                column(6, wellPanel(class = "summary-well",
                                                                    h5(icon("clipboard-check"), paste0(tr2("key_overview"), " (", tr2("viz_day"), ")")),
                                                                    uiOutput("viz_info_day"))),
                                                column(6, wellPanel(class = "stats-well",
                                                                    h5(icon("clipboard-list"), paste0(tr2("stats_summary"), " (", tr2("viz_day"), ")")),
                                                                    verbatimTextOutput("patient_summary_day")))
                                              ),
                                              fluidRow(
                                                column(12, div(class = "plot-well",
                                                               div(class = "plot-well-header", icon("chart-line"), tr2("trend_title")),
                                                               div(class = "plot-well-body", plotlyOutput("bp_trend_chart_day", height = "450px"))))
                                              ),
                                              br(),
                                              fluidRow(
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("chart-pie"), tr2("donut_title")),
                                                              div(class = "plot-well-body", plotlyOutput("time_in_range_donut_day", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("tachometer-alt"), tr2("burden_title")),
                                                              div(class = "plot-well-body", plotlyOutput("burden_chart_day", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("wave-square"), tr2("variability_title")),
                                                              div(class = "plot-well-body", plotlyOutput("variability_chart_day", height = "350px"))))
                                              )),
                                     tabPanel(title = span(icon("moon"), tr2("viz_night")), value = "viz_night",
                                              br(),
                                              fluidRow(
                                                column(6, wellPanel(class = "summary-well",
                                                                    h5(icon("clipboard-check"), paste0(tr2("key_overview"), " (", tr2("viz_night"), ")")),
                                                                    uiOutput("viz_info_night"))),
                                                column(6, wellPanel(class = "stats-well",
                                                                    h5(icon("clipboard-list"), paste0(tr2("stats_summary"), " (", tr2("viz_night"), ")")),
                                                                    verbatimTextOutput("patient_summary_night")))
                                              ),
                                              fluidRow(
                                                column(12, div(class = "plot-well",
                                                               div(class = "plot-well-header", icon("chart-line"), tr2("trend_title")),
                                                               div(class = "plot-well-body", plotlyOutput("bp_trend_chart_night", height = "450px"))))
                                              ),
                                              br(),
                                              fluidRow(
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("chart-pie"), tr2("donut_title")),
                                                              div(class = "plot-well-body", plotlyOutput("time_in_range_donut_night", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("tachometer-alt"), tr2("burden_title")),
                                                              div(class = "plot-well-body", plotlyOutput("burden_chart_night", height = "350px")))),
                                                column(4, div(class = "plot-well",
                                                              div(class = "plot-well-header", icon("wave-square"), tr2("variability_title")),
                                                              div(class = "plot-well-body", plotlyOutput("variability_chart_night", height = "350px"))))
                                              ))
                         )),

                # ---- Personalized analysis ----
                tabPanel(title = span(icon("user-check"), tr2("tab_personal")), value = "personal_analysis_tab",
                         br(),
                         fluidRow(
                           column(4,
                                  wellPanel(
                                    selectInput("analysis_maskid", tr2("choose_patient"), choices = NULL, width = "100%"),
                                    p(style = "font-size:0.85em;color:#666;", tr2("personal_note")))),
                           column(8,
                                  wellPanel(class = "summary-well",
                                            h5(icon("notes-medical"), tr2("followup_title")),
                                            uiOutput("personal_followup_level")))
                         ),
                         h4(icon("project-diagram"), tr2("dims_title")),
                         DTOutput("personal_dimension_table"),
                         br(),
                         h4(icon("book-medical"), tr2("guidelines_title")),
                         DTOutput("personal_guideline_table"),
                         br(),
                         h4(icon("comment-medical"), tr2("advice_title")),
                         uiOutput("personal_advice"),
                         br(), hr(),
                         # Glucose (CGM) block, rendered only when GLU results exist
                         uiOutput("personal_glu_block"),
                         wellPanel(
                           style = "font-size:0.85em;color:#555;",
                           tags$strong(paste0(tr2("tab_guide"), ": ")),
                           tr2("disclaimer"),
                           tags$br(),
                           a("ESC 2024", href = "https://www.escardio.org/guidelines/clinical-practice-guidelines/all-esc-practice-guidelines/elevated-blood-pressure-and-hypertension/", target = "_blank"),
                           "; ",
                           a("AHA/ACC 2025", href = "https://professional.heart.org/en/science-news/2025-high-blood-pressure-guideline", target = "_blank"),
                           "; ",
                           a(if (lang == "zh") "中国高血压防治指南（2024年修订版）" else "Chinese Hypertension Guideline (2024 revision)",
                             href = "https://pmc.ncbi.nlm.nih.gov/articles/PMC11937835/", target = "_blank")
                         )),

                # ---- Field definitions ----
                tabPanel(title = span(icon("list-alt"), tr2("tab_fielddefs")), value = "field_defs_tab",
                         br(), h4(tr2("field_defs_title")),
                         DTOutput("field_defs_table")),

                # ---- User guide ----
                tabPanel(title = span(icon("question-circle"), tr2("tab_guide")), value = "guide_tab",
                         br(),
                         build_guide_ui(lang),
                         build_author_panel(lang))
    ) # end main tabset
  ) # end mainPanel

  # sidebarPanel(width=3) + mainPanel(width=9) must live directly inside
  # sidebarLayout(); wrapping them in fluidRow/column would double-apply the
  # width rules and break the layout ratio.
  sidebarLayout(sidebar, main)
}
