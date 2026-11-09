library(ellmer)
library(mcptools)

# chat --------------------------------------------------------------------
chat <- ellmer::chat(
  "openai/gpt-5.6-luna",
  system_prompt = "Responde en español. Consulta el MCP e indica país, año, valor, unidad y fuente."
)

# tools -------------------------------------------------------------------
chat$set_tools(mcp_tools("app-09-v2/mcp-imf.json"))

# conversation ------------------------------------------------------------
chat$chat("Según WEO del FMI, ¿cuál fue la tasa de desempleo de España en 2023?")

live_console(chat)
