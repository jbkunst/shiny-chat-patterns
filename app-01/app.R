library(shiny)
library(bslib)
library(datos)

# data --------------------------------------------------------------------

penguins <- datos::pinguinos
species <- c("Todas", sort(unique(stats::na.omit(penguins$especie))))

# user interface ----------------------------------------------------------

ui <- page_sidebar(
  title = "App 01 · Shiny básico",
  sidebar = sidebar(selectInput("species", "Especie", choices = species)),
  layout_columns(
    value_box("Registros", textOutput("n_rows")),
    value_box("Masa promedio", textOutput("avg_mass")),
    col_widths = c(6, 6)
  ),
  layout_columns(
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(6, 6)
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {
  data <- reactive({
    if (input$species == "Todas") {
      penguins
    } else {
      penguins[penguins$especie == input$species, ]
    }
  })

  output$n_rows <- renderText(nrow(data()))
  output$avg_mass <- renderText(paste0(round(mean(data()$masa_corporal_g, na.rm = TRUE)), " g"))

  output$plot <- renderPlot({
    df <- data()

    plot(
      df$largo_aleta_mm,
      df$masa_corporal_g,
      pch = 19,
      xlab = "Largo de aleta (mm)",
      ylab = "Masa corporal (g)"
    )
  })

  output$table <- renderTable(head(data(), 10), striped = TRUE, hover = TRUE)
}

shinyApp(ui, server)
