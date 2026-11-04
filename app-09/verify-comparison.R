library(jsonlite)

# cache -------------------------------------------------------------------
cache <- read_json("data/comparacion.json")
stopifnot(length(cache$casos) == 1L)
for (caso in cache$casos) {
  stopifnot(length(caso$sin_mcp$llamadas) == 0L, length(caso$con_mcp$llamadas) > 0L)
}

# observations ------------------------------------------------------------
claves <- c("ESP.LUR.A", "ESP.U.PT.A")
for (caso in cache$casos) {
  consultas <- Filter(function(x) {
    x$nombre == "imf_query_dataset" && is.null(x$error) && x$resultado$key %in% claves
  }, caso$con_mcp$llamadas)
  stopifnot(length(consultas) > 0L)
  resultado <- consultas[[length(consultas)]]$resultado
  observacion <- Filter(function(x) x$time_period == "2025", resultado$observations)[[1]]
  escala <- as.numeric(resultado$series_attributes$scale)
  esperados <- c(observacion$value, observacion$value / 10^escala)

  texto <- caso$con_mcp$respuesta
  numeros <- regmatches(texto, gregexpr("[0-9]+(?:[.,][0-9]+)*", texto, perl = TRUE))[[1]]
  coincide <- vapply(numeros, function(numero) {
    partes <- strsplit(numero, "[.,]")[[1]]
    decimales <- if (length(partes) == 1L) 0L else nchar(tail(partes, 1))
    valor <- suppressWarnings(as.numeric(gsub(",", ".", numero, fixed = TRUE)))
    decimal <- any(abs(valor - round(esperados, decimales)) < 1e-6, na.rm = TRUE)
    entero <- as.numeric(gsub("[.,]", "", numero))
    agrupado <- length(partes) > 1L && all(nchar(partes[-1]) == 3L)
    decimal || (agrupado && any(abs(entero - round(esperados)) < 1e-6))
  }, logical(1))
  stopifnot(any(coincide), grepl("2025", texto, fixed = TRUE))
  stopifnot(grepl("%|porcentaje|por ciento", texto, ignore.case = TRUE))
  stopifnot(grepl("International Monetary Fund", resultado$source, fixed = TRUE))
}
cat("Caché verificada: país, indicador, año y cifras contrastados a la precisión mostrada.\n")
