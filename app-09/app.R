library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(readr)
library(stringr)
library(ellmer)
library(shinychat)
library(mcptools)
library(mapgl)
library(sf)
theme_set(theme_minimal())
thematic::thematic_shiny(font = "auto")

# map ---------------------------------------------------------------------
data("countries50", package = "rnaturalearthdata")
mundo <- sf::st_transform(sf::st_as_sf(countries50), 4326)

# prompt ------------------------------------------------------------------
saludo <- read_file("greeting.md")
prompt_sistema <- read_file("prompt.md")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 09 · Conectar herramientas externas con MCP",
  sidebar = sidebar(
    shinychat::chat_ui("chat", greeting = saludo, placeholder = "Consulta datos por país..."), width = 400
  ),
  layout_columns(
    value_box("Países", textOutput("n_paises"), showcase = icon("earth-americas"), theme = "text-primary"),
    value_box("Años", textOutput("periodo"), showcase = icon("calendar"), theme = "text-primary"),
    value_box("Variables", textOutput("n_variables"), showcase = icon("table"), theme = "text-primary"),
    navset_card_tab(
      nav_panel("Visualización",
        layout_columns(
          card(card_header("Mapa"), mapgl::maplibreOutput("map", height = "500px")),
          card(card_header("Gráfico"), plotOutput("plot", height = "500px")),
          col_widths = c(6, 6)
        )
      ),
      nav_panel("Datos", tableOutput("table"))
    ),
    col_widths = c(4, 4, 4, 12), row_heights = c(1, 4)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  filas_vacias <- tibble(pais = character(), anio = integer(), x = double(), y = double())
  data <- reactiveVal(list(datos = filas_vacias, variables = tibble(indicador = character())))

  output$n_paises <- renderText(n_distinct(data()$datos$pais))
  output$n_variables <- renderText(n_distinct(data()$variables$indicador))
  output$periodo <- renderText({
    df <- data()$datos
    if (nrow(df)) paste(unique(range(df$anio)), collapse = "–") else "—"
  })
  output$table <- renderTable(data()$datos, digits = 4, striped = TRUE, hover = TRUE)

  output$plot <- renderPlot({
    df <- data()$datos |> filter(!is.na(x), !is.na(y))
    if (!nrow(df)) return(ggplot() + xlim(0, 1) + ylim(0, 1) + labs(x = "X", y = "Y"))
    etiquetas <- with(data()$variables, setNames(str_c(nombre, " · ", unidad), columna))
    ggplot(df, aes(x, y)) + geom_point(color = "#0E4F5A", size = 3) +
      labs(x = etiquetas["x"], y = etiquetas["y"])
  })

  output$map <- mapgl::renderMaplibre({
    map <- mapgl::maplibre(style = mapgl::carto_style("positron")) |> mapgl::add_globe_control()
    mapa <- mundo |> inner_join(data()$datos, by = c("adm0_a3" = "pais")) |> filter(!is.na(y))
    if (!nrow(mapa)) return(map)
    info <- data()$variables |> filter(columna == "y")
    mapa <- mapa |> mutate(detalle = str_glue(
      "{name_es}<br>{info$nombre}: {round(y, 4)} {info$unidad}<br>Año: {anio}<br>FMI · WEO"
    ))
    rango <- range(mapa$y)
    if (diff(rango) == 0) rango <- rango + c(-0.5, 0.5)
    colores <- c("#dcebea", "#0E4F5A")
    map |>
      mapgl::add_fill_layer(
        id = "paises", source = mapa, fill_opacity = 0.8, fill_outline_color = "white", tooltip = "detalle",
        fill_color = mapgl::interpolate("y", values = rango, stops = colores)
      ) |>
      mapgl::add_legend(str_c(info$nombre, " · ", info$unidad), values = rango, colors = colores)
  })

  # tools -----------------------------------------------------------------
  guardar_datos <- function(datos, variables) {
    data(list(datos = bind_rows(filas_vacias, datos), variables = bind_rows(variables)))
    paste("Vista actualizada:", length(datos), "países.")
  }

  ver_datos <- function() isolate(data())

  # chat ------------------------------------------------------------------
  chat <- ellmer::chat("openai/gpt-5.6-luna", system_prompt = prompt_sistema)
  chat$set_tools(mcp_tools("mcp.json"))
  chat$register_tool(tool(
    guardar_datos, "Reemplaza la carga: mapa usa y; gráfico y tabla usan x e y.",
    arguments = list(
      datos = type_array(type_object(
        pais = type_string("Código ISO3 del país, sin agregados."),
        anio = type_integer("Año común de los valores de esta fila."),
        x = type_number("Eje X; null para un mapa o si falta el valor.", required = FALSE),
        y = type_number("Eje Y y color del mapa; null si falta el valor.", required = FALSE)
      ), "Una fila por país; valores reales del MCP a cuatro decimales."),
      variables = type_array(type_object(
        columna = type_enum(c("x", "y"), "Columna descrita; y también se usa en el mapa."),
        indicador = type_string("ID del indicador del MCP."),
        nombre = type_string("Nombre del indicador."),
        unidad = type_string("Unidad original de la fuente.")
      ), "Metadatos de cada columna utilizada.")
    )
  ))
  chat$register_tool(tool(ver_datos, "Lee la carga actual, sus nombres y unidades, sin modificarla."))
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
