library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(DBI)
library(duckdb)

# database ----------------------------------------------------------------
db_path <- "nycflights.duckdb"

if (!file.exists(db_path)) {
  con <- dbConnect(duckdb(), dbdir = db_path)
  dbWriteTable(con, "flights", nycflights13::flights)
  dbWriteTable(con, "airlines", nycflights13::airlines)
  dbWriteTable(con, "airports", nycflights13::airports)
  dbWriteTable(con, "planes", nycflights13::planes)
  dbWriteTable(con, "weather", nycflights13::weather)
  dbDisconnect(con, shutdown = TRUE)
}

con <- dbConnect(duckdb(), dbdir = db_path, read_only = TRUE)
schema <- paste(
  vapply(dbListTables(con), function(table) {
    paste0(table, "(", paste(dbListFields(con, table), collapse = ", "), ")")
  }, character(1)),
  collapse = "\n"
)
dbDisconnect(con, shutdown = TRUE)

validate_sql <- function(sql) {
  sql <- trimws(sql)

  if (!grepl("^(SELECT|WITH)\\b", sql, ignore.case = TRUE)) {
    stop("Solo se permiten consultas SELECT o WITH.")
  }

  if (grepl(";", sql, fixed = TRUE)) {
    stop("Envía una sola consulta y no incluyas punto y coma.")
  }

  sql
}

execute_sql <- function(sql) {
  con <- dbConnect(duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
  dbGetQuery(con, validate_sql(sql))
}

extract_sql <- function(analysis) {
  sql <- sub("(?s).*SQL:\\s*", "", analysis, perl = TRUE)
  trimws(gsub("```sql|```", "", sql, ignore.case = TRUE))
}

# prompts -----------------------------------------------------------------
greeting <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
analyst_prompt <- paste(
  paste(readLines("analyst-prompt.md", warn = FALSE), collapse = "\n"),
  "Tablas y columnas disponibles:",
  schema,
  sep = "\n"
)
writer_prompt <- paste(readLines("writer-prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 11 · Orquestación de agentes",
  sidebar = sidebar(
    width = 420,
    shinychat::chat_ui(
      "chat",
      messages = greeting,
      placeholder = "Ej: ¿Qué aerolínea tuvo más vuelos?"
    )
  ),
  h4("Flujo explícito"),
  p("Pregunta → orchestrate() → analyst_agent → DuckDB → writer_agent"),
  layout_columns(
    card(card_header("1. analyst_agent"), verbatimTextOutput("analysis")),
    card(card_header("2. DuckDB"), tableOutput("data")),
    col_widths = c(6, 6)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  # Agents are created once per Shiny session.
  analyst_agent <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = analyst_prompt
  )
  writer_agent <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = writer_prompt
  )

  last_analysis <- reactiveVal("Aún no hay análisis.")
  last_data <- reactiveVal(NULL)

  output$analysis <- renderText(last_analysis())
  output$data <- renderTable(last_data(), striped = TRUE)

  # orchestrator ----------------------------------------------------------
  orchestrate <- function(question) {
    analysis <- analyst_agent$chat(question, echo = "none")
    data <- execute_sql(extract_sql(analysis))
    data_text <- paste(capture.output(print(data, row.names = FALSE)), collapse = "\n")

    answer <- writer_agent$chat(paste0(
      "PREGUNTA:\n", question,
      "\n\nANÁLISIS:\n", analysis,
      "\n\nRESULTADO DUCKDB:\n", data_text
    ), echo = "none")

    list(analysis = analysis, data = data, answer = answer)
  }

  observeEvent(input$chat_user_input, {
    question <- trimws(input$chat_user_input)
    req(nzchar(question))

    tryCatch({
      result <- orchestrate(question)
      last_analysis(result$analysis)
      last_data(result$data)
      shinychat::chat_append("chat", result$answer)
    }, error = function(error) {
      shinychat::chat_append("chat", paste("Error:", conditionMessage(error)))
    })
  })
}

shinyApp(ui, server)
