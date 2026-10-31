library(ellmer)
library(mcptools)
library(jsonlite)

# prompt ------------------------------------------------------------------
prompt <- paste(readLines("comparison-prompt.md", warn = FALSE), collapse = "\n")
preguntas <- c(
  "Según el FMI, ¿cuánta población tenía Chile en 2025?",
  "Según el FMI, ¿cuál fue la tasa de desempleo de España en 2025?"
)

# tools -------------------------------------------------------------------
tools <- mcptools::mcp_tools("mcp.json")

# comparison --------------------------------------------------------------
ejecutar <- function(pregunta, usar_mcp) {
  chat <- chat_openai(model = "gpt-5-nano", system_prompt = prompt)
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

casos <- lapply(preguntas, function(pregunta) {
  cat("Comparando:", pregunta, "\n")
  sin_mcp <- ejecutar(pregunta, FALSE)
  con_mcp <- ejecutar(pregunta, TRUE)
  stopifnot(length(sin_mcp$llamadas) == 0L, length(con_mcp$llamadas) > 0L)
  list(pregunta = pregunta, sin_mcp = sin_mcp, con_mcp = con_mcp)
})

cache <- list(
  generado_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%d %H:%M:%S UTC"),
  modelo = "gpt-5-nano",
  endpoint = "https://imf.caseyjhand.com/mcp",
  prompt = prompt,
  casos = casos
)
dir.create("data", showWarnings = FALSE)
saveRDS(cache, "data/comparacion.rds")
write_json(cache, "data/comparacion.json", auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
cat("Comparación guardada en data/comparacion.json. Revisa las respuestas y sus llamadas.\n")
source("verify-comparison.R", encoding = "UTF-8")
