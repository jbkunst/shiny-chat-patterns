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
  title = "App 09 v3 · Dashboard configurable con MCP",
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
  data <- reactiveVal(list(
    datos = tibble(pais = character(), anio = integer(), x_var = double(), y_var = double(),
      size_var = double(), color_var = double(), map_var = double()),
    variables = tibble(indicador = character())
  ))
  escala <- reactiveVal("")
  escala_tamano <- reactiveVal("area")

  output$n_paises <- renderText(n_distinct(data()$datos$pais))
  output$n_variables <- renderText(n_distinct(data()$variables$indicador))
  output$periodo <- renderText({
    df <- data()$datos
    if (nrow(df)) paste(unique(range(df$anio)), collapse = "–") else "—"
  })
  output$table <- renderTable(data()$datos, digits = 4, striped = TRUE, hover = TRUE)

  output$plot <- renderPlot({
    df <- data()$datos |> filter(if_all(c(x_var, y_var), ~ !is.na(.x)),
      !grepl("x", escala()) | x_var > 0, !grepl("y", escala()) | y_var > 0)
    if (!nrow(df)) return(ggplot() + xlim(0, 1) + ylim(0, 1) +
      theme(axis.line = element_line(), panel.grid = element_blank(),
        axis.text = element_blank(), axis.ticks = element_blank()) + labs(x = "X", y = "Y"))
    info <- data()$variables
    etiquetas <- with(info, setNames(str_c(nombre, " · ", unidad), columna))
    tamano <- if (escala_tamano() == "log10") scale_size_continuous(transform = "log10")
      else scale_size_area(max_size = 9)
    tamano$na.value <- 3
    ggplot(df, aes(x_var, y_var, size = size_var, color = color_var)) +
      geom_point() + tamano +
      scale_color_gradient(low = "#9cc9c4", high = "#0E4F5A", na.value = "#0E4F5A") +
      scale_x_continuous(transform = if (grepl("x", escala())) "log10" else "identity") +
      scale_y_continuous(transform = if (grepl("y", escala())) "log10" else "identity") +
      labs(x = etiquetas["x_var"], y = etiquetas["y_var"],
        size = etiquetas["size_var"], color = etiquetas["color_var"])
  })

  output$map <- mapgl::renderMaplibre({
    map <- mapgl::maplibre(style = mapgl::carto_style("positron")) |> mapgl::add_globe_control()
    mapa <- mundo |> inner_join(data()$datos |> filter(!is.na(map_var)), by = c("adm0_a3" = "pais"))
    if (!nrow(mapa)) return(map)
    info <- data()$variables |> filter(columna == "map_var")
    mapa <- mapa |> mutate(detalle = str_glue(
      "{name_es}<br>{info$nombre}: {round(map_var, 4)} {info$unidad}<br>Año: {anio}<br>FMI · WEO"
    ))
    rango <- range(mapa$map_var)
    if (diff(rango) == 0) rango <- rango + c(-0.5, 0.5)
    colores <- c("#dcebea", "#0E4F5A")
    map |>
      mapgl::add_fill_layer(
        id = "paises", source = mapa, fill_opacity = 0.8, fill_outline_color = "white", tooltip = "detalle",
        fill_color = mapgl::interpolate("map_var", values = rango, stops = colores)
      ) |>
      mapgl::add_legend(str_c(info$nombre, " · ", info$unidad), values = rango, colors = colores)
  })

  # tools -----------------------------------------------------------------
  guardar_datos <- function(datos, variables) {
    data(list(datos = bind_rows(isolate(data())$datos[0, ], datos),
      variables = bind_rows(variables)))
    paste("Vista actualizada:", length(datos), "países.")
  }

  ver_datos <- function() isolate(data())

  configurar_grafico <- function(log = NULL, tamano = NULL) {
    if (!is.null(log)) escala(log)
    if (!is.null(tamano)) escala_tamano(tamano)
    "Escala del gráfico actualizada."
  }

  # chat ------------------------------------------------------------------
  chat <- ellmer::chat("openai/gpt-5.6-luna", system_prompt = prompt_sistema)
  chat$set_tools(mcp_tools("mcp.json"))
  chat$register_tool(tool(
    guardar_datos, "Reemplaza la carga completa que comparten mapa, dispersión y tabla.",
    arguments = list(
      datos = type_array(type_object(
        pais = type_string("Código ISO3 del país, sin agregados."),
        anio = type_integer("Año real de los valores de esta fila."),
        x_var = type_number("Valor del eje X; null si no se usa.", required = FALSE),
        y_var = type_number("Valor del eje Y; null si no se usa.", required = FALSE),
        size_var = type_number("Valor positivo para el tamaño; null si no se usa.", required = FALSE),
        color_var = type_number("Valor para el color del punto; null para color uniforme.", required = FALSE),
        map_var = type_number("Valor para el color del país; null si no se usa.", required = FALSE)
      ), "Una fila por país; valores reales del MCP a cuatro decimales."),
      variables = type_array(type_object(
        columna = type_enum(c("x_var", "y_var", "size_var", "color_var", "map_var"), "Papel en la vista."),
        indicador = type_string("ID exacto del indicador del MCP."),
        nombre = type_string("Nombre breve del indicador."),
        unidad = type_string("Unidad original de la fuente.")
      ), "Nombre y unidad de cada columna utilizada. Un indicador puede tener varios usos.")
    )
  ))
  chat$register_tool(tool(ver_datos, "Lee la carga actual, sus nombres y unidades, sin modificarla."))
  chat$register_tool(tool(
    configurar_grafico, "Cambia las escalas de ejes y tamaño; conserva los datos.",
    arguments = list(
      log = type_enum(c("", "x", "y", "xy"), "Ejes logarítmicos; vacío para lineales.", required = FALSE),
      tamano = type_enum(c("area", "log10"), "Área proporcional o tamaño logarítmico.", required = FALSE)
    )
  ))
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
