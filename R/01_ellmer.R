library(ellmer)

chat <- ellmer::chat_openai(
  model = "gpt-3.5-turbo",
  system_prompt = "Eres un bot muy alegre!"
  )

chat$chat("Saludame")