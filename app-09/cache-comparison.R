library(ellmer)
library(mcptools)
library(jsonlite)

# prompt ------------------------------------------------------------------
prompt <- paste(readLines("comparison-prompt.md", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
pregunta <- "¿Cuál fue la esperanza de vida al nacer en Colombia en 2023?"
modelo <- "gpt-5-nano"
if (!nzchar(Sys.getenv("OPENAI_API_KEY"))) stop("Falta OPENAI_API_KEY; la caché anterior se conserva.")

# tools -------------------------------------------------------------------
source("mcp-tools.R", local = TRUE, encoding = "UTF-8")

# comparison --------------------------------------------------------------
ejecutar <- function(usar_mcp) {
  chat <- ellmer::chat(
    paste0("openai/", modelo),
    system_prompt = prompt, params = params(max_tokens = 16384, reasoning_effort = "low")
  )
  if (usar_mcp) chat$set_tools(tools)
  respuesta <- as.character(chat$chat(pregunta, echo = "none"))

  llamadas <- list()
  for (turno in chat$get_turns()) {
    for (contenido in turno@contents) {
      if (!inherits(contenido, "ellmer::ContentToolResult")) next
      llamadas[[length(llamadas) + 1L]] <- list(
        nombre = contenido@request@name,
        argumentos = contenido@request@arguments,
        resultado = contenido@value,
        error = if (is.null(contenido@error)) NULL else as.character(contenido@error)
      )
    }
  }
  list(respuesta = respuesta, llamadas = llamadas)
}

sin_mcp <- ejecutar(FALSE)
con_mcp <- ejecutar(TRUE)
cache <- list(
  generado_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%d %H:%M:%S UTC"),
  modelo = modelo,
  parametros = params(max_tokens = 16384, reasoning_effort = "low"),
  endpoint = "https://worldbank.caseyjhand.com/mcp",
  fuente = "Banco Mundial · World Development Indicators",
  prompt = prompt,
  casos = list(list(pregunta = pregunta, sin_mcp = sin_mcp, con_mcp = con_mcp))
)

# validate before replacing the previous cache -----------------------------
temporal_json <- tempfile(fileext = ".json")
temporal_rds <- tempfile(fileext = ".rds")
write_json(cache, temporal_json, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
saveRDS(cache, temporal_rds)
source("verify-comparison.R", local = list2env(list(archivo_cache = temporal_json)), encoding = "UTF-8")
stopifnot(isTRUE(all.equal(read_json(temporal_json), readRDS(temporal_rds), check.attributes = FALSE)))

dir.create("data", showWarnings = FALSE)
stopifnot(file.copy(temporal_json, "data/comparacion.json", overwrite = TRUE))
stopifnot(file.copy(temporal_rds, "data/comparacion.rds", overwrite = TRUE))
unlink(c(temporal_json, temporal_rds))
cat("Comparación Banco Mundial guardada tras verificar las observaciones y la respuesta.\n")
