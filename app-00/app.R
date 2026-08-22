library(shiny)
library(bslib)
library(forecast)

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 00 · Shiny desde cero",
  sidebar = sidebar(
    textInput("title", "Título", value = "Pasajeros aéreos"),
    sliderInput("n", "Cantidad de puntos", min = 24, max = 144, value = 36, step = 12),
    checkboxInput("forecast", "Mostrar pronóstico", value = FALSE)
  ),
  h2(textOutput("plot_title")),
  plotOutput("plot")
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  output$plot_title <- renderText(input$title)

  output$plot <- renderPlot({
    fun <- if (input$forecast) forecast::forecast else identity
    plot(fun(head(AirPassengers, input$n)), xlab = NULL, ylab = "Pasajeros (miles)")
  })
}

shinyApp(ui, server)
