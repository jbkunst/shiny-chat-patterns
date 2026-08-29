library(shiny)
library(bslib)
library(tinyplot)

# data --------------------------------------------------------------------
paises <- utils::read.csv(file.path("..", "data", "paises.csv"), fileEncoding = "UTF-8")
continentes <- c("Todos", sort(unique(paises$continente)))

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 01 · Dashboard reactivo",
  sidebar = sidebar(selectInput("continente", "Continente", choices = continentes), width = 400),
  layout_columns(
    value_box("Países", textOutput("n_filas"), showcase = icon("earth-americas"), theme = "text-primary"),
    value_box("Esperanza de vida", textOutput("vida"), showcase = icon("heart-pulse"), theme="text-primary"),
    value_box("Población", textOutput("poblacion"), showcase = icon("people-group"), theme = "text-primary"),
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(4, 4, 4, 6, 6),
    row_heights = c(1, 3)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  data <- reactive({
    if (input$continente == "Todos") paises
    else paises[paises$continente == input$continente, ]
  })

  output$n_filas   <- renderText(nrow(data()))
  output$vida      <- renderText(paste0(round(mean(data()$esperanza_de_vida), 1), " años"))
  output$poblacion <- renderText(paste0(round(sum(data()$poblacion) / 1e6), " millones"))

  output$plot <- renderPlot({
    tinyplot(esperanza_de_vida ~ pib_per_capita, data = paises, pch = 19, col = "#d2d2d2", log = "x")
    tinyplot_add(data = data(), col = "#0E4F5A", cex = 1.5)
  })

  output$table <- renderTable(data(), striped = TRUE, hover = TRUE)
}

shinyApp(ui, server)
