library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(mapgl)
library(sf)

# data --------------------------------------------------------------------
departamentos <- readRDS("data/colombia_departamentos.rds")
catalogo <- data.frame(
  indicador = c(
    "poblacion", "hogares", "viviendas", "area_m2", "hogares_por_vivienda", "personas_por_hogar",
    "energia_pct", "gas_natural_pct", "acueducto_pct", "alcantarillado_pct", "recoleccion_basura_pct",
    "hogares_internet_pct", "deficit_cuantitativo_pct", "deficit_cualitativo_pct", "deficit_habitacional_pct",
    "afiliacion_salud_pct", "anios_educacion", "uso_computador_pct", "uso_internet_pct", "uso_celular_pct",
    "pobreza_percibida_pct"
  ),
  titulo = c(
    "Población estimada", "Hogares estimados", "Viviendas estimadas", "Área (MGN 2018)",
    "Hogares por vivienda", "Personas por hogar", "Hogares con energía eléctrica",
    "Hogares con gas natural", "Hogares con acueducto", "Hogares con alcantarillado",
    "Hogares con recolección de basura", "Hogares con internet", "Déficit habitacional cuantitativo",
    "Déficit habitacional cualitativo", "Déficit habitacional total", "Afiliación al sistema de salud",
    "Años promedio de educación", "Uso de computador", "Uso de internet", "Uso de teléfono celular",
    "Pobreza percibida por los hogares"
  ),
  unidad = c(
    "personas", "hogares", "viviendas", "m²", "hogares por vivienda", "personas por hogar",
    rep("% de hogares", 9), "% de personas", "años · personas de 5 años y más",
    rep("% de personas de 5 años y más", 3), "% de hogares"
  ),
  anio = 2025L
)
catalogo$anio[catalogo$indicador == "area_m2"] <- 2018L
colores <- c("#F5E9C9", "#D5DCC5", "#A6C6C6", "#6F9FB5", "#2B617F")

normalizar <- function(x) {
  tolower(iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT"))
}

saludo <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_fillable(
  title = "App 91 · Colombia territorial",
  padding = 0,
  tags$style(HTML("
    .territorial-map { height: 100dvh; }
    .floating-chat { position: absolute; z-index: 10; top: 16px; left: 16px;
      width: min(390px, calc(100% - 32px)); height: calc(100dvh - 32px);
      display: flex; flex-direction: column; gap: 12px; padding: 16px;
      min-height: 0; overflow: hidden; background: #fff;
      border: 1px solid #d8dee4; border-radius: 10px; box-shadow: 0 4px 20px #0002; }
    .floating-chat > :not(.chat-wrapper) { flex: 0 0 auto; }
    .floating-chat h2 { margin: 0; font-size: 19px; font-weight: 600; color: #28334a; }
    .floating-chat #contexto p { margin: 0; font-size: 14px; }
    .chat-wrapper { display: flex; flex-direction: column; flex: 1 1 0;
      min-height: 0; overflow: hidden; }
    .chat-wrapper shiny-chat-container { flex: 1 1 auto; min-height: 0; }
    .floating-chat footer { display: flex; flex-direction: column; gap: 8px; }
    .floating-chat small { color: #59656d; font-size: 11px; }
    @media (max-width: 700px) {
      .floating-chat { top: auto; bottom: 16px; height: 48dvh; }
      #escala-territorial { bottom: calc(48dvh + 24px); }
    }
  ")),
  div(class = "territorial-map", mapgl::maplibreOutput("map", height = "100%")),
  div(
    class = "floating-chat",
    h2("Colombia territorial"),
    uiOutput("contexto"),
    div(class = "chat-wrapper",
      shinychat::chat_ui("chat", greeting = saludo, placeholder = "Explora Colombia...", height = "100%")
    ),
    tags$footer(
      actionButton("ver_colombia", "Ver toda Colombia", class = "btn-outline-secondary btn-sm"),
      tags$small("Fuente: DANE · ECV 2025. Geometría: MGN 2018 / data_ColOpenData.")
    )
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  consulta_preparada <- reactiveVal(NULL)
  indicador_actual <- reactiveVal("poblacion")
  territorio_actual <- reactiveVal(NULL)

  datos_visibles <- reactive({
    territorio <- territorio_actual()
    if (is.null(territorio)) departamentos else departamentos[departamentos$codigo == territorio, ]
  })
  output$contexto <- renderUI({
    info <- catalogo[catalogo$indicador == indicador_actual(), ]
    territorio <- if (is.null(territorio_actual())) "Colombia · 33 territorios" else {
      datos_visibles()$departamento
    }
    tags$p(tags$strong(info$titulo), paste0(" · ", info$unidad, " · ", info$anio), tags$br(), territorio)
  })

  output$map <- mapgl::renderMaplibre({
    rango <- range(departamentos$poblacion)
    valores <- seq(rango[1], rango[2], length.out = length(colores))
    mapgl::maplibre(style = mapgl::carto_style("positron"), bounds = departamentos) |>
      mapgl::add_source("territorios", departamentos) |>
      mapgl::add_fill_layer(
        id = "contexto", source = "territorios", fill_color = "#e5e8eb", fill_outline_color = "white",
        before_id = "watername_ocean"
      ) |>
      mapgl::add_fill_layer(
        id = "departamentos", source = "territorios",
        fill_color = mapgl::interpolate(
          "poblacion", values = valores, stops = colores
        ),
        fill_opacity = 0.72, fill_outline_color = "white", tooltip = "departamento",
        before_id = "watername_ocean"
      ) |>
      mapgl::add_continuous_legend(
        "Población estimada · personas", values = rango, colors = colores,
        position = "bottom-right", unique_id = "escala-territorial"
      )
  })

  observeEvent(indicador_actual(), {
    indicador <- indicador_actual()
    info <- catalogo[catalogo$indicador == indicador, ]
    rango <- range(departamentos[[indicador]], na.rm = TRUE)
    valores <- seq(rango[1], rango[2], length.out = length(colores))
    mapgl::maplibre_proxy("map", session) |>
      mapgl::set_paint_property(
        "departamentos", "fill-color", mapgl::interpolate(indicador, values = valores, stops = colores)
      ) |>
      mapgl::add_continuous_legend(
        paste(info$titulo, info$unidad, sep = " · "), values = rango, colors = colores,
        position = "bottom-right", unique_id = "escala-territorial"
      )
  }, ignoreInit = TRUE)

  # tools -----------------------------------------------------------------
  resolver_catalogo <- function(texto = "") {
    patron <- normalizar(texto)
    indicadores <- grepl(patron, normalizar(paste(catalogo$titulo, catalogo$indicador)), fixed = TRUE)
    territorios <- grepl(patron, normalizar(departamentos$departamento), fixed = TRUE)
    list(
      indicadores = catalogo[indicadores, ],
      territorios = sf::st_drop_geometry(departamentos[territorios, c("codigo", "departamento")])
    )
  }

  consultar_indicador <- function(indicador, codigo = "Colombia") {
    if (!indicador %in% catalogo$indicador) stop("Indicador no disponible.")
    if (!codigo %in% c("Colombia", departamentos$codigo)) stop("Código territorial no disponible.")

    territorio <- if (codigo == "Colombia") NULL else codigo
    df <- if (is.null(territorio)) departamentos else departamentos[departamentos$codigo == territorio, ]
    info <- catalogo[catalogo$indicador == indicador, ]
    consulta_preparada(list(indicador = indicador, codigo = territorio))
    list(
      indicador = indicador, titulo = info$titulo, unidad = info$unidad, anio = info$anio,
      datos = sf::st_drop_geometry(df[c("codigo", "departamento", indicador)])
    )
  }

  visualizar_indicador <- function() {
    consulta <- consulta_preparada()
    if (is.null(consulta)) stop("Consulta primero los datos con consultar_indicador.")

    indicador_actual(consulta$indicador)
    territorio_actual(consulta$codigo)
    filtro <- if (is.null(consulta$codigo)) NULL else list("==", list("get", "codigo"), consulta$codigo)
    mapgl::maplibre_proxy("map", session) |>
      mapgl::set_filter("departamentos", filtro) |>
      mapgl::fit_bounds(datos_visibles(), animate = TRUE, padding = 60)
    paste("Mapa actualizado:", consulta$indicador)
  }

  inspeccionar_vista <- function() {
    df <- sf::st_drop_geometry(datos_visibles())
    indicador <- indicador_actual()
    info <- catalogo[catalogo$indicador == indicador, ]
    list(
      indicador = indicador,
      titulo = info$titulo,
      unidad = info$unidad,
      anio = info$anio,
      fuente = if (indicador == "area_m2") "MGN 2018 / data_ColOpenData" else "DANE · ECV 2025",
      territorios = nrow(df),
      minimo = min(df[[indicador]], na.rm = TRUE),
      maximo = max(df[[indicador]], na.rm = TRUE),
      datos = df[c("codigo", "departamento", indicador)]
    )
  }
  observeEvent(input$ver_colombia, {
    consultar_indicador(indicador_actual())
    visualizar_indicador()
  })

  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)
  chat$register_tool(tool(
    resolver_catalogo,
    "Busca indicadores y departamentos en el catálogo local; devuelve nombres, unidades, años y códigos.",
    arguments = list(
      texto = type_string("Palabra del indicador o departamento; vacío lista todo.", required = FALSE)
    )
  ))
  chat$register_tool(tool(
    consultar_indicador,
    "Lee observaciones locales. Para la coropleta nacional, consulta Colombia una vez y luego visualiza.",
    arguments = list(
      indicador = type_enum(catalogo$indicador, "Indicador exacto obtenido del catálogo."),
      codigo = type_enum(
        c("Colombia", departamentos$codigo), "Colombia para todos los departamentos, o un código DANE."
      )
    )
  ))
  chat$register_tool(tool(
    visualizar_indicador,
    "Colorea la selección consultada y ajusta la cámara. Después llama a inspeccionar_vista."
  ))
  chat$register_tool(tool(
    inspeccionar_vista,
    "Devuelve datos y extremos de la vista actual para fundamentar la respuesta."
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
