library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(dplyr)
library(stringr)

# data --------------------------------------------------------------------
catalogo <- readRDS("../data/series_catalog.rds")

saludo         <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 12 · Chat orientador",
  fillable = TRUE,
  sidebar = sidebar(
    shinychat::chat_ui("chat", messages = saludo, placeholder = "Busca una serie..."),
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
  serie_actual   <- reactiveVal(NULL)
  datos_actuales <- reactiveVal(NULL)

  buscar_series <- function(texto) {
    terminos <- texto |> iconv(to = "ASCII//TRANSLIT") |> str_to_lower() |> str_split("\\s+") |> unlist()
    catalogo |>
      mutate(texto_busqueda = str_c(series_id, spanish_title, english_title, sep = " ") |>
        iconv(to = "ASCII//TRANSLIT") |> str_to_lower()) |>
      filter(sapply(texto_busqueda, \(x) all(str_detect(x, fixed(terminos))))) |>
      arrange(desc(last_observation)) |>
      select(series_id, spanish_title, frequency) |>
      slice_head(n = 10)
  }

  actualizar_dashboard <- function(codigo, desde = NULL, hasta = NULL) {
    info <- catalogo |> filter(series_id == codigo) |> slice_head(n = 1)
    if (!nrow(info)) stop("Código no encontrado.")

    datos <- bcchr::get_series(codigo, desde, hasta, token = Sys.getenv("BCCH_TOKEN"))
    serie_actual(info)
    datos_actuales(datos)

    "Dashboard actualizado."
  }

  output$titulo <- renderText({
    if (is.null(serie_actual())) "Busca y consulta una serie" else serie_actual()$spanish_title
  })

  output$plot <- renderPlot({
    req(datos_actuales())
    bcchr::plot_series(datos_actuales())
  })

  output$table <- renderTable({
    req(datos_actuales())
    transform(datos_actuales(), date = format(date, "%Y-%m-%d"))
  }, striped = TRUE, hover = TRUE)

  # tools -----------------------------------------------------------------
  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)

  chat$register_tool(tool(
    buscar_series,
    "Busca series por título en el catálogo local.",
    arguments = list(texto = type_string("Palabras presentes en el título de la serie."))
  ))

  chat$register_tool(tool(
    actualizar_dashboard,
    "Descarga una serie y envía sus datos al título, gráfico y tabla.",
    arguments = list(
      codigo = type_string("Código exacto obtenido con buscar_series."),
      desde = type_string("Fecha inicial YYYY-MM-DD.", required = FALSE),
      hasta = type_string("Fecha final YYYY-MM-DD.", required = FALSE)
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
