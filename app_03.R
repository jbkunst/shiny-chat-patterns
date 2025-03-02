library(shiny)
library(bslib)
library(here)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat")

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
    x <-Sys.time()
  
    # aprovecho de actualizar una variable reactiva para utilizarla en shiny
    # la función debe estar definida dentro del server para actualizar
    # la variable reactiva, en otro caso puede estar definida en otra parte.
    fecha_hora_reac(x)
    x
  }

  output$salida <- renderText({
    if(is.null(fecha_hora_reac())) return(NULL)
    paste0("La hora es ", fecha_hora_reac())
  })

  chat <- ellmer::chat_openai(
    model = "gpt-3.5-turbo",
    system_prompt = paste(readLines(here("md/app_03_prompt.md"), warn = FALSE), collapse = "\n")
    )

  chat$register_tool(tool(
    .fun = obtener_hora_actual,
    .description = "Función que al ejecutar retorna la fecha y hora actual del sistema."
  ))
  
  shinychat::chat_append("chat",  "Hola! Comencemos!")
  
  shiny::observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })

}

shinyApp(ui, server)