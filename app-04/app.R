library(shiny)
library(bslib)
library(datos)
library(DBI)
library(duckdb)
library(ellmer)
library(shinychat)

# database ----------------------------------------------------------------

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
DBI::dbWriteTable(con, "pinguinos", datos::pinguinos)
DBI::dbExecute(con, "SET enable_external_access = false")
onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))

validate_select <- function(query) {
  query <- trimws(query)

  if (!grepl("^SELECT\\b", query, ignore.case = TRUE)) {
    stop("Solo se permiten consultas SELECT.")
  }

  if (!grepl("\\bpinguinos\\b", query, ignore.case = TRUE)) {
    stop("La consulta debe usar la tabla pinguinos.")
  }

  if (grepl(";", query, fixed = TRUE)) {
    stop("Envía una sola consulta y no incluyas punto y coma.")
  }

  query
}

# prompt ------------------------------------------------------------------

greeting <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
system_prompt <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------

ui <- page_sidebar(
  title = "App 04 · Tool SQL",
  sidebar = sidebar(
    width = 420,
    shinychat::chat_ui(
      "chat",
      messages = greeting,
      placeholder = "Pregunta por los datos..."
    )
  ),
  card(
    card_header("Base de datos"),
    p("DuckDB en memoria con una tabla llamada ", code("pinguinos"), "."),
    tags$ul(
      tags$li(code("especie"), ", ", code("isla"), ", ", code("sexo"), ", ", code("anio")),
      tags$li(code("largo_pico_mm"), ", ", code("alto_pico_mm")),
      tags$li(code("largo_aleta_mm"), ", ", code("masa_corporal_g"))
    )
  ),
  card(
    card_header("Idea de esta etapa"),
    p(
      "La tool ejecuta una consulta y devuelve su resultado al modelo. ",
      "Todavía no modifica ningún reactive ni output de Shiny."
    )
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {
  query_penguins <- function(query) {
    DBI::dbGetQuery(con, validate_select(query))
  }

  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = system_prompt)

  chat$register_tool(tool(
    query_penguins,
    "Ejecuta una consulta SELECT de solo lectura sobre la tabla DuckDB pinguinos.",
    arguments = list(
      query = type_string("Una consulta DuckDB SELECT que use la tabla pinguinos, sin punto y coma.")
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
