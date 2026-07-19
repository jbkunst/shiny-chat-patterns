library(shiny)
library(bslib)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat/pkg-r")

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
    system_prompt = paste(readLines("prompt.md", warn = FALSE), collapse = "\n")
    )

  # Append an initial message to the chat.
  shinychat::chat_append("chat", paste(readLines("greeting.md", warn = FALSE), collapse = "\n"))
  
  shiny::observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
    print(chat)
    # The response is generated asynchronously after the user submits a message.
  })

}

shinyApp(ui, server)
