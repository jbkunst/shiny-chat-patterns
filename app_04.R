# packages ---------------------------------------------------------------
library(shiny)
library(bslib)
library(here)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat")
library(duckdb)
library(here)
library(datos)     # pak::pak("cienciadedatos/datos")
library(tidyverse)
library(reactable)

# setup ------------------------------------------------------------------
db_path       <- here("db/database.duckdb")
db_table_name <- "pinguinos"

if (file.exists(db_path)) unlink(db_path)

conn <- dbConnect(duckdb(), dbdir = db_path, read_only = FALSE)
DBI::dbWriteTable(conn, "pinguinos", pinguinos, overwrite = TRUE)
dbDisconnect(conn)

# helpers ----------------------------------------------------------------
system_prompt <- function(df, name, categorical_threshold = 10) {
  schema <- df_to_schema(df, name, categorical_threshold)

  # Read the prompt file
  prompt_path <- here("md/app_04_prompt.md")
  prompt_content <- read_lines(prompt_path)
  prompt_text <- str_c(prompt_content, collapse = "\n")

  # Replace the placeholder with the schema
  prompt_text <- str_replace(prompt_text, "\\$\\{SCHEMA\\}", schema)

  prompt_text
}

df_to_schema <- function(df, name, categorical_threshold) {
  schema <- c(paste("Table:", name), "Columns:")

  column_info <- lapply(names(df), function(column) {
    # Map R classes to SQL-like types
    sql_type <- if (is.integer(df[[column]])) {
      "INTEGER"
    } else if (is.numeric(df[[column]])) {
      "FLOAT"
    } else if (is.logical(df[[column]])) {
      "BOOLEAN"
    } else if (inherits(df[[column]], "POSIXt")) {
      "DATETIME"
    } else {
      "TEXT"
    }

    info <- paste0("- ", column, " (", sql_type, ")")

    # For TEXT columns, check if they're categorical
    if (sql_type == "TEXT") {
      unique_values <- length(unique(df[[column]]))
      if (unique_values <= categorical_threshold) {
        categories <- unique(df[[column]])
        categories_str <- paste0("'", categories, "'", collapse = ", ")
        info <- c(info, paste0("  Categorical values: ", categories_str))
      }
    }

    return(info)
  })

  schema <- c(schema, unlist(column_info))
  return(paste(schema, collapse = "\n"))
}

df_to_html <- function(df, maxrows = 5) {
  df_short <- if (nrow(df) > 10) head(df, maxrows) else df

  tbl_html <- capture.output(
    df_short |>
      xtable::xtable() |>
      print(type = "html", include.rownames = FALSE, html.table.attributes = NULL)
  ) |> paste(collapse = "\n")

  if (nrow(df_short) != nrow(df)) {
    rows_notice <- glue::glue("\n\n(Showing only the first {maxrows} rows out of {nrow(df)}.)\n")
  } else {
    rows_notice <- ""
  }

  paste0(tbl_html, "\n", rows_notice)
}

# variables --------------------------------------------------------------
conn <- dbConnect(duckdb(), dbdir = db_path, read_only = TRUE)
onStop(\() dbDisconnect(conn))

# gpt-4o does much better than gpt-4o-mini, especially at interpreting plots
openai_model <- "gpt-3.5-turbo" # "gpt-4o"

greeting <- str_c(read_lines(here("md/app_04_greetings.md")), collapse = "\n")
greeting <- str_replace(greeting, "\\$\\{TABLE\\}", db_table_name)
# cat(greeting)

system_prompt_str <- system_prompt(
  dbGetQuery(conn, str_glue("SELECT * FROM {db_table_name};")),
  db_table_name
)
# cat(system_prompt_str)

# user interface ---------------------------------------------------------
ui <- bslib::page_navbar(
  sidebar = sidebar(
    width = 400,
    shinychat::chat_ui("chat", placeholder = "Ingresa un mensaje...")
  ),
  nav_panel(
    title = "Dashboard",
    # tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
    includeCSS("www/styles.css"),
    textOutput("title_sql", container = h3),
    verbatimTextOutput("query_sql") |> tagAppendAttributes(style = "max-height: 100px; overflow: auto;"),

    bslib::layout_columns(
      widths = 4,
      fill = FALSE,
      value_box("Registros", value = textOutput("vb_nrows")),
      value_box("Datos", value = NULL),
      value_box("Datos", value = NULL)
    ),

    bslib::layout_columns(
      widths = c(12),
      card(       
        card_header("Data"),
        reactableOutput("table", height = "100%")
      )
    )
  )
)

# server -----------------------------------------------------------------
server <- function(input, output, session) {
  
  # variables reactivas
  current_title <- reactiveVal(NULL)
  current_query <- reactiveVal(NULL)

  output$title_sql <- renderText(current_title())
  output$query_sql <- renderText(current_query())

  data <- reactive({
    sql <- current_query()
    if (is.null(sql) || sql == "") {
      sql <- str_glue("SELECT * FROM {db_table_name};")
    }
    dbGetQuery(conn, sql)
  })

  output$vb_nrows <- renderText(nrow(data()))
  output$table <- renderReactable(reactable(data(), pagination = FALSE, compact = TRUE))

  # definición chat y tools ------------------------------------------------
  append_output <- function(...) {

    cli::cli_inform("running `append_output`")

    txt <- paste0(...)
    shinychat::chat_append_message(
      "chat",
      list(role = "assistant", content = txt),
      chunk = TRUE,
      operation = "append",
      session = session
    )
  }

  update_dashboard <- function(query, title) {

    cli::cli_inform("running `update_dashboard`:\n\tquery: {query}\n\ttitle: {title}")

    if(query == "") {
      current_query(query)
      current_title(title)
      return(TRUE)
    }

    append_output("\n```sql\n", query, "\n```\n\n")
    
    tryCatch(
      {
        # Try it to see if it errors; if so, the LLM will see the error
        dbGetQuery(conn, query)
      },
      error = function(err) {
        append_output("> Error: ", conditionMessage(err), "\n\n")
        stop(err)
      }
    )

    if (!is.null(query)) {
      current_query(query)
    }
    
    if (!is.null(title)) {
      current_title(title)
    }
    
  }

  query <- function(query) {

    cli::cli_inform("running `query`")

    # Do this before query, in case it errors
    append_output("\n```sql\n", query, "\n```\n\n")

    tryCatch(
      {
        df <- dbGetQuery(conn, query)
      },
      error = function(e) {
        append_output("> Error: ", conditionMessage(e), "\n\n")
        stop(e)
      }
    )

    tbl_html <- df_to_html(df, maxrows = 5)
    append_output(tbl_html, "\n\n")

    jsonlite::toJSON(df, auto_unbox = TRUE)
  }

  chat <- ellmer::chat_openai(model = openai_model, system_prompt = system_prompt_str)

  chat$register_tool(tool(
    update_dashboard,
    "Modifica los datos presentados en el panel de control basándose en la consulta SQL proporcionada y también actualiza el título.",
    query = type_string("Una consulta SQL de DuckDB; debe ser una instrucción SELECT."),
    title = type_string("Un título para mostrar en la parte superior del panel de control, que resuma la intención de la consulta SQL.")
  ))

  chat$register_tool(tool(
    query,
    "Realiza una consulta SQL sobre los datos y devuelve los resultados en formato JSON.",
    query = type_string("Una consulta SQL de DuckDB; debe ser una instrucción SELECT.")
  ))
  
  shinychat::chat_append("chat", greeting)
  
  shiny::observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })

}

# run application --------------------------------------------------------
shinyApp(ui, server)
