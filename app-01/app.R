library(shiny)
library(bslib)

ui <- bslib::page_sidebar(
  title = "App 01 - Estructura básica",
  sidebar = sidebar(
    width = 400
  )
)

server <- function(input, output, session) {
}

shinyApp(ui, server)
