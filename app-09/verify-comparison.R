library(jsonlite)

# cache -------------------------------------------------------------------
cache <- read_json("data/comparacion.json")
stopifnot(length(cache$casos) == 2L)
for (caso in cache$casos) {
  stopifnot(length(caso$sin_mcp$llamadas) == 0L, length(caso$con_mcp$llamadas) > 0L)
  stopifnot(all(vapply(caso$con_mcp$llamadas, function(x) is.null(x$error), logical(1))))
}

# metadata ----------------------------------------------------------------
caso <- cache$casos[[1]]
catalogo <- caso$con_mcp$llamadas[[1]]$resultado$dataflows
weo <- Filter(function(x) x$id == "WEO", catalogo)[[1]]
for (valor in c(weo$id, weo$agency_id, weo$version)) {
  stopifnot(grepl(valor, caso$con_mcp$respuesta, fixed = TRUE))
}

# observations ------------------------------------------------------------
caso <- cache$casos[[2]]
consultas <- Filter(function(x) x$nombre == "imf_query_dataset", caso$con_mcp$llamadas)
resultado <- consultas[[length(consultas)]]$resultado
stopifnot(resultado$key == "CHL.NGDP_RPCH.A", resultado$observation_count == 2L)
for (observacion in resultado$observations) {
  valor <- formatC(observacion$value, format = "f", digits = 3, decimal.mark = ".")
  stopifnot(grepl(observacion$time_period, caso$con_mcp$respuesta, fixed = TRUE))
  stopifnot(grepl(valor, caso$con_mcp$respuesta, fixed = TRUE))
}
stopifnot(grepl("International Monetary Fund", resultado$source, fixed = TRUE))
cat("Caché verificada: metadatos, años y valores contrastados con los resultados de las tools.\n")
