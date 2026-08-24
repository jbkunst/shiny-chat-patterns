library(shiny)
library(bslib)
library(ellmer)
library(shinychat)

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 11 · Chat sin tools",
  fillable = TRUE,
  sidebar = sidebar(
    shinychat::chat_ui(
      "chat",
      messages = "Hola, soy un chat sin acceso al dashboard.",
      placeholder = "Escribe un mensaje..."
    ),
    width = 400
  ),
  layout_columns(
    card(card_header(textOutput("titulo")), plotOutput("plot")),
    card(card_header("Observaciones"), tableOutput("table")),
    col_widths = 12,
    row_heights = c(1, 1)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output) {
  output$titulo <- renderText("Sin serie seleccionada")

  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = "Responde brevemente en español. No tienes acceso al dashboard ni a sus datos."
  )

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
