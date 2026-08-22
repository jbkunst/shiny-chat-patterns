library(shiny)
library(bslib)

# user interface ----------------------------------------------------------

ui <- page_sidebar(
  title = "App 00 · Shiny desde cero",
  sidebar = sidebar(
    textInput("name", "Nombre", value = "Joshua"),
    sliderInput("n", "Cantidad de puntos", min = 5, max = 50, value = 20),
    selectInput("color", "Color", c(Azul = "#2C7FB8", Verde = "#2CA25F", Naranjo = "#F28E2B"))
  ),
  card(
    card_header("Una entrada, una salida"),
    textOutput("greeting"),
    plotOutput("plot")
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {
  output$greeting <- renderText(paste("Hola", input$name))

  output$plot <- renderPlot({
    plot(seq_len(input$n), pch = 19, col = input$color, xlab = NULL, ylab = NULL)
  })
}

shinyApp(ui, server)
