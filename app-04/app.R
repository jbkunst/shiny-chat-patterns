# packages ---------------------------------------------------------------
library(shiny)
library(bslib)
library(ellmer)
library(shinychat) # pak::pak("posit-dev/shinychat/pkg-r")
library(duckdb)
library(datos)     # pak::pak("cienciadedatos/datos")
library(tidyverse)
library(reactable)

# setup ------------------------------------------------------------------
db_path       <- tempfile(fileext = ".duckdb")
db_table_name <- "pinguinos"

if (file.exists(db_path)) unlink(db_path)

conn <- dbConnect(duckdb(), dbdir = db_path, read_only = FALSE)
DBI::dbWriteTable(conn, "pinguinos", pinguinos, overwrite = TRUE)
dbDisconnect(conn)

system_prompt_template <- paste(
  "Eres el asistente breve de un dashboard. Trabajas únicamente con DuckDB y esta tabla:",
  "",
  "${SCHEMA}",
  "",
  "## Herramientas",
  "",
  "- Usa `update_dashboard(query, title)` para filtrar, ordenar o reiniciar el dashboard.",
  "- Usa `query(query)` para responder preguntas sobre los datos.",
  "",
  "## Reglas",
  "",
  "- Genera solamente consultas `SELECT` sobre la tabla disponible.",
  "- Realiza cálculos y agregaciones dentro de SQL.",
  "- Para reiniciar, llama `update_dashboard` con `query = \"\"`.",
  "- Si la solicitud es ambigua, pide una aclaración.",
  "- Mantén las respuestas cortas y en español.",
  sep = "\n"
)

greeting_template <- paste(
  "Explora la tabla `${TABLE}` con el chat. Por ejemplo:",
  "",
  "- “Muestra solo los pingüinos Adelie”.",
  "- “Ordena por masa corporal”.",
  "- “Compara la masa promedio entre especies”.",
  "",
  "También puedes escribir “reiniciar” para volver a todos los datos.",
  sep = "\n"
)

# helpers ----------------------------------------------------------------
system_prompt <- function(df, name, categorical_threshold = 10) {
  schema <- df_to_schema(df, name, categorical_threshold)

  # Replace the placeholder with the schema
  prompt_text <- str_replace(system_prompt_template, "\\$\\{SCHEMA\\}", schema)

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

card <- purrr::partial(bslib::card, full_screen = TRUE)

# variables --------------------------------------------------------------
conn <- dbConnect(duckdb(), dbdir = db_path, read_only = TRUE)
onStop(\() dbDisconnect(conn))

# gpt-4o does much better than gpt-4o-mini, especially at interpreting plots
openai_model <- Sys.getenv("OPENAI_MODEL", unset = "gpt-3.5-turbo")

greeting <- str_replace(greeting_template, "\\$\\{TABLE\\}", db_table_name)
# cat(greeting)

system_prompt_str <- system_prompt(
  dbGetQuery(conn, str_glue("SELECT * FROM {db_table_name};")),
  db_table_name
)
# cat(system_prompt_str)

# user interface ---------------------------------------------------------
ui <- bslib::page_sidebar(
  title = "App 04 - Dashboard de pingüinos",
  sidebar = sidebar(
    width = 400,
    shinychat::chat_mod_ui("chat", placeholder = "Ingresa un mensaje...")
  ),
  # tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
  includeCSS("www/styles.css"),
  textOutput("title_sql", container = h3),
  verbatimTextOutput("query_sql") |> tagAppendAttributes(style = "max-height: 100px; overflow: auto;"),

  bslib::layout_columns(
    col_widths = 4,
    fill = FALSE,
    value_box("Registros", value = textOutput("vb_nrows")),
    value_box("Especies", value = textOutput("vb_species")),
    value_box("Masa promedio", value = textOutput("vb_avg_mass"))
  ),

  bslib::layout_columns(
    col_widths = c(6, 6, 12),
    card(plotOutput("plot")),
    card(plotOutput("plot_species")),
    card(reactableOutput("table", height = "100%"))
  )
)

# server -----------------------------------------------------------------
server <- function(input, output, session) {
  
  # reactive values
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
  output$vb_species <- renderText(n_distinct(data()$especie))
  output$vb_avg_mass <- renderText(paste0(round(mean(data()$masa_corporal_g, na.rm = TRUE)), " g"))

  output$plot <- renderPlot({
    data <- data() # pinguinos

    ggplot(data = data, aes(x = largo_aleta_mm, y = masa_corporal_g)) +
      geom_point(aes(color = especie), size = 3, alpha = 0.8) +
      theme_minimal() +
      scale_color_manual(values = c("darkorange", "purple", "cyan4")) +
      labs(x = "Largo aleta (mm)", y = "Masa corporal (g)", color = "Especie") +
      theme(legend.position = "bottom")

  })

  output$plot_species <- renderPlot({
    data() |>
      count(especie) |>
      ggplot(aes(x = especie, y = n, fill = especie)) +
      geom_col(width = 0.7, show.legend = FALSE) +
      geom_text(aes(label = n), vjust = -0.4) +
      scale_fill_manual(values = c("darkorange", "purple", "cyan4")) +
      labs(x = NULL, y = "Cantidad", title = "Pingüinos por especie") +
      theme_minimal() +
      theme(plot.title = element_text(face = "bold"))
  })

  output$table <- renderReactable(reactable(data(), pagination = FALSE, compact = TRUE))

  # chat and tool definitions ---------------------------------------------
  update_dashboard <- function(query, title) {
    if (query != "") {
      dbGetQuery(conn, query)
    }

    current_query(query)
    current_title(title)
    TRUE
  }

  query <- function(query) {
    dbGetQuery(conn, query) |>
      jsonlite::toJSON(auto_unbox = TRUE)
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

  shinychat::chat_mod_server("chat", client = chat, greeting = greeting)

}

# run application --------------------------------------------------------
shinyApp(ui, server)
