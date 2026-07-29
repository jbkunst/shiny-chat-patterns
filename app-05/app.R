library(shiny)
library(bslib)
library(leaflet)
library(sf)
library(ellmer)
library(shinychat)

system_prompt_text <- paste(
  "Eres un asistente breve para explorar un mapa mundial.",
  "",
  "- Usa `go_to_country` para viajar a un país.",
  "- Usa `show_country_report` para abrir su informe.",
  "- Usa `change_metric` para cambiar la coropleta.",
  "- Las métricas disponibles son `life_expectancy`, `life_expectancy_change`, `population_growth`, `population`, `gdp_per_capita` y `gdp_growth`.",
  "- Responde siempre en español.",
  sep = "\n"
)

greeting_text <- paste(
  "Datos históricos de **Gapminder**.",
  "",
  "Puedes mostrar **esperanza de vida**, **cambio en esperanza de vida**, **crecimiento poblacional**, **población**, **PIB por habitante** o **crecimiento del PIB por habitante**.",
  "",
  "Prueba: **viaja a China** o **abre el informe de Chile**.",
  sep = "\n"
)

# data --------------------------------------------------------------------
data("countries110", package = "rnaturalearthdata")

countries <- st_transform(countries110, 4326)
countries$country_id <- countries$adm0_a3
countries$country_name <- ifelse(
  is.na(countries$name_es) | countries$name_es == "",
  countries$name,
  countries$name_es
)
gap_2007 <- subset(gapminder::gapminder, year == 2007)
gap_1997 <- subset(gapminder::gapminder, year == 1997)
gap_2007$country_id <- countrycode::countrycode(gap_2007$country, "country.name", "iso3c")
gap_1997$country_id <- countrycode::countrycode(gap_1997$country, "country.name", "iso3c")

index_2007 <- match(countries$country_id, gap_2007$country_id)
index_1997 <- match(countries$country_id, gap_1997$country_id)
countries$life_expectancy_1997 <- gap_1997$lifeExp[index_1997]
countries$life_expectancy <- gap_2007$lifeExp[index_2007]
countries$life_expectancy_change <- round(
  countries$life_expectancy - countries$life_expectancy_1997,
  1
)
countries$population_1997 <- gap_1997$pop[index_1997]
countries$population_2007 <- gap_2007$pop[index_2007]
countries$population_growth <- round(
  100 * (countries$population_2007 / countries$population_1997 - 1),
  1
)
countries$gdp_per_capita_1997 <- gap_1997$gdpPercap[index_1997]
countries$gdp_per_capita_2007 <- gap_2007$gdpPercap[index_2007]
countries$gdp_per_capita_growth <- round(
  100 * (countries$gdp_per_capita_2007 / countries$gdp_per_capita_1997 - 1),
  1
)

metrics <- list(
  life_expectancy = list(column = "life_expectancy", label = "Esperanza de vida (2007)"),
  life_expectancy_change = list(column = "life_expectancy_change", label = "Cambio en esperanza de vida (años)"),
  population_growth = list(column = "population_growth", label = "Crecimiento poblacional (%)"),
  population = list(column = "population_2007", label = "Población (2007)"),
  gdp_per_capita = list(column = "gdp_per_capita_2007", label = "PIB por habitante (2007)"),
  gdp_growth = list(column = "gdp_per_capita_growth", label = "Crecimiento del PIB por habitante (%)")
)

country_data <- data.frame(
  ISO = countries$country_id,
  País = countries$country_name,
  Continente = countries$continent,
  `Esperanza de vida 1997` = countries$life_expectancy_1997,
  `Esperanza de vida 2007` = countries$life_expectancy,
  `Cambio esperanza de vida` = countries$life_expectancy_change,
  `Población 1997` = countries$population_1997,
  `Población 2007` = countries$population_2007,
  `Crecimiento población` = countries$population_growth,
  `PIB por habitante 1997` = countries$gdp_per_capita_1997,
  `PIB por habitante 2007` = countries$gdp_per_capita_2007,
  `Crecimiento PIB por habitante` = countries$gdp_per_capita_growth,
  check.names = FALSE
)

add_choropleth <- function(map, metric) {
  info <- metrics[[metric]]
  values <- countries[[info$column]]
  colors <- c("#DCE6EB", "#A8C0CC", "#6F98AA", "#3F7188", "#234A5C")

  if (metric %in% c("population", "gdp_per_capita")) {
    values <- log10(values)
    info$label <- paste(info$label, "— escala log10")
    palette <- colorNumeric(colors, values, na.color = "transparent")
  } else {
    palette <- colorQuantile(colors, values, n = 5, na.color = "transparent")
  }

  map |>
    addPolygons(
      data = countries,
      layerId = ~country_id,
      fillColor = palette(values),
      fillOpacity = 0.8,
      color = "white",
      weight = 0.5,
      label = ~country_name
    ) |>
    addLegend(
      position = "bottomright",
      pal = palette,
      values = values,
      title = info$label
    )
}

# user interface ----------------------------------------------------------
ui <- page_sidebar(
  title = "App 05 - Mapa mundial",
  sidebar = sidebar(
    width = 400,
    shinychat::chat_mod_ui(
      "chat",
      placeholder = "Viaja a China..."
    )
  ),
  fillable = TRUE,
  fillable_mobile = TRUE,
  navset_card_tab(
    nav_panel(
      "Censo mundial",
      div(
        style = "position: relative; width: 100%; height: 100%; min-height: 0;",
        leafletOutput("map", width = "100%", height = "100%")
      )
    ),
    nav_panel(
      "Acerca de",
      div(
        class = "p-4",
        h2("Acerca de"),
        p("Ejemplo mínimo con geometrías de Natural Earth y datos históricos de Gapminder."),
        div(style = "overflow-x: auto;", tableOutput("country_table"))
      )
    )
  )
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  map_metric <- reactiveVal("life_expectancy")
  selected_country <- reactiveVal(NULL)

  output$country_table <- renderTable(country_data, striped = TRUE, hover = TRUE)

  output$map <- renderLeaflet({
    leaflet(options = leafletOptions(zoomControl = FALSE)) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      setView(lng = 0, lat = 20, zoom = 2)
  })

  update_choropleth <- function(metric) {
    leafletProxy("map", session = session) |>
      clearShapes() |>
      clearControls() |>
      add_choropleth(metric)
  }

  session$onFlushed(function() {
    update_choropleth("life_expectancy")
  }, once = TRUE)

  observeEvent(map_metric(), ignoreInit = TRUE, {
    update_choropleth(map_metric())
  })

  find_country <- function(country_name) {
    query <- tolower(trimws(country_name))
    index <- which(
      tolower(countries$country_name) == query |
        tolower(countries$name) == query
    )[1]
    if (is.na(index)) {
      stop("No encontré ese país.")
    }

    countries[index, ]
  }

  center_country <- function(country, zoom = 4) {
    leafletProxy("map", session = session) |>
      flyTo(
        lng = country$label_x,
        lat = country$label_y,
        zoom = zoom,
        options = list(duration = 1.5)
      )
  }

  show_country_report <- function(country_name) {
    country <- find_country(country_name)
    selected_country(NULL)
    selected_country(country$country_id)
    center_country(country)

    paste("Informe abierto para", country$country_name)
  }

  observeEvent(selected_country(), {
    country <- countries[countries$country_id == selected_country(), ]

    showModal(modalDialog(
      title = country$country_name,
      layout_columns(
        col_widths = c(6, 6),
        value_box(
          "Esperanza de vida",
          paste0(country$life_expectancy, " años")
        ),
        value_box(
          "Crecimiento poblacional",
          paste0(country$population_growth, "%")
        )
      ),
      easyClose = TRUE,
      footer = modalButton("Enviar datos a mi cliente")
    ), session = session)
  })

  observeEvent(input$map_shape_click, {
    country <- countries[countries$country_id == input$map_shape_click$id, ]
    show_country_report(country$country_name)
  })

  go_to_country <- function(country_name, zoom = 4) {
    country <- find_country(country_name)
    center_country(country, zoom)
    paste("Mapa centrado en", country$country_name)
  }

  change_metric <- function(metric) {
    if (!metric %in% names(metrics)) {
      stop("Métrica no disponible.")
    }

    map_metric(metric)
    paste("Coropleta actualizada a", metrics[[metric]]$label)
  }

  chat <- ellmer::chat_openai(
    model = Sys.getenv("OPENAI_MODEL", unset = "gpt-3.5-turbo"),
    system_prompt = system_prompt_text
  )

  chat$register_tool(tool(
    go_to_country,
    "Centra el mapa en un país.",
    arguments = list(
      country_name = type_string("Nombre del país en español o inglés."),
      zoom = type_number("Nivel de zoom, normalmente entre 2 y 8.", required = FALSE)
    )
  ))

  chat$register_tool(tool(
    show_country_report,
    "Centra el mapa y abre un informe de un país.",
    arguments = list(
      country_name = type_string("Nombre del país en español o inglés.")
    )
  ))

  chat$register_tool(tool(
    change_metric,
    "Cambia la variable de la coropleta.",
    arguments = list(
      metric = type_string(paste("Una de:", paste(names(metrics), collapse = ", ")))
    )
  ))

  shinychat::chat_mod_server(
    "chat",
    client = chat,
    greeting = greeting_text
  )
}

shinyApp(ui, server)
