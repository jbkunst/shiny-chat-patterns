library(shiny)
library(bslib)
library(shinychat)
library(ellmer)
library(dplyr)
library(datos)

# datos -------------------------------------------------------------------
datos::pinguinos

# función disponible ------------------------------------------------------
ajustar_regresion <- function(especie, x, y) {
  df <- datos::pinguinos |>
    filter(especie == !!especie) |>
    rename(x = !!x, y = !!y)
  modelo <- lm(y ~ x, data = df)
  resumen <- capture.output(summary(modelo))
  paste(resumen, collapse = "\n")
}

# Pruébala en R antes de conectarla al chat.
ajustar_regresion("Adelia", "largo_aleta_mm", "masa_corporal_g")

# user interface ----------------------------------------------------------
ui <- page_fillable(chat_ui("chat"), fillable_mobile = TRUE)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  chat <- ellmer::chat(
    "openai/gpt-5-nano",
    system_prompt = "Responde en español."
  )

  # TODO: registra ajustar_regresion como herramienta con los argumentos especie, x e y.

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
