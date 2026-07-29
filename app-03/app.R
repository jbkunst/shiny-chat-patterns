library(shiny)
library(bslib)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat/pkg-r")

system_prompt_text <- paste(
  "Eres un asistente experto en SQL. Responde de forma breve y clara.",
  "",
  "También puedes usar `obtener_hora_actual` para consultar la fecha y hora del sistema. Usa la herramienta cuando el usuario pregunte por la hora, la fecha o solicite un cálculo que dependa del momento actual.",
  sep = "\n"
)

greeting_text <- "Hola. Puedo consultar la fecha y hora actual. Prueba preguntando: **¿qué hora es?**"

ui <- bslib::page_sidebar(
  title = "App 03 - Chat con herramienta",
  sidebar = sidebar(
    width = 400,
    shinychat::chat_ui("chat", placeholder = "Ingresa un mensaje...")
  ),
  verbatimTextOutput("salida")
)

server <- function(input, output, session) {
  
  fecha_hora_reac <- reactiveVal(NULL)

  obtener_hora_actual <- function(){
    cli::cli_inform("Ejecutando `obtener_hora_actual`")
    x <- Sys.time()
  
    # Update a reactive value so Shiny can display the tool result.
    # The function lives inside server because it modifies session state.
    fecha_hora_reac(x)
    x
  }

  output$salida <- renderText({
    if(is.null(fecha_hora_reac())) return(NULL)
    paste0("La hora es ", fecha_hora_reac())
  })

  chat <- ellmer::chat_openai(
    model = Sys.getenv("OPENAI_MODEL", unset = "gpt-3.5-turbo"),
    system_prompt = system_prompt_text
    )

  obtener_hora_actual <- tool(
    obtener_hora_actual,
    name = "obtener_hora_actual",
    description =  "Función que al ejecutar retorna la fecha y hora actual del sistema.",
    arguments = list()
  )
  
  chat$register_tool(obtener_hora_actual)

  shinychat::chat_append("chat", greeting_text)
  
  shiny::observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })

}

shinyApp(ui, server)
