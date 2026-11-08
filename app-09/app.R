library(shiny)
library(bslib)
library(DBI)
library(duckdb)
library(ellmer)
library(shinychat)
library(tinyplot)
library(mcptools)
library(mapgl)
library(sf)

# database ----------------------------------------------------------------
paises <- utils::read.csv("data/paises.csv", fileEncoding = "UTF-8")
rangos_mapa <- list(
  desempleo = range(paises$desempleo),
  poblacion = range(log10(paises$poblacion)),
  pib_per_capita = range(log10(paises$pib_per_capita))
)

data("countries50", package = "rnaturalearthdata")
mapa_mundo <- sf::st_transform(sf::st_as_sf(countries50), 4326)
geometrias <- data.frame(
  codigo = mapa_mundo$adm0_a3,
  longitud = mapa_mundo$label_x,
  latitud = mapa_mundo$label_y,
  wkt = sf::st_as_text(sf::st_geometry(mapa_mundo))
)
paises_geo <- merge(paises, geometrias, by = "codigo")

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
DBI::dbWriteTable(con, "paises_carga", paises_geo)
DBI::dbExecute(con, paste(
  "CREATE TABLE paises_geo AS",
  "SELECT * EXCLUDE (wkt), wkt::GEOMETRY AS geometry FROM paises_carga"
))
DBI::dbExecute(con, paste(
  "CREATE VIEW paises AS SELECT pais, continente, desempleo,",
  "poblacion, pib_per_capita, codigo FROM paises_geo"
))
DBI::dbRemoveTable(con, "paises_carga")
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
  title = "App 09 · MCP + mapa del FMI (2007)",
  sidebar = sidebar(
    shinychat::chat_ui("chat", greeting = saludo, placeholder = "Consulta el FMI o controla el mapa..."),
    width = 400
  ),
  layout_columns(
    value_box("Países", textOutput("n_filas"), showcase = icon("earth-americas"), theme = "text-primary"),
    value_box("Desempleo", textOutput("desempleo"), showcase = icon("briefcase"), theme="text-primary"),
    value_box("Población", textOutput("poblacion"), showcase = icon("people-group"), theme = "text-primary"),
    card(plotOutput("plot")),
    card(mapgl::maplibreOutput("map", height = "500px")),
    col_widths = c(4, 4, 4, 6, 6),
    row_heights = c(1, 3)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  consulta_actual <- reactiveVal("SELECT * FROM paises")
  variable_mapa <- reactiveVal("desempleo")
  serie_actual <- reactiveVal(NULL)

  data <- reactive({
    consulta <- paste(
      "SELECT q.*, ST_AsText(g.geometry) AS wkt",
      paste0("FROM (", consulta_actual(), ") q"),
      "JOIN paises_geo g USING (codigo)"
    )
    DBI::dbGetQuery(con, consulta) |> sf::st_as_sf(wkt = "wkt", crs = 4326)
  })

  output$n_filas   <- renderText(nrow(data()))
  output$desempleo <- renderText(paste0(round(mean(data()$desempleo), 1), " %"))
  output$poblacion <- renderText(paste0(round(sum(data()$poblacion) / 1e6), " millones"))

  output$plot <- renderPlot({
    tinyplot(
      desempleo ~ pib_per_capita, data = paises, pch = 19, col = "#d2d2d2", log = "x",
      xlab = "PIB por habitante (USD corrientes)", ylab = "Desempleo (%)"
    )
    tinyplot_add(data = sf::st_drop_geometry(data()), col = "#0E4F5A", cex = 1.5)
  })

  output$map <- mapgl::renderMaplibre({
    df <- data()
    req(nrow(df))
    df$valor_mapa <- switch(variable_mapa(),
      poblacion = log10(df$poblacion),
      pib_per_capita = log10(df$pib_per_capita),
      df$desempleo
    )
    valores <- rangos_mapa[[variable_mapa()]]
    colores <- mapgl::interpolate("valor_mapa", values = valores, stops = c("#dcebea", "#0E4F5A"))

    mapgl::maplibre(style = mapgl::carto_style("positron"), bounds = df) |>
      mapgl::add_fill_layer(
        id = "paises", source = df, fill_color = colores, fill_opacity = 0.8,
        fill_outline_color = "white", tooltip = "pais"
      ) |>
      mapgl::add_globe_control()
  })

  output$serie <- renderPlot({
    serie <- req(serie_actual())
    tinyplot(
      valor ~ anio | pais, data = serie$datos, type = "b", pch = 19,
      main = serie$titulo, xlab = "Año", ylab = serie$unidad
    )
  })
  output$datos_serie <- renderTable({ req(serie_actual())$datos }, digits = 3, striped = TRUE, hover = TRUE)

  # tools -----------------------------------------------------------------
  consultar_paises <- function(consulta) {
    DBI::dbGetQuery(con, validar_select(consulta))
  }

  actualizar_dashboard <- function(consulta) {
    consulta <- validar_select(consulta)
    resultado <- DBI::dbGetQuery(con, consulta)

    consulta_actual(consulta)
    list(
      mensaje = "Dashboard y mapa actualizados.",
      registros = nrow(resultado),
      desempleo_promedio = round(mean(resultado$desempleo), 1),
      poblacion_total = sum(resultado$poblacion),
      pib_promedio = round(mean(resultado$pib_per_capita))
    )
  }

  cambiar_variable <- function(variable) {
    variable_mapa(variable)
    paste("Mapa coloreado por", variable)
  }

  ir_a_pais <- function(pais, zoom = 4) {
    ubicacion <- DBI::dbGetQuery(con, paste(
      "SELECT DISTINCT p.pais, g.longitud, g.latitud",
      "FROM paises p JOIN paises_geo g USING (codigo)",
      "WHERE lower(p.pais) = lower(?)"
    ), params = list(pais))
    if (!nrow(ubicacion)) stop("No encontré ese país.")

    mapgl::maplibre_proxy("map", session) |>
      mapgl::fly_to(center = c(ubicacion$longitud[1], ubicacion$latitud[1]), zoom = zoom)

    paste("Mapa centrado en", ubicacion$pais[1])
  }

  graficar_serie <- function(anios, valores, paises, titulo, unidad) {
    datos <- data.frame(anio = anios, valor = valores, pais = paises)
    datos <- datos[order(datos$pais, datos$anio), ]
    serie_actual(list(datos = datos, titulo = titulo, unidad = unidad))
    showModal(modalDialog(
      title = titulo, plotOutput("serie"), tableOutput("datos_serie"), size = "l", easyClose = TRUE
    ))
    datos
  }

  # chat ------------------------------------------------------------------
  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)
  chat$set_tools(mcptools::mcp_tools("mcp.json"))

  chat$register_tool(tool(
    consultar_paises,
    "Ejecuta una consulta SELECT de solo lectura sobre la tabla DuckDB paises.",
    arguments = list(
      consulta = type_string("Consulta DuckDB SELECT sobre la tabla paises, sin punto y coma.")
    )
  ))

  chat$register_tool(tool(
    actualizar_dashboard,
    "Filtra, ordena o reinicia los datos reactivos mostrados en el dashboard y el mapa.",
    arguments = list(
      consulta = type_string("SELECT * FROM paises con WHERE u ORDER BY, sin punto y coma.")
    )
  ))

  chat$register_tool(tool(
    cambiar_variable,
    "Cambia la variable utilizada para colorear los países del mapa.",
    arguments = list(
      variable = type_enum(
        c("desempleo", "poblacion", "pib_per_capita"),
        "Variable con la que se colorea el mapa."
      )
    )
  ))

  chat$register_tool(tool(
    ir_a_pais,
    "Vuela hacia un país en el mapa.",
    arguments = list(
      pais = type_string("Nombre del país en español."),
      zoom = type_number("Nivel de zoom, normalmente entre 2 y 6.", required = FALSE)
    )
  ))

  chat$register_tool(tool(
    graficar_serie,
    "Abre un modal con series anuales recuperadas del MCP, sin cambiar el dashboard de 2007.",
    arguments = list(
      anios = type_array(type_integer(), "Año de cada observación."),
      valores = type_array(type_number(), "Valores exactos devueltos por el MCP, en el mismo orden."),
      paises = type_array(type_string(), "País de cada observación, en el mismo orden."),
      titulo = type_string("Título con el indicador y la fuente consultada."),
      unidad = type_string("Unidad de los valores devueltos por el MCP.")
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
