library(mcptools)
library(jsonlite)
library(countrycode)

# source ------------------------------------------------------------------
anio <- 2007L
indicadores <- c(desempleo = "LUR", poblacion = "LP", pib_per_capita = "NGDPDPC")
tools <- mcptools::mcp_tools("mcp.json")
names(tools) <- vapply(tools, function(tool) tool@name, character(1))
bases <- tools$imf_list_databases(
  filter = "World Economic Outlook", include_vintages = FALSE, limit = 10L, offset = 0L
)
stopifnot(is.null(bases@error))
base <- Filter(function(x) x$id == "WEO", bases@value$dataflows)[[1]]

# observations ------------------------------------------------------------
respuestas <- lapply(indicadores, function(indicador) {
  resultado <- do.call(tools$imf_query_dataset, list(
    dataflow_id = base$id, agency_id = base$agency_id, version = base$version,
    key = paste0("*.", indicador, ".A"), start_period = as.character(anio), end_period = as.character(anio),
    last_n_observations = NULL, canvas_id = NULL, output_mode = "auto"
  ))
  if (!is.null(resultado@error)) stop(resultado@error)
  stopifnot(!resultado@value$staged, !resultado@value$truncated)
  resultado@value
})

# country snapshot --------------------------------------------------------
tablas <- lapply(names(respuestas), function(variable) {
  observaciones <- respuestas[[variable]]$observations
  tabla <- data.frame(
    codigo = vapply(observaciones, function(x) strsplit(x$series_key, ".", fixed = TRUE)[[1]][1], ""),
    valor = vapply(observaciones, function(x) x$value, numeric(1))
  )
  names(tabla)[2] <- variable
  tabla
})
paises <- Reduce(function(x, y) merge(x, y, by = "codigo"), tablas)
paises$pais <- countrycode(paises$codigo, "iso3c", "country.name.es", warn = FALSE)
paises$continente <- countrycode(paises$codigo, "iso3c", "continent", warn = FALSE)
continentes <- c(
  Africa = "África", Americas = "América", Asia = "Asia", Europe = "Europa", Oceania = "Oceanía"
)
paises$continente <- unname(continentes[paises$continente])
paises <- paises[complete.cases(paises) & paises$poblacion > 0 & paises$pib_per_capita > 0, ]
paises <- paises[order(paises$pais),
  c("pais", "continente", "desempleo", "poblacion", "pib_per_capita", "codigo")]
stopifnot(nrow(paises) > 0L, !anyDuplicated(paises$codigo))

# cache -------------------------------------------------------------------
cache <- list(
  recuperado_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%d %H:%M:%S UTC"),
  anio = anio, base = base, indicadores = as.list(indicadores),
  unidades = list(desempleo = "%", poblacion = "personas", pib_per_capita = "USD corrientes"),
  respuestas = respuestas
)
dir.create("data", showWarnings = FALSE)
write.csv(paises, "data/paises.csv", row.names = FALSE, fileEncoding = "UTF-8")
write_json(cache, "data/dashboard.json", auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
cat("Dashboard FMI guardado:", nrow(paises), "países con los tres indicadores en", anio, "\n")
