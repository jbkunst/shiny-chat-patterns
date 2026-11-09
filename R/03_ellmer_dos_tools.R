library(ellmer)
library(httr2)

# tools -------------------------------------------------------------------
consultar_pronostico <- function(ciudad, fecha) {
  if (length(ciudad) != 1L || is.na(ciudad) || !nzchar(trimws(ciudad))) {
    stop("Indica una ciudad.")
  }
  if (length(fecha) != 1L || is.na(fecha) || !grepl("^\\d{4}-\\d{2}-\\d{2}$", fecha)) {
    stop("Usa una fecha con formato AAAA-MM-DD.")
  }
  dia <- tryCatch(as.Date(fecha), error = function(e) NA)
  hoy <- as.Date(format(Sys.time(), tz = "UTC", format = "%Y-%m-%d"))
  if (is.na(dia) || dia < hoy || dia > hoy + 15) {
    stop("La fecha debe estar entre hoy y los próximos 15 días, UTC.")
  }

  lugares <- request("https://geocoding-api.open-meteo.com/v1/search") |>
    req_url_query(name = trimws(ciudad), count = 1, language = "es") |>
    req_timeout(20) |>
    req_perform() |>
    resp_body_json()
  if (is.null(lugares$results)) stop("No encontré esa ciudad.")
  lugar <- lugares$results[[1]]

  pronostico <- request("https://api.open-meteo.com/v1/forecast") |>
    req_url_query(
      latitude = lugar$latitude, longitude = lugar$longitude,
      daily = "temperature_2m_min,temperature_2m_max,precipitation_probability_max",
      timezone = "UTC", start_date = fecha, end_date = fecha
    ) |>
    req_timeout(20) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE)

  list(
    ciudad = lugar$name, region = lugar$admin1, pais = lugar$country, fecha = fecha,
    pronostico = pronostico$daily, unidades = pronostico$daily_units
  )
}

consultar_fecha_actual <- function() {
  list(
    fecha = format(Sys.time(), tz = "UTC", format = "%Y-%m-%d"),
    zona_horaria = "UTC"
  )
}

# prompt ------------------------------------------------------------------
fecha_ejemplo <- format(as.Date(format(Sys.time(), tz = "UTC")) + 1, "%Y-%m-%d")
pregunta <- "¿Lloverá en Madrid dentro de tres días? Indica también las temperaturas."

# chat --------------------------------------------------------------------
# Prueba primero la función sin el modelo:
consultar_pronostico("Madrid", fecha_ejemplo)

chat <- ellmer::chat(
  "openai/gpt-5-nano",
  system_prompt = paste(
    "Responde en español.",
    "Para fechas relativas, consulta primero consultar_fecha_actual y calcula la fecha.",
    "Después usa consultar_pronostico. No inventes datos meteorológicos.",
    "Si faltan tools, explica que no puedes obtener el pronóstico."
  )
)

# Sin registrar las tools: todavía no puede consultar la fecha ni el pronóstico.
chat$chat(pregunta)

# Ahora damos acceso a ambas funciones.
chat$register_tool(tool(
  consultar_pronostico,
  "Consulta el pronóstico de un día en una ciudad. Usa la primera coincidencia.",
  arguments = list(
    ciudad = type_string("Nombre de una ciudad, por ejemplo Madrid o Tokio."),
    fecha = type_string("Fecha AAAA-MM-DD, entre hoy y hoy + 15 días, UTC.")
  )
))

chat$register_tool(tool(
  consultar_fecha_actual,
  "Devuelve la fecha actual en UTC. Úsala para interpretar hoy, mañana o en N días."
))

# Con ambas tools: consulta la fecha actual y luego el pronóstico.
chat$chat(paste("Ahora usa las herramientas disponibles para responder.", pregunta))
