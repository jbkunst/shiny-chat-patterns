library(shiny)
library(bslib)
library(DBI)
library(duckdb)
library(ellmer)
library(shinychat)
library(tinyplot)

# database ----------------------------------------------------------------
paises <- utils::read.csv(file.path("..", "data", "paises.csv"), fileEncoding = "UTF-8")

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
DBI::dbWriteTable(con, "paises", paises)
DBI::dbExecute(con, "SET enable_external_access = false")
onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))

validar_select <- function(consulta) {
  consulta <- trimws(consulta)
  if (!grepl("^SELECT\\b", consulta, ignore.case = TRUE)) stop("Solo se permiten consultas SELECT.")
  if (!grepl("\\bpaises\\b", consulta, ignore.case = TRUE)) stop("La consulta debe usar paises.")
  if (grepl(";", consulta, fixed = TRUE)) stop("Envía una sola consulta y no incluyas punto y coma.")
  consulta
}

# prompt ------------------------------------------------------------------
saludo <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = tagList(
    "App 06 · Tools de interfaz",
    tags$small(" · ", textOutput("titulo", inline = TRUE))
  ),
  sidebar = sidebar(
    shinychat::chat_ui(
      "chat",
      messages = saludo,
      placeholder = "Filtra, muestra datos o crea un gráfico..."
    ),
    width = 400
  ),
  layout_columns(
    value_box("Países", textOutput("n_filas"), showcase = icon("earth-americas"), theme = "text-primary"),
    value_box("Esperanza de vida", textOutput("vida"), showcase = icon("heart-pulse"), theme="text-primary"),
    value_box("Población", textOutput("poblacion"), showcase = icon("people-group"), theme = "text-primary"),
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(4, 4, 4, 6, 6),
    row_heights = c(1, 3)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  titulo_actual <- reactiveVal("Todos los países")
  consulta_actual <- reactiveVal("SELECT * FROM paises")

  data <- reactive(DBI::dbGetQuery(con, consulta_actual()))

  output$titulo    <- renderText(titulo_actual())
  output$n_filas   <- renderText(nrow(data()))
  output$vida      <- renderText(paste0(round(mean(data()$esperanza_de_vida), 1), " años"))
  output$poblacion <- renderText(paste0(round(sum(data()$poblacion) / 1e6), " millones"))

  output$plot <- renderPlot({
    tinyplot(esperanza_de_vida ~ pib_per_capita, data = paises, pch = 19, col = "#d2d2d2", log = "x")
    tinyplot_add(data = data(), col = "#0E4F5A", cex = 1.5)
  })

  output$table <- renderTable(data(), striped = TRUE, hover = TRUE)

  # tools -----------------------------------------------------------------
  consultar_paises <- function(consulta) {
    DBI::dbGetQuery(con, validar_select(consulta))
  }

  actualizar_dashboard <- function(consulta, titulo) {
    consulta <- validar_select(consulta)
    resultado <- DBI::dbGetQuery(con, consulta)
    if (!all(names(paises) %in% names(resultado))) stop("La consulta debe devolver todas las columnas.")

    consulta_actual(consulta)
    titulo_actual(titulo)

    list(mensaje = "Dashboard actualizado.", registros = nrow(resultado))
  }

  mostrar_tabla <- function(n, titulo) {
    n <- max(1L, min(as.integer(n), 100L))
    df <- isolate(data())
    resultado <- head(df, n)
    output$tabla_modal <- renderTable(resultado, striped = TRUE, hover = TRUE)

    showModal(modalDialog(
      title = titulo, tableOutput("tabla_modal"), size = "l", easyClose = TRUE,
      footer = modalButton("Cerrar")
    ))

    resultado
  }

  mostrar_grafico <- function(x, y, color, titulo) {
    df <- isolate(data())
    columnas <- c(x, y, color)
    columnas <- columnas[nzchar(columnas)]
    if (!all(columnas %in% names(df))) stop("Una o más columnas no existen.")
    if (!nrow(df)) stop("No hay datos para graficar.")
    formula <- as.formula(paste(y, "~", x, if (nzchar(color)) paste("|", color) else ""))

    dibujar <- function() {
      if (nzchar(color)) tinyplot(formula, data = df, pch = 19, palette = "Blues 3")
      else tinyplot(formula, data = df, pch = 19, col = "#0E4F5A")
    }

    output$grafico_modal <- renderPlot(dibujar())

    showModal(modalDialog(
      title = titulo, plotOutput("grafico_modal", height = "500px"), size = "l", easyClose = TRUE,
      footer = modalButton("Cerrar")
    ))

    archivo <- tempfile(fileext = ".png")
    grDevices::png(archivo, width = 768, height = 500)
    tryCatch(dibujar(), finally = grDevices::dev.off())
    on.exit(unlink(archivo))
    content_image_file(archivo, resize = "none")
  }

  # chat ------------------------------------------------------------------
  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)

  chat$register_tool(tool(
    consultar_paises,
    "Ejecuta una consulta SELECT de solo lectura sobre la tabla DuckDB paises.",
    arguments = list(
      consulta = type_string("Consulta DuckDB SELECT sobre la tabla paises, sin punto y coma.")
    )
  ))

  chat$register_tool(tool(
    actualizar_dashboard,
    "Filtra, ordena o reinicia los datos reactivos mostrados en el dashboard.",
    arguments = list(
      consulta = type_string("SELECT * FROM paises con WHERE u ORDER BY, sin punto y coma."),
      titulo = type_string("Título breve que describe los datos mostrados.")
    )
  ))

  chat$register_tool(tool(
    mostrar_tabla,
    "Abre en un modal una tabla con los datos visibles en el dashboard.",
    arguments = list(
      n = type_integer("Cantidad de filas, entre 1 y 100."),
      titulo = type_string("Título breve del modal.")
    )
  ))

  chat$register_tool(tool(
    mostrar_grafico,
    "Abre en un modal un gráfico de puntos con los datos visibles en el dashboard.",
    arguments = list(
      x = type_enum(c("poblacion", "esperanza_de_vida", "pib_per_capita"), "Columna para el eje x."),
      y = type_enum(c("poblacion", "esperanza_de_vida", "pib_per_capita"), "Columna para el eje y."),
      color = type_enum(c("", "continente"), "Columna para el color, o ninguna."),
      titulo = type_string("Título breve del modal.")
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
