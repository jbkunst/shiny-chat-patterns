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
  unidad = c("pesos por dólar", "porcentaje", "porcentaje", "pesos por UVR")
)
endpoint <- "https://totoro.banrep.gov.co/nsi-jax-ws/rest/data"

normalizar <- function(x) tolower(iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT"))
saludo <- paste(readLines("greeting.md", warn = FALSE), collapse = "\n")
prompt_sistema <- paste(readLines("prompt.md", warn = FALSE), collapse = "\n")

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 92 · Banrep + SDMX",
  sidebar = sidebar(
    shinychat::chat_ui("chat", messages = saludo, placeholder = "Pregunta por una serie...")
  ),
  card(card_header(textOutput("titulo")), plotOutput("plot")),
  card(card_header("Últimas observaciones"), tableOutput("tabla"))
)

# server ------------------------------------------------------------------
server <- function(input, output) {
  consultas <- reactiveVal(list())
  serie_visible <- reactiveVal(NULL)

  resolver_serie <- function(texto) {
    patron <- normalizar(texto)
    candidatos <- grepl(patron, normalizar(paste(catalogo$nombre, catalogo$flow_id)), fixed = TRUE)
    catalogo[candidatos, ]
  }

  consultar_sdmx <- function(flow_id, desde, hasta) {
    if (!flow_id %in% catalogo$flow_id) stop("El flow_id no pertenece al catálogo.")
    desde <- as.integer(desde)
    hasta <- as.integer(hasta)
    if (is.na(desde) || is.na(hasta) || desde > hasta) stop("El período no es válido.")

    url <- paste0(
      endpoint, "/ESTAT,", flow_id, ",1.0/all/ALL/?startPeriod=", desde,
      "&endPeriod=", hasta + 1L, "&dimensionAtObservation=TIME_PERIOD&detail=full"
    )
    response <- httr::GET(url, httr::timeout(30))
    httr::stop_for_status(response)
    document <- xml2::read_xml(httr::content(response, as = "raw"))
    observations <- xml2::xml_find_all(document, ".//*[local-name()='Obs']")
    datos <- data.frame(
      fecha = as.Date(xml2::xml_attr(
        xml2::xml_find_first(observations, "./*[local-name()='ObsDimension']"), "value"
      ), "%Y%m%d"),
      valor = as.numeric(xml2::xml_attr(
        xml2::xml_find_first(observations, "./*[local-name()='ObsValue']"), "value"
      ))
    )
    if (!nrow(datos)) stop("La consulta SDMX no devolvió observaciones.")

    cache <- consultas()
    cache[[flow_id]] <- datos
    consultas(cache)
    list(flow_id = flow_id, observaciones = nrow(datos), desde = min(datos$fecha), hasta = max(datos$fecha))
  }

  visualizar_serie <- function(flow_id) {
    if (is.null(consultas()[[flow_id]])) stop("Consulta primero ese flow_id con consultar_sdmx.")
    serie_visible(flow_id)
    paste("Serie visible:", flow_id)
  }

  inspeccionar_vista <- function() {
    flow_id <- serie_visible()
    if (is.null(flow_id)) stop("Todavía no hay una serie visible.")
    datos <- consultas()[[flow_id]]
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
      ultimo = tail(datos, 1)
    )
  }

  output$titulo <- renderText({
    req(serie_visible())
    catalogo$nombre[catalogo$flow_id == serie_visible()]
  })
  output$plot <- renderPlot({
    req(serie_visible())
    tinyplot(valor ~ fecha, data = consultas()[[serie_visible()]], type = "l", lwd = 2, col = "#0E4F5A")
  })
  output$tabla <- renderTable({
    req(serie_visible())
    tail(consultas()[[serie_visible()]], 10)
  }, striped = TRUE, hover = TRUE)

  # tools -----------------------------------------------------------------
  chat <- ellmer::chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)
  chat$register_tool(tool(
    resolver_serie,
    "Resuelve palabras del usuario a un flow_id SDMX disponible.",
    arguments = list(texto = type_string("Nombre, sigla o tema de la serie."))
  ))
  chat$register_tool(tool(
    consultar_sdmx,
    "Consulta observaciones reales desde el endpoint SDMX REST/XML de Banrep.",
    arguments = list(
      flow_id = type_string("Flow ID exacto obtenido con resolver_serie."),
      desde = type_integer("Año inicial."),
      hasta = type_integer("Año final inclusivo.")
    )
  ))
  chat$register_tool(tool(
    visualizar_serie,
    "Muestra en el dashboard una serie SDMX que ya fue consultada.",
    arguments = list(flow_id = type_string("Flow ID previamente consultado."))
  ))
  chat$register_tool(tool(
    inspeccionar_vista,
    "Devuelve metadatos y estadísticas de la serie visible para fundamentar la respuesta."
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input, tool_mode = "sequential", stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
