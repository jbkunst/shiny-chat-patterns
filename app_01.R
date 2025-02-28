library(shiny)
library(bslib)

ui <- bslib::page_navbar(
  sidebar = sidebar(
    width = 350,
    "Sidebar"
  )
)

server <- function(input, output, session) {
}

shinyApp(ui, server)
