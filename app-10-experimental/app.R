library(shiny)
library(bslib)
library(dplyr)
library(stringr)

# data --------------------------------------------------------------------
catalogo <- readRDS("../data/series_catalog.rds")

buscar_series <- function(texto, n = 20) {
  terminos <- texto |> iconv(to = "ASCII//TRANSLIT") |> str_to_lower() |> str_split("\\s+") |> unlist()
  catalogo |>
    mutate(texto_busqueda = str_c(series_id, spanish_title, english_title, sep = " ") |>
      iconv(to = "ASCII//TRANSLIT") |> str_to_lower()) |>
    filter(!is.na(first_observation), !is.na(last_observation)) |>
    filter(sapply(texto_busqueda, \(x) all(str_detect(x, fixed(terminos))))) |>
    arrange(desc(last_observation)) |>
    select(-texto_busqueda) |>
    slice_head(n = n)
}

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 10 · Explorador manual",
  fillable = TRUE,
  sidebar = sidebar(
    textInput("busqueda", "Buscar", placeholder = "Escribe al menos 5 caracteres..."),
    uiOutput("selector_ui"),
    uiOutput("consulta_ui"),
    width = 400
  ),
  layout_columns(
    card(card_header(textOutput("titulo")), plotOutput("plot")),
    card(card_header("Observaciones"), tableOutput("table")),
    col_widths = 12, row_heights = c(1, 1)
  )
)

# server ------------------------------------------------------------------
server <- function(input, output) {
  busqueda   <- reactive(trimws(input$busqueda)) |> debounce(500)
  resultados <- reactive({
    req(nchar(busqueda()) >= 5)
    buscar_series(busqueda())
  })
  serie_actual   <- reactiveVal(NULL)
  datos_actuales <- reactiveVal(NULL)

  output$selector_ui <- renderUI({
    req(nrow(resultados()))
    etiquetas <- paste(resultados()$spanish_title, resultados()$frequency, sep = " · ")
    selectInput("serie", "Serie", choices = setNames(resultados()$series_id, etiquetas))
  })

  seleccion <- reactive({
    req(input$serie)
    info <- resultados() |> filter(series_id == input$serie) |> slice_head(n = 1)
    req(nrow(info))
    info
  })

  output$consulta_ui <- renderUI({
    info  <- seleccion()
    anios <- as.integer(format(c(info$first_observation, info$last_observation), "%Y"))
    tagList(
      p(paste("Frecuencia:", info$frequency)),
      p(paste("Primera observación:", info$first_observation)),
      p(paste("Última observación:", info$last_observation)),
      sliderInput("anios", "Rango", anios[1], anios[2], c(max(anios[1], anios[2] - 5), anios[2]),
        step = 1, sep = ""),
      actionButton("consultar", "Consultar", class = "btn-primary")
    )
  })

  observeEvent(input$consultar, {
    info <- seleccion()
    req(length(input$anios) == 2)
    inicio_slider <- as.Date(paste0(as.integer(input$anios[1]), "-01-01"), format = "%Y-%m-%d")
    fin_slider    <- as.Date(paste0(as.integer(input$anios[2]), "-12-31"), format = "%Y-%m-%d")
    inicio        <- max(info$first_observation, inicio_slider)
    fin           <- min(info$last_observation, fin_slider)
    datos         <- bcchr::get_series(info$series_id, inicio, fin, token = Sys.getenv("BCCH_TOKEN"))
    if (!nrow(datos)) stop("No hay observaciones en el rango consultado.")
    serie_actual(info)
    datos_actuales(datos)
  })

  output$titulo <- renderText({
    if (is.null(serie_actual())) "Busca y consulta una serie" else serie_actual()$spanish_title
  })

  output$plot <- renderPlot({
    req(datos_actuales())
    bcchr::plot_series(datos_actuales())
  })

  output$table <- renderTable({
    req(datos_actuales())
    transform(datos_actuales(), date = format(date, "%Y-%m-%d"))
  }, striped = TRUE, hover = TRUE)

}

shinyApp(ui, server)
