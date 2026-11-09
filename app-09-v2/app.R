library(shiny)
library(shinychat)
library(ellmer)
library(mcptools)

# user interface ----------------------------------------------------------
ui <- page_chat("App 09 v2 · Conversar con herramientas MCP FMI")

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  chat <- ellmer::chat(
    "openai/gpt-5.6-luna",
    system_prompt = paste(
      "Responde en español.",
      "Resume los resultados y evita listar series largas completas."
    )
  )
  chat$set_tools(mcp_tools("mcp-imf.json"))
  chat_server("chat", chat, history = FALSE)
}

shinyApp(ui, server)
