library(ellmer)

chat <- ellmer::chat(
  "openai/gpt-5-nano",
  system_prompt = paste(
    "Responde brevemente en español sobre los países de Gapminder en su último año.",
    "No inventes resultados numéricos."
  )
)

live_console(chat)
