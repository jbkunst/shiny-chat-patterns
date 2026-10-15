library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(mapgl)
library(sf)

# data --------------------------------------------------------------------
departamentos <- readRDS("data/colombia_departamentos.rds")
catalogo <- data.frame(
  indicador = c("poblacion", "hogares", "viviendas", "area_m2"),
  titulo = c("Población censada", "Hogares", "Viviendas", "Área"),
  unidad = c("personas", "hogares", "viviendas", "m²")
)

normalizar <- function(x) {
  tolower(iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT"))
}

saludo <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_fillable(
  title = "App 91 · Colombia territorial",
  tags$style(HTML(paste(
    ".territorial-map { height: calc(100vh - 58px); }",
    ".floating-chat { position: absolute; z-index: 10; top: 76px; left: 18px;",
    "width: 390px; max-height: calc(100vh - 96px); padding: 14px; overflow: auto;",
    "border: 1px solid #d8dee4; border-radius: 14px; background: rgba(255,255,255,.96);",
    "box-shadow: 0 12px 34px rgba(0,0,0,.16); }"
  ))),
  div(class = "territorial-map", mapgl::maplibreOutput("map", height = "100%")),
  div(
    class = "floating-chat",
    shinychat::chat_ui("chat", messages = saludo, placeholder = "Explora Colombia...")
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  indicador_actual <- reactiveVal("poblacion")
  territorio_actual <- reactiveVal(NULL)

  datos_visibles <- reactive({
    territorio <- territorio_actual()
    if (is.null(territorio)) departamentos else departamentos[departamentos$codigo == territorio, ]
  })

  output$map <- mapgl::renderMaplibre({
    indicador <- indicador_actual()
    df <- departamentos
    df$valor <- df[[indicador]]
    rango <- range(df$valor, na.rm = TRUE)

    mapgl::maplibre(style = mapgl::carto_style("positron"), bounds = df) |>
      mapgl::add_fill_layer(
        id = "departamentos", source = df,
        fill_color = mapgl::interpolate(
          "valor", values = rango, stops = c("#dcebea", "#0E4F5A")
        ),
        fill_opacity = 0.82, fill_outline_color = "white", tooltip = "departamento"
      )
  })

  # tools -----------------------------------------------------------------
  resolver_territorio <- function(texto) {
    patron <- normalizar(texto)
    candidatos <- grepl(patron, normalizar(departamentos$departamento), fixed = TRUE)
    sf::st_drop_geometry(departamentos[candidatos, c("codigo", "departamento")])
  }

  consultar_indicadores <- function(texto = "") {
    patron <- normalizar(texto)
    candidatos <- grepl(patron, normalizar(paste(catalogo$titulo, catalogo$indicador)), fixed = TRUE)
    catalogo[candidatos, ]
  }

  visualizar_indicador <- function(indicador, codigo = NULL) {
    if (!indicador %in% catalogo$indicador) stop("Indicador no disponible.")
    if (!is.null(codigo) && !codigo %in% departamentos$codigo) stop("Código territorial no disponible.")

    indicador_actual(indicador)
    territorio_actual(codigo)
    if (!is.null(codigo)) {
      lugar <- departamentos[departamentos$codigo == codigo, ]
      mapgl::maplibre_proxy("map", session) |>
        mapgl::fly_to(center = c(lugar$longitud[1], lugar$latitud[1]), zoom = 5)
    }
    territorio <- if (is.null(codigo)) "Colombia" else codigo
    list(indicador = indicador, territorio = territorio)
  }

  inspeccionar_vista <- function() {
    df <- sf::st_drop_geometry(datos_visibles())
    indicador <- indicador_actual()
    list(
      indicador = indicador,
      territorios = nrow(df),
      minimo = min(df[[indicador]], na.rm = TRUE),
      maximo = max(df[[indicador]], na.rm = TRUE),
      datos = df[c("codigo", "departamento", indicador)]
    )
  }

  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)
  chat$register_tool(tool(
    resolver_territorio,
    "Resuelve un nombre parcial de departamento a su nombre y código DANE.",
    arguments = list(texto = type_string("Nombre total o parcial del departamento."))
  ))
  chat$register_tool(tool(
    consultar_indicadores,
    "Busca indicadores disponibles en el catálogo local.",
    arguments = list(texto = type_string("Palabra asociada al indicador.", required = FALSE))
  ))
  chat$register_tool(tool(
    visualizar_indicador,
    "Colorea el mapa por un indicador y opcionalmente acerca la cámara a un territorio.",
    arguments = list(
      indicador = type_enum(catalogo$indicador, "Indicador exacto obtenido del catálogo."),
      codigo = type_string("Código DANE exacto del departamento.", required = FALSE)
    )
  ))
  chat$register_tool(tool(
    inspeccionar_vista,
    "Devuelve datos y extremos de la vista actual para fundamentar la respuesta."
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
