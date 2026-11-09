library(shiny)
library(shinychat)
library(ellmer)
library(mcptools)

# user interface ----------------------------------------------------------
ui <- page_chat("App 09 v2 · Conversar con herramientas MCP", sidebar = FALSE, allow_attachments = FALSE)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  chat <- chat_openai(
    model = "gpt-5.6-luna",
    system_prompt = paste(
      "Responde en español.",
      "Usa MCP para consultar datos; indica año, unidad y fuente.",
      "Resume los resultados y evita listar series largas completas."
    )
  )
  chat$set_tools(mcp_tools("mcp.json"))
  chat_server("chat", chat, history = FALSE)
}

shinyApp(ui, server)
