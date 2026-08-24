library(shiny)
library(bslib)
library(DBI)
library(duckdb)
library(ellmer)
library(shinychat)
library(tinyplot)
library(mapgl)
library(sf)

# database ----------------------------------------------------------------
paises <- utils::read.csv(file.path("..", "data", "paises.csv"), fileEncoding = "UTF-8")
codigos <- countrycode::countrycode(levels(gapminder::gapminder$country), "country.name", "iso3c")
stopifnot(nrow(paises) == length(codigos))
paises$codigo <- unname(codigos)
rangos_mapa <- list(
  esperanza_de_vida = range(paises$esperanza_de_vida),
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
  "CREATE VIEW paises AS SELECT pais, continente, esperanza_de_vida,",
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
  title = tagList("App 08 · Tool + mapa", tags$small(" · ", textOutput("titulo", inline = TRUE))),
  sidebar = sidebar(
    shinychat::chat_ui("chat", messages = saludo, placeholder = "Filtra o controla el mapa..."),
    width = 400
  ),
  layout_columns(
    value_box("Países", textOutput("n_filas"), showcase = icon("earth-americas"), theme = "text-primary"),
    value_box("Esperanza de vida", textOutput("vida"), showcase = icon("heart-pulse"), theme="text-primary"),
    value_box("Población", textOutput("poblacion"), showcase = icon("people-group"), theme = "text-primary"),
    card(plotOutput("plot")),
    card(mapgl::maplibreOutput("map", height = "500px")),
    col_widths = c(4, 4, 4, 6, 6),
    row_heights = c(1, 3)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  titulo_actual <- reactiveVal("Todos los países")
  consulta_actual <- reactiveVal("SELECT * FROM paises")
  variable_mapa <- reactiveVal("esperanza_de_vida")

  data <- reactive({
    consulta <- paste(
      "SELECT q.*, ST_AsText(g.geometry) AS wkt",
      paste0("FROM (", consulta_actual(), ") q"),
      "JOIN paises_geo g USING (codigo)"
    )
    DBI::dbGetQuery(con, consulta) |> sf::st_as_sf(wkt = "wkt", crs = 4326)
  })

  output$titulo    <- renderText(titulo_actual())
  output$n_filas   <- renderText(nrow(data()))
  output$vida      <- renderText(paste0(round(mean(data()$esperanza_de_vida), 1), " años"))
  output$poblacion <- renderText(paste0(round(sum(data()$poblacion) / 1e6), " millones"))

  output$plot <- renderPlot({
    tinyplot(esperanza_de_vida ~ pib_per_capita, data = paises, pch = 19, col = "#d2d2d2", log = "x")
    tinyplot_add(data = sf::st_drop_geometry(data()), col = "#0E4F5A", cex = 1.5)
  })

  output$map <- mapgl::renderMaplibre({
    df <- data()
    req(nrow(df))
    df$valor_mapa <- switch(variable_mapa(),
      poblacion = log10(df$poblacion),
      pib_per_capita = log10(df$pib_per_capita),
      df$esperanza_de_vida
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

    list(
      mensaje = "Dashboard y mapa actualizados.",
      registros = nrow(resultado),
      esperanza_promedio = round(mean(resultado$esperanza_de_vida), 1),
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
    "Filtra, ordena o reinicia los datos reactivos mostrados en el dashboard y el mapa.",
    arguments = list(
      consulta = type_string("SELECT * FROM paises con WHERE u ORDER BY, sin punto y coma."),
      titulo = type_string("Título breve que describe los datos mostrados.")
    )
  ))

  chat$register_tool(tool(
    cambiar_variable,
    "Cambia la variable utilizada para colorear los países del mapa.",
    arguments = list(
      variable = type_enum(
        c("esperanza_de_vida", "poblacion", "pib_per_capita"),
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

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
