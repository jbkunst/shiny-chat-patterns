library(shiny)
library(bslib)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat/pkg-r")

ui <- bslib::page_navbar(
  sidebar = sidebar(
    width = 400,
    shinychat::chat_ui("chat", placeholder = "Ingresa un mensaje...")
  ),
  nav_panel(
    title = "Panel",
    verbatimTextOutput("salida")
  )
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
    model = "gpt-3.5-turbo",
    system_prompt = paste(readLines("prompt.md", warn = FALSE), collapse = "\n")
    )

  obtener_hora_actual <- tool(
    obtener_hora_actual,
    name = "obtener_hora_actual",
    description =  "Función que al ejecutar retorna la fecha y hora actual del sistema.",
    arguments = list()
  )
  
  chat$register_tool(obtener_hora_actual)

  greeting <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
  shinychat::chat_append("chat", greeting)
  
  shiny::observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })

}

shinyApp(ui, server)
