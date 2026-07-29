library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(DBI)
library(RSQLite)

# database ----------------------------------------------------------------

db_path <- "nycflights.sqlite"

if (!file.exists(db_path)) {
  con <- dbConnect(SQLite(), db_path)

  dbWriteTable(con, "flights", nycflights13::flights)
  dbWriteTable(con, "airlines", nycflights13::airlines)
  dbWriteTable(con, "airports", nycflights13::airports)
  dbWriteTable(con, "planes", nycflights13::planes)
  dbWriteTable(con, "weather", nycflights13::weather)

  dbDisconnect(con)
}

con <- dbConnect(SQLite(), db_path)

schema <- paste(
  vapply(dbListTables(con), function(table) {
    paste0(table, "(", paste(dbListFields(con, table), collapse = ", "), ")")
  }, character(1)),
  collapse = "\n"
)

dbDisconnect(con)

execute_sql <- function(sql) {
  if (!grepl("^\\s*(SELECT|WITH)\\b", sql, ignore.case = TRUE)) stop("Only SELECT or WITH queries are allowed.")

  con <- dbConnect(SQLite(), db_path)
  on.exit(dbDisconnect(con), add = TRUE)

  dbGetQuery(con, sql)
}

extract_sql <- function(analysis) {
  sql <- sub("(?s).*SQL:\\s*", "", analysis, perl = TRUE)
  trimws(gsub("```sql|```", "", sql, ignore.case = TRUE))
}

# prompts -----------------------------------------------------------------

analyst_prompt <- paste(
  "You are analyst_agent.",
  "The user asks questions about the nycflights13 SQLite database.",
  "Available tables and columns are:",
  schema,
  "Return exactly two sections: PLAN: and SQL:.",
  "PLAN must be one or two short sentences.",
  "SQL must contain one valid SQLite SELECT or WITH query.",
  "Use joins when needed and keep results to at most 20 rows.",
  "Do not invent query results.",
  sep = "\n"
)

writer_prompt <- paste(
  "You are writer_agent.",
  "Answer the user's question clearly and briefly.",
  "Use only the supplied SQLite result as evidence.",
  "Do not invent values that are not present in the result."
)

# user interface ----------------------------------------------------------

ui <- page_sidebar(
  title = "App 07 · Two agents + SQLite",

  sidebar = sidebar(
    width = 420,
    shinychat::chat_ui(
      "chat",
      placeholder = "Ej: ¿Qué aerolínea tuvo más vuelos?"
    )
  ),

  h4("Flujo lineal"),
  p("Pregunta → analyst_agent → SQLite → writer_agent"),

  layout_columns(
    card(
      card_header("1. analyst_agent"),
      verbatimTextOutput("analysis")
    ),
    card(
      card_header("2. SQLite result"),
      tableOutput("data")
    ),
    col_widths = c(6, 6)
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {

  # agents are created once per Shiny session -----------------------------

  analyst_agent <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = analyst_prompt
  )

  writer_agent <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = writer_prompt
  )

  # state -----------------------------------------------------------------

  last_analysis <- reactiveVal("Aún no hay análisis.")
  last_data <- reactiveVal(NULL)

  output$analysis <- renderText(last_analysis())
  output$data <- renderTable(last_data(), striped = TRUE)

  # orchestrator ----------------------------------------------------------

  orchestrate <- function(question) {
    analysis <- analyst_agent$chat(question)
    sql <- extract_sql(analysis)
    data <- execute_sql(sql)

    data_text <- paste(
      capture.output(print(data, row.names = FALSE)),
      collapse = "\n"
    )

    answer <- writer_agent$chat(paste0(
      "USER QUESTION:\n", question,
      "\n\nANALYST OUTPUT:\n", analysis,
      "\n\nSQLITE RESULT:\n", data_text
    ))

    list(
      analysis = analysis,
      data = data,
      answer = answer
    )
  }

  # chat ------------------------------------------------------------------

  shinychat::chat_append(
    "chat",
    paste(
      "Este ejemplo usa dos agentes persistentes por sesión y una SQLite real.",
      "Pregunta por vuelos, aerolíneas, aeropuertos, aviones o clima."
    )
  )

  observeEvent(input$chat_user_input, {
    question <- trimws(input$chat_user_input)
    req(nzchar(question))

    tryCatch({
      result <- orchestrate(question)

      last_analysis(result$analysis)
      last_data(result$data)

      shinychat::chat_append("chat", result$answer)
    }, error = function(error) {
      shinychat::chat_append(
        "chat",
        paste("Error:", conditionMessage(error))
      )
    })
  })
}

shinyApp(ui, server)
