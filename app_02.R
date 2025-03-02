library(shiny)
library(bslib)
library(here)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat")

ui <- bslib::page_navbar(
  sidebar = sidebar(
    width = 400,
    shinychat::chat_ui("chat", placeholder = "Ingresa un mensaje...")
  )
)

server <- function(input, output, session) {
  
  # https://github.com/posit-dev/shinychat?tab=readme-ov-file#example
  chat <- ellmer::chat_openai(
    model = "gpt-3.5-turbo",
    system_prompt = paste(readLines(here("md/app_02_prompt.md"), warn = FALSE), collapse = "\n")
    )

  # puedo _appendear_ cualquier texto.
  shinychat::chat_append("chat", paste(readLines(here("md/app_02_saludo.md"), warn = FALSE), collapse = "\n"))
  
  shiny::observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
    print(chat)
    # va desfasado debido a que muestra lo que existe cuando el user escribe, la respuestas 
    # se generan después.
  })

}

shinyApp(ui, server)