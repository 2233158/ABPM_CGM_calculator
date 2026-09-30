# --- 5. Static UI shell: persistent header (language switch / tour) + page ---
# Everything else is rendered by output$page (build_ui) so that the interface
# language can be switched without reloading the app.
ui <- fluidPage(
  theme = shinytheme("flatly"),
  shinyjs::useShinyjs(),
  if (has_introjs) rintrojs::introjsUI() else NULL,

  tags$head(
    tags$style(HTML("
      .well h5 { margin-top: 0; margin-bottom: 10px; font-weight: bold; }
      .summary-well { background-color: #f0f9ff; border: 1px solid #b3e0ff; border-radius: 5px; padding: 10px 15px; min-height: 130px; }
      .stats-well { background-color: #f8f9fa; border-radius: 5px; padding: 10px 15px; min-height: 130px; }
      .plot-well { background-color: #ffffff; border: 1px solid #ddd; border-radius: 5px; padding: 5px; margin-bottom: 15px; }
      .plot-well-header { padding: 8px 15px; background-color: #f5f5f5; border-bottom: 1px solid #ddd; border-radius: 5px 5px 0 0; font-weight: bold; color: #337ab7; }
      .plot-well-body { padding: 15px; }
      .app-header { display: flex; align-items: center; justify-content: space-between;
                    flex-wrap: wrap; background-color: #ffffff; border-bottom: 1px solid #e5e5e5;
                    padding: 10px 20px; margin-bottom: 10px; }
      .app-header .app-title { font-size: 1.5em; font-weight: bold; color: #2c3e50; }
      .app-header .app-tools { display: flex; align-items: center; gap: 10px; }
      .app-header .app-tools .radio-inline { margin-bottom: 0; }
      footer { text-align: center; padding: 15px; background-color: #f5f5f5;
               margin-top: 30px; border-top: 1px solid #ddd; font-size: 0.9em; color: #555; }
    "))
  ),

  div(class = "app-header",
      div(class = "app-title", uiOutput("header_title")),
      div(class = "app-tools",
          radioButtons("lang_radio", NULL,
                       choices = c("English" = "en", "中文" = "zh"),
                       selected = "en", inline = TRUE),
          actionButton("tour_btn", NULL, icon = icon("map-signs"),
                       class = "btn-sm btn-info",
                       title = "Start guided tour / 开始引导"))
  ),

  uiOutput("page"),

  tags$footer(uiOutput("footer_text"))
)

# --- 6. Run the Application ---
shinyApp(ui = ui, server = server)
