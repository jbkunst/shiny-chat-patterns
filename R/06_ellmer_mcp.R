library(ellmer)
library(mcptools)

# tools -------------------------------------------------------------------
tools <- mcp_tools("app-09/mcp.json")
tools <- Filter(function(x) x@name %in% c(
  "worldbank_search_indicators", "worldbank_get_indicator", "worldbank_get_data"
), tools)
names(tools) <- vapply(tools, function(x) x@name, "")

# Conserva los argumentos del taller: la unión opcional de frequency falla con este cliente/modelo.
tools$worldbank_get_data@arguments@properties <- tools$worldbank_get_data@arguments@properties[
  c("indicator_id", "countries", "date_range", "mrnev", "page", "per_page")
]

# chat --------------------------------------------------------------------
chat <- chat_openai(
  model = "gpt-5.6-luna",
  system_prompt = "Responde en español. Consulta el MCP e indica país, año, valor, unidad y fuente."
)

chat$set_tools(tools)

# conversation ------------------------------------------------------------
chat$chat("¿Cuál fue la esperanza de vida al nacer en Colombia en 2023?")
