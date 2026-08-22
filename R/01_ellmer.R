library(ellmer)

chat <- ellmer::chat_openai(
  model = "gpt-5-nano",
  system_prompt = "Eres un bot muy alegre."
)

chat$chat("Salúdame")

chat$chat("¿Cuánto es 2 elevado a 4?")

live_console(chat)
