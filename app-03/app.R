library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(tinyplot)

# data --------------------------------------------------------------------
paises <- utils::read.csv(file.path("..", "data", "paises.csv"), fileEncoding = "UTF-8")
continentes <- c("Todos", sort(unique(paises$continente)))

# prompt ------------------------------------------------------------------
saludo <- paste(
  "Prueba con:",
  "- **¿Cuántos países se muestran?**",
  "- **¿Cuál es su esperanza de vida promedio?**",
  sep = "\n\n"
)

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 03 · Tool con contexto",
  sidebar = sidebar(
    selectInput("continente", "Continente", choices = continentes),
    shinychat::chat_ui("chat", messages = saludo, placeholder = "Pregunta sobre los datos visibles..."),
    width = 400
  ),
  layout_columns(
    value_box("Países", textOutput("n_filas"), showcase = icon("earth-americas"), theme = "text-primary"),
    value_box("Esperanza de vida", textOutput("vida"), showcase = icon("heart-pulse"), theme="text-primary"),
    value_box("Población", textOutput("poblacion"), showcase = icon("people-group"), theme = "text-primary"),
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(4, 4, 4, 6, 6),
    row_heights = c(1, 3)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  data <- reactive({
    if (input$continente == "Todos") paises
    else paises[paises$continente == input$continente, ]
  })

  output$n_filas   <- renderText(nrow(data()))
  output$vida      <- renderText(paste0(round(mean(data()$esperanza_de_vida), 1), " años"))
  output$poblacion <- renderText(paste0(round(sum(data()$poblacion) / 1e6), " millones"))

  output$plot <- renderPlot({
    tinyplot(esperanza_de_vida ~ pib_per_capita, data = paises, pch = 19, col = "#d2d2d2", log = "x")
    tinyplot_add(data = data(), col = "#0E4F5A", cex = 1.5)
  })

  output$table <- renderTable(data(), striped = TRUE, hover = TRUE)

  # tool ------------------------------------------------------------------
  resumir_datos_visibles <- function() {
    df <- isolate(data())
    list(
      continente = isolate(input$continente),
      registros = nrow(df),
      poblacion_total = sum(df$poblacion),
      esperanza_promedio = round(mean(df$esperanza_de_vida), 1),
      pib_promedio = round(mean(df$pib_per_capita))
    )
  }

  # chat ------------------------------------------------------------------
  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = paste(
      "Responde brevemente en español.",
      "Usa resumir_datos_visibles para responder sobre el dashboard y no inventes resultados."
    )
  )

  chat$register_tool(tool(
    resumir_datos_visibles,
    "Resume los países que están visibles en el dashboard."
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
