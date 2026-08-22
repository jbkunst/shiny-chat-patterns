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

validate_dashboard_query <- function(query) {
  query <- trimws(query)

  if (!grepl("^SELECT\\s+\\*\\s+FROM\\s+pinguinos\\b", query, ignore.case = TRUE)) {
    stop("Usa SELECT * FROM pinguinos, con WHERE u ORDER BY opcionales.")
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
  title = "App 05 · Tool + reactividad",
  sidebar = sidebar(
    width = 420,
    shinychat::chat_ui(
      "chat",
      messages = greeting,
      placeholder = "Filtra u ordena el dashboard..."
    )
  ),
  h3(textOutput("title", inline = TRUE)),
  verbatimTextOutput("query"),
  layout_columns(
    value_box("Registros", textOutput("n_rows")),
    value_box("Especies", textOutput("n_species")),
    value_box("Masa promedio", textOutput("avg_mass")),
    col_widths = 4
  ),
  layout_columns(
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(6, 6)
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {
  current_title <- reactiveVal("Todos los pingüinos")
  current_query <- reactiveVal("SELECT * FROM pinguinos")

  data <- reactive(DBI::dbGetQuery(con, current_query()))

  output$title <- renderText(current_title())
  output$query <- renderText(current_query())
  output$n_rows <- renderText(nrow(data()))
  output$n_species <- renderText(length(unique(data()$especie)))
  output$avg_mass <- renderText(paste0(round(mean(data()$masa_corporal_g, na.rm = TRUE)), " g"))

  output$plot <- renderPlot({
    df <- data()

    plot(
      df$largo_aleta_mm,
      df$masa_corporal_g,
      pch = 19,
      xlab = "Largo de aleta (mm)",
      ylab = "Masa corporal (g)"
    )
  })

  output$table <- renderTable(head(data(), 20), striped = TRUE, hover = TRUE)

  # tool ------------------------------------------------------------------

  update_dashboard <- function(query, title) {
    query <- validate_dashboard_query(query)
    result <- DBI::dbGetQuery(con, query)

    current_query(query)
    current_title(title)

    list(message = "Dashboard actualizado.", records = nrow(result))
  }

  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = system_prompt)

  chat$register_tool(tool(
    update_dashboard,
    "Filtra, ordena o reinicia los datos reactivos mostrados en el dashboard.",
    arguments = list(
      query = type_string("SELECT * FROM pinguinos con WHERE u ORDER BY opcionales, sin punto y coma."),
      title = type_string("Título breve que describe los datos mostrados.")
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
