library(jsonlite)

# cache -------------------------------------------------------------------
if (!exists("archivo_cache", inherits = FALSE)) archivo_cache <- "data/comparacion.json"
cache <- read_json(archivo_cache)
stopifnot(
  cache$endpoint == "https://worldbank.caseyjhand.com/mcp",
  length(cache$casos) == 1L,
  nzchar(cache$modelo), nzchar(cache$prompt)
)
caso <- cache$casos[[1]]
stopifnot(
  caso$pregunta == "¿Cuál fue la esperanza de vida al nacer en Colombia en 2023?",
  length(caso$sin_mcp$llamadas) == 0L,
  length(caso$con_mcp$llamadas) > 0L
)

# observations ------------------------------------------------------------
consultas <- Filter(function(x) {
  x$nombre == "worldbank_get_data" && is.null(x$error) &&
    identical(x$argumentos$indicator_id, "SP.DYN.LE00.IN") &&
    identical(x$resultado$indicator$id, "SP.DYN.LE00.IN")
}, caso$con_mcp$llamadas)
stopifnot(length(consultas) > 0L)
observaciones <- unlist(lapply(consultas, function(x) x$resultado$data), recursive = FALSE)
observaciones <- Filter(function(x) {
  identical(x$countryIso3, "COL") && identical(x$countryName, "Colombia") &&
    identical(x$date, "2023") && !is.null(x$value) && !isTRUE(x$isAggregate)
}, observaciones)
stopifnot(length(observaciones) > 0L)
esperados <- unique(vapply(observaciones, function(x) x$value, numeric(1)))
stopifnot(length(esperados) == 1L, is.finite(esperados), esperados > 0)

# unit and answer ---------------------------------------------------------
# WDI devuelve unit vacío: la unidad original está en el nombre "(years)".
stopifnot(any(vapply(consultas, function(x) {
  grepl("Life expectancy at birth, total", x$resultado$indicator$name, fixed = TRUE) &&
    grepl("(years)", x$resultado$indicator$name, fixed = TRUE) &&
    identical(x$resultado$sourceId, "2")
}, logical(1))))

texto <- gsub("*", "", caso$con_mcp$respuesta, fixed = TRUE)
stopifnot(
  grepl("\\bColombia\\b", texto),
  grepl("\\b2023\\b", texto),
  grepl("años|years", texto, ignore.case = TRUE),
  grepl("Banco Mundial|World Bank|WDI|World Development Indicators", texto, ignore.case = TRUE)
)
cifras <- regmatches(texto, gregexpr("[0-9]+(?:[.,][0-9]+)?", texto, perl = TRUE))[[1]]
coincide <- vapply(cifras, function(cifra) {
  partes <- strsplit(cifra, "[.,]")[[1]]
  decimales <- if (length(partes) == 1L) 0L else nchar(partes[2])
  valor <- as.numeric(sub(",", ".", cifra, fixed = TRUE))
  abs(valor - esperados) <= 0.5 * 10^(-decimales) + 1e-10
}, logical(1))
stopifnot(any(coincide))
cat("Caché Banco Mundial verificada: Colombia, SP.DYN.LE00.IN, 2023, años y cifra a su precisión.\n")
