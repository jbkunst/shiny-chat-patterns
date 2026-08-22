library(shiny)
library(bslib)
library(datos)

# data --------------------------------------------------------------------
pinguinos <- datos::pinguinos[
  c("especie", "isla", "masa_corporal_g", "anio", "largo_aleta_mm")
]
especies <- c("Todas", sort(unique(stats::na.omit(as.character(pinguinos$especie)))))

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 01 · Shiny básico",
  sidebar = sidebar(selectInput("especie", "Especie", choices = especies)),
  layout_columns(
    value_box("Registros", textOutput("n_filas"), showcase = icon("database")),
    value_box("Masa promedio", textOutput("masa_promedio"), showcase = icon("weight-scale")),
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(6, 6, 6, 6),
    row_heights = c(1, 4)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  data <- reactive({
    if (input$especie == "Todas") pinguinos
    else pinguinos[pinguinos$especie == input$especie, ]
  })

  output$n_filas       <- renderText(nrow(data()))
  output$masa_promedio <- renderText(paste0(round(mean(data()$masa_corporal_g, na.rm = TRUE)), " g"))

  output$plot <- renderPlot({
    df <- data()

    plot(
      df$largo_aleta_mm, df$masa_corporal_g, pch = 19, col = "#007bc2",
      xlab = "Largo de aleta (mm)", ylab = "Masa corporal (g)")
  })

  output$table <- renderTable(head(data(), 10), striped = TRUE, hover = TRUE)
}

shinyApp(ui, server)
