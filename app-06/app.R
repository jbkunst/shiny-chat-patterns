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
  title = "App 06 · Tools de interfaz",
  sidebar = sidebar(
    width = 420,
    shinychat::chat_ui(
      "chat",
      messages = greeting,
      placeholder = "Filtra, muestra una tabla o crea un gráfico..."
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

  data <- reactive({
    DBI::dbGetQuery(con, current_query())
  })

  output$title <- renderText(current_title())
  output$query <- renderText(current_query())
  output$n_rows <- renderText(nrow(data()))
  output$n_species <- renderText(length(unique(data()$especie)))

  output$avg_mass <- renderText({
    paste0(round(mean(data()$masa_corporal_g, na.rm = TRUE)), " g")
  })

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

  # tools -----------------------------------------------------------------

  update_dashboard <- function(query, title) {
    query <- validate_dashboard_query(query)
    result <- DBI::dbGetQuery(con, query)

    current_query(query)
    current_title(title)

    list(message = "Dashboard actualizado.", records = nrow(result))
  }

  show_table <- function(n, title) {
    n <- max(1L, min(as.integer(n), 100L))
    df <- DBI::dbGetQuery(con, isolate(current_query()))

    output$modal_table <- renderTable(
      head(df, n),
      striped = TRUE,
      hover = TRUE
    )

    showModal(modalDialog(
      title = title,
      tableOutput("modal_table"),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Cerrar")
    ), session = session)

    paste("Tabla abierta con", min(n, nrow(df)), "registros.")
  }

  show_chart <- function(x, y, color, title) {
    df <- DBI::dbGetQuery(con, isolate(current_query()))
    requested_columns <- c(x, y, color)
    requested_columns <- requested_columns[nzchar(requested_columns)]

    if (!all(requested_columns %in% names(df))) {
      stop("Una o más columnas no existen en los datos actuales.")
    }

    output$modal_chart <- renderPlot({
      if (nzchar(color)) {
        groups <- as.factor(df[[color]])
        palette <- grDevices::hcl.colors(nlevels(groups), "Dark 3")

        plot(
          df[[x]],
          df[[y]],
          col = palette[groups],
          pch = 19,
          xlab = x,
          ylab = y
        )

        legend(
          "topleft",
          legend = levels(groups),
          col = palette,
          pch = 19,
          bty = "n"
        )
      } else {
        plot(df[[x]], df[[y]], pch = 19, xlab = x, ylab = y)
      }
    })

    showModal(modalDialog(
      title = title,
      plotOutput("modal_chart", height = "500px"),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Cerrar")
    ), session = session)

    "Gráfico abierto en un modal."
  }

  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = system_prompt
  )

  chat$register_tools(list(
    tool(
      update_dashboard,
      "Filtra, ordena o reinicia los datos reactivos mostrados en el dashboard.",
      arguments = list(
        query = type_string("SELECT * FROM pinguinos con WHERE u ORDER BY opcionales, sin punto y coma."),
        title = type_string("Título breve que describe los datos mostrados.")
      )
    ),
    tool(
      show_table,
      "Abre en un modal una tabla con los datos que actualmente alimentan el dashboard.",
      arguments = list(
        n = type_integer("Cantidad de filas, entre 1 y 100."),
        title = type_string("Título breve del modal.")
      )
    ),
    tool(
      show_chart,
      "Abre en un modal un gráfico de puntos con los datos actuales del dashboard.",
      arguments = list(
        x = type_string("Columna para el eje x."),
        y = type_string("Columna para el eje y."),
        color = type_string("Columna categórica para el color, o una cadena vacía para no agrupar."),
        title = type_string("Título breve del modal.")
      )
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(
      input$chat_user_input,
      tool_mode = "sequential"
    )
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
