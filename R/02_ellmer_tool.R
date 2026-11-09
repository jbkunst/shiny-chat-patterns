library(ellmer)
library(httr2)

# tools -------------------------------------------------------------------
consultar_pronostico <- function(ciudad, fecha) {
  lugares <- request("https://geocoding-api.open-meteo.com/v1/search") |>
    req_url_query(name = trimws(ciudad), count = 1, language = "es") |>
    req_perform() |>
    resp_body_json()
  lugar <- lugares$results[[1]]

  pronostico <- request("https://api.open-meteo.com/v1/forecast") |>
    req_url_query(
      latitude = lugar$latitude, longitude = lugar$longitude,
      daily = "temperature_2m_min,temperature_2m_max,precipitation_probability_max",
      timezone = "UTC", start_date = fecha, end_date = fecha
    ) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE)

  list(
    ciudad = lugar$name, region = lugar$admin1, pais = lugar$country, fecha = fecha,
    pronostico = pronostico$daily, unidades = pronostico$daily_units
  )
}

# prompt ------------------------------------------------------------------
fecha_ejemplo <- format(as.Date(format(Sys.time(), tz = "UTC")) + 1, "%Y-%m-%d")
pregunta <- sprintf("¿Lloverá en Madrid el %s? Indica también las temperaturas.", fecha_ejemplo)

# chat --------------------------------------------------------------------
# Prueba primero la función sin el modelo:
consultar_pronostico("Madrid", fecha_ejemplo)

chat <- ellmer::chat(
  "openai/gpt-5-nano",
  system_prompt = paste(
    "Responde en español. Usa consultar_pronostico; no inventes datos meteorológicos.",
    "Si no tienes una tool disponible para consultar el pronóstico, explica que no puedes obtenerlo."
  )
)

# Sin registrar la tool: el modelo no puede consultar la API.
chat$chat(pregunta)

# Ahora damos acceso a la función y describimos sus argumentos.
chat$register_tool(tool(
  consultar_pronostico,
  "Consulta el pronóstico de un día en una ciudad. Usa la primera coincidencia.",
  arguments = list(
    ciudad = type_string("Nombre de una ciudad, por ejemplo Madrid o Tokio."),
    fecha = type_string("Fecha AAAA-MM-DD, entre hoy y hoy + 15 días, UTC.")
  )
))

# Con la tool disponible: vuelve a pedir el pronóstico.
chat$chat(paste("Ahora consulta el pronóstico con la herramienta disponible.", pregunta))
