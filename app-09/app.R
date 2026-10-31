library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(mcptools)
library(tinyplot)

# prompt ------------------------------------------------------------------
saludo <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 09 · MCP + datos del FMI",
  sidebar = sidebar(
    shinychat::chat_ui("chat", messages = saludo, placeholder = "Consulta una serie del FMI..."),
    width = 400
  ),
  plotOutput("plot", height = "400px"),
  tableOutput("table"),
  fillable = FALSE
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  grafico_actual <- reactiveVal(NULL)

  output$plot <- renderPlot({
    grafico <- req(grafico_actual())
    tinyplot(
      valor ~ anio | pais, data = grafico$datos, type = "b", pch = 19,
      main = grafico$titulo, xlab = "Año", ylab = grafico$unidad
    )
  })
  output$table <- renderTable({ req(grafico_actual())$datos }, digits = 3, striped = TRUE, hover = TRUE)

  # tool ------------------------------------------------------------------
  graficar_serie <- function(anios, valores, paises, titulo, unidad) {
    datos <- data.frame(anio = anios, valor = valores, pais = paises)
    grafico_actual(list(datos = datos, titulo = titulo, unidad = unidad))
    datos
  }

  # chat ------------------------------------------------------------------
  chat <- chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)
  chat$set_tools(mcptools::mcp_tools("mcp.json"))
  chat$register_tool(tool(
    graficar_serie,
    "Grafica series anuales recuperadas del MCP y muestra sus datos en el dashboard.",
    arguments = list(
      anios = type_array(type_integer(), "Año de cada observación."),
      valores = type_array(type_number(), "Valores exactos devueltos por el MCP, en el mismo orden."),
      paises = type_array(type_string(), "País de cada observación, en el mismo orden."),
      titulo = type_string("Título con el indicador y la fuente consultada."),
      unidad = type_string("Unidad indicada por la fuente, por ejemplo porcentaje.")
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
