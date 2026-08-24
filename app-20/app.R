library(shiny)
library(bslib)
library(ellmer)
library(shinychat)

# agents ------------------------------------------------------------------
analyst_agent <- function(question) {
  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = paste(
      "You are analyst_agent.",
      "The user asks questions about a toy table named sales with columns:",
      "date, region, product, units, revenue.",
      "Return a very short analysis plan followed by one SQLite SELECT query.",
      "Do not invent query results."
    )
  )

  chat$chat(question, echo = "none")
}

writer_agent <- function(question, analysis, data) {
  data_text <- paste(capture.output(print(data, row.names = FALSE)), collapse = "\n")

  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = paste(
      "You are writer_agent.",
      "Answer clearly and briefly using only the supplied query result.",
      "The data is simulated for a learning example, so say that explicitly."
    )
  )

  chat$chat(paste0(
    "USER QUESTION:\n", question,
    "\n\nANALYST OUTPUT:\n", analysis,
    "\n\nSIMULATED QUERY RESULT:\n", data_text
  ), echo = "none")
}

# fake database -----------------------------------------------------------
simulate_execution <- function(analysis) {
  # In a real app this is where DBI::dbGetQuery() would execute the SQL.
  # We intentionally ignore `analysis` and return fixed data for the example.
  data.frame(
    region = c("Norte", "Centro", "Sur"),
    units = c(420, 560, 310),
    revenue = c(125000, 186000, 98000)
  )
}

# orchestrator ------------------------------------------------------------
orchestrate <- function(question) {
  analysis <- analyst_agent(question)
  data <- simulate_execution(analysis)
  answer <- writer_agent(question, analysis, data)

  list(analysis = analysis, data = data, answer = answer)
}

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 20 · Two agents",
  sidebar = sidebar(
    width = 420,
    shinychat::chat_ui(
      "chat",
      messages = paste(
        "Este ejemplo usa dos agentes sin memoria compartida.",
        "Pregunta por ventas, regiones, productos, unidades o revenue."
      ),
      placeholder = "Ej: ¿Qué región vende más?"
    )
  ),
  h4("Flujo lineal"),
  p("Pregunta → analyst_agent → ejecución simulada → writer_agent"),
  layout_columns(
    card(card_header("1. analyst_agent"), verbatimTextOutput("analysis")),
    card(card_header("2. simulated execution"), tableOutput("data")),
    col_widths = c(6, 6)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  last_analysis <- reactiveVal("Aún no hay análisis.")
  last_data <- reactiveVal(NULL)

  output$analysis <- renderText(last_analysis())
  output$data <- renderTable(last_data(), striped = TRUE)

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
