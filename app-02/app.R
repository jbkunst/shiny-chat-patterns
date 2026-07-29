library(shiny)
library(bslib)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat/pkg-r")

system_prompt_text <- paste(
  "Eres un asistente experto en SQL.",
  "",
  "- Genera consultas según lo solicitado por el usuario.",
  "- Entrega primero el código y luego una explicación breve.",
  "- Si falta información, pide una aclaración.",
  "- Termina con una pregunta para continuar la conversación.",
  sep = "\n"
)

greeting_text <- "Hola. Puedo ayudarte a escribir y explicar consultas SQL. ¿Qué necesitas consultar?"

ui <- bslib::page_sidebar(
  title = "App 02 - Chat SQL",
  sidebar = sidebar(
    width = 400,
    shinychat::chat_ui("chat", placeholder = "Ingresa un mensaje...")
  )
)

server <- function(input, output, session) {
  
  # https://github.com/posit-dev/shinychat?tab=readme-ov-file#example
  chat <- ellmer::chat_openai(
    model = Sys.getenv("OPENAI_MODEL", unset = "gpt-3.5-turbo"),
    system_prompt = system_prompt_text
    )

  # Append an initial message to the chat.
  shinychat::chat_append("chat", greeting_text)
  
  shiny::observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
    print(chat)
    # The response is generated asynchronously after the user submits a message.
  })

}

shinyApp(ui, server)
