library(shiny)

source("R/data_loader.R", local = TRUE)
source("R/ui_analysis.R", local = TRUE)
source("R/server_analysis.R", local = TRUE)
source("R/prediction_app.R", local = TRUE)

app_data <- load_app_data()

ui <- navbarPage(
  title = "CPBL Data Science",
  windowTitle = "CPBL Data Science",
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  tabPanel("資料分析", analysis_ui(app_data)),
  tabPanel("預測結果", prediction_ui(app_data))
)

server <- function(input, output, session) {
  analysis_server(input, output, session, app_data)
  prediction_server(input, output, session, app_data)
}

shinyApp(ui, server)
