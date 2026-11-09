library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(httr)
library(xml2)
library(tinyplot)

# data --------------------------------------------------------------------
catalogo <- data.frame(
  flow_id = c(
    "DF_TRM_DAILY_HIST", "DF_CBR_DAILY_HIST", "DF_DTF_DAILY_HIST", "DF_UVR_DAILY_HIST"
  ),
  nombre = c("TRM diaria", "Tasa de política monetaria", "DTF a 90 días", "UVR diaria"),
  unidad = c("pesos por dólar", "% anual", "% anual", "pesos por UVR"),
  unidad_sdmx = c("COP", "PA", "PA", "CRVU")
)
endpoint <- "https://totoro.banrep.gov.co/nsi-jax-ws/rest/data"

normalizar <- function(x) tolower(iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT"))
saludo <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "Series de Colombia",
  theme = bs_theme(bg = "#f8fafb", fg = "#213741", primary = "#2B617F"),
  fillable = FALSE,
  tags$style(HTML("
    #vista h2 { margin: 0; font-size: 1.65rem; font-weight: 600; }
    .series-meta { margin: .4rem 0 1.25rem; color: #647781; }
    #vista h3 { margin: 1.5rem 0 .75rem; font-size: 1.1rem; font-weight: 600; }
    #tabla table { font-variant-numeric: tabular-nums; }
    #tabla thead th { background: #eef3f5; color: #365365; border-bottom: 2px solid #d6e0e6; }
    .series-source { color: #647781; }
  ")),
  sidebar = sidebar(
    width = 400, bg = "#ffffff",
    shinychat::chat_ui("chat", greeting = saludo, placeholder = "Pregunta por una serie...")
  ),
  uiOutput("vista"),
  tags$small(
    class = "series-source",
    "Fuente: ", tags$a("Banco de la República", href = "https://suameca.banrep.gov.co/"),
    " · Datos diarios consultados mediante SDMX."
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  consultas <- reactiveVal(list())
  serie_visible <- reactiveVal(NULL)

  resolver_serie <- function(texto = "") {
    patron <- normalizar(texto)
    candidatos <- grepl(patron, normalizar(paste(catalogo$nombre, catalogo$flow_id)), fixed = TRUE)
    catalogo[candidatos, ]
  }

  consultar_sdmx <- function(flow_id, desde, hasta) {
    if (!flow_id %in% catalogo$flow_id) stop("El flow_id no pertenece al catálogo.")
    desde <- as.integer(desde)
    hasta <- as.integer(hasta)
    if (is.na(desde) || is.na(hasta) || desde > hasta) stop("El período no es válido.")

    # Este servicio usa el inicio del año siguiente como límite final.
    url <- paste0(
      endpoint, "/ESTAT,", flow_id, ",1.0/all/ALL/?startPeriod=", desde,
      "&endPeriod=", hasta + 1L, "&dimensionAtObservation=TIME_PERIOD&detail=full"
    )
    response <- httr::GET(url, httr::timeout(30))
    httr::stop_for_status(response)
    document <- xml2::read_xml(httr::content(response, as = "raw"))
    info <- catalogo[catalogo$flow_id == flow_id, ]
    series <- xml2::xml_find_all(document, ".//*[local-name()='Series']")
    unidades <- xml2::xml_attr(xml2::xml_find_first(
      series, "./*[local-name()='SeriesKey']/*[@id='UNIT_MEASURE']"
    ), "value")
    observations <- xml2::xml_find_all(series[unidades == info$unidad_sdmx], "./*[local-name()='Obs']")
    datos <- data.frame(
      fecha = as.Date(xml2::xml_attr(
        xml2::xml_find_first(observations, "./*[local-name()='ObsDimension']"), "value"
      ), "%Y%m%d"),
      valor = as.numeric(xml2::xml_attr(
        xml2::xml_find_first(observations, "./*[local-name()='ObsValue']"), "value"
      ))
    )
    inicio <- as.Date(paste0(desde, "-01-01"))
    fin <- as.Date(paste0(hasta, "-12-31"))
    datos <- datos[!is.na(datos$fecha) & is.finite(datos$valor) &
      datos$fecha >= inicio & datos$fecha <= fin, ]
    datos <- datos[order(datos$fecha), ]
    if (!nrow(datos)) stop("La consulta no devolvió observaciones para ese período.")

    cache <- consultas()
    cache[[flow_id]] <- datos
    consultas(cache)
    list(
      flow_id = flow_id, nombre = info$nombre, unidad = info$unidad,
      observaciones = nrow(datos), desde = min(datos$fecha), hasta = max(datos$fecha)
    )
  }

  visualizar_serie <- function(flow_id) {
    if (is.null(consultas()[[flow_id]])) stop("Consulta primero ese flow_id con consultar_sdmx.")
    serie_visible(list(flow_id = flow_id, datos = consultas()[[flow_id]]))
    paste("Serie visible:", flow_id)
  }

  inspeccionar_vista <- function() {
    vista <- serie_visible()
    if (is.null(vista)) stop("Todavía no hay una serie visible.")
    flow_id <- vista$flow_id
    datos <- vista$datos
    info <- catalogo[catalogo$flow_id == flow_id, ]
    list(
      flow_id = flow_id,
      nombre = info$nombre,
      unidad = info$unidad,
      observaciones = nrow(datos),
      desde = min(datos$fecha),
      hasta = max(datos$fecha),
      minimo = min(datos$valor, na.rm = TRUE),
      maximo = max(datos$valor, na.rm = TRUE),
      ultimo = tail(datos, 1),
      fuente = "Banco de la República · SDMX"
    )
  }

  output$vista <- renderUI({
    vista <- serie_visible()
    if (is.null(vista)) {
      return(tagList(
        h2("Explora una serie económica"),
        p("Pide una serie y un período en el chat. Aquí aparecerán su gráfico y sus últimos datos."),
        p(tags$strong("Por ejemplo: "), "Grafica la TRM de 2025 y dime cómo terminó el año."),
        p("Disponibles: TRM, tasa de política monetaria, DTF a 90 días y UVR.")
      ))
    }
    info <- catalogo[catalogo$flow_id == vista$flow_id, ]
    tagList(
      h2(info$nombre),
      p(class = "series-meta", paste(info$unidad, "·", min(vista$datos$fecha), "a", max(vista$datos$fecha))),
      plotOutput("plot", height = "360px"),
      h3("Últimas observaciones"), tableOutput("tabla")
    )
  })
  output$plot <- renderPlot({
    req(serie_visible())
    vista <- serie_visible()
    unidad <- catalogo$unidad[catalogo$flow_id == vista$flow_id]
    par(bg = "transparent", col.axis = "#647781", col.lab = "#213741", mar = c(4, 4.5, 1, 1))
    tinyplot(valor ~ fecha, data = vista$datos, type = "l", lwd = 2.5, col = "#2B617F",
      xlab = "Fecha", ylab = unidad, bty = "n")
  }, bg = "transparent")
  output$tabla <- renderTable({
    req(serie_visible())
    datos <- tail(serie_visible()$datos, 10)
    datos$fecha <- as.character(datos$fecha)
    names(datos) <- c("Fecha", "Valor")
    datos
  }, width = "100%", align = "lr", striped = TRUE, hover = TRUE, digits = 4)

  # tools -----------------------------------------------------------------
  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)
  chat$register_tool(tool(
    resolver_serie,
    "Resuelve palabras del usuario a un flow_id SDMX disponible.",
    arguments = list(texto = type_string("Nombre o sigla; vacío lista todas.", required = FALSE))
  ))
  chat$register_tool(tool(
    consultar_sdmx,
    "Consulta observaciones reales desde el endpoint SDMX REST/XML de Banrep.",
    arguments = list(
      flow_id = type_enum(catalogo$flow_id, "Flow ID exacto obtenido con resolver_serie."),
      desde = type_integer("Año inicial."),
      hasta = type_integer("Año final inclusivo.")
    )
  ))
  chat$register_tool(tool(
    visualizar_serie,
    "Grafica una serie ya consultada. Después llama a inspeccionar_vista para leer el resultado.",
    arguments = list(flow_id = type_enum(catalogo$flow_id, "Flow ID previamente consultado."))
  ))
  chat$register_tool(tool(
    inspeccionar_vista,
    "Devuelve metadatos y estadísticas de la serie visible para fundamentar la respuesta."
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
