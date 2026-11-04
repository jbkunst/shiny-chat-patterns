library(commons)

# data --------------------------------------------------------------------
# Datos ficticios: cuatro meses para cada region.
ventas <- data.frame(
  region = rep(c("Norte", "Centro", "Sur"), each = 4),
  mes = rep(c("enero", "febrero", "marzo", "abril"), times = 3),
  unidades = c(100, 120, 110, 150, 80, 90, 95, 100, 60, 85, 80, 120)
)

# trusted calculation -----------------------------------------------------
capa <- semantic_layer(
  measure(
    "total_unidades_region",
    "Calcula el total de unidades vendidas de una region en toda la tabla ventas.",
    function(region, datos) {
      DBI::dbGetQuery(
        datos,
        "SELECT SUM(unidades) AS total_unidades FROM ventas WHERE LOWER(region) = LOWER(?)",
        params = list(region)
      )
    },
    arguments = list(
      region = ellmer::type_string("Region: Norte, Centro o Sur.")
    )
  )
)

# agent -------------------------------------------------------------------
agente <- commons(
  client = ellmer::chat_openai(model = "gpt-5-nano"),
  data_sources = list(datos = data_source(ventas = ventas)),
  semantic_layer = capa,
  instructions = "Responde en espanol, brevemente, usando solo los datos disponibles."
)

# shiny -------------------------------------------------------------------
commons_app(agente)
