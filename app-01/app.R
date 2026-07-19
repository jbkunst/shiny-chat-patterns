library(shiny)
library(bslib)

ui <- bslib::page_navbar(
  sidebar = sidebar(
    width = 400
  )
)

server <- function(input, output, session) {
}

shinyApp(ui, server)