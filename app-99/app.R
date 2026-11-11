library(shiny)
library(bslib)
library(shinychat)
library(ellmer)
library(dplyr)
library(datos)

# tools -------------------------------------------------------------------
ajustar_regresion <- function(especie, x, y) {
  df <- datos::pinguinos |>
    filter(especie == !!especie) |>
    rename(x = !!x, y = !!y)
  modelo <- lm(y ~ x, data = df)
  resumen <- capture.output(summary(modelo))
  paste(resumen, collapse = "\n")
}

# user interface ----------------------------------------------------------
ui <- page_fillable(
  chat_ui("chat", greeting = "Pregunta por una regresión para una especie de pingüino."),
  fillable_mobile = TRUE
)

# server ------------------------------------------------------------------
server <- function(input, output, session) {
  # chat ------------------------------------------------------------------
  chat <- ellmer::chat(
    "openai/gpt-5-nano",
    system_prompt = paste(
      "Responde en español. Usa ajustar_regresion para calcular regresiones con pingüinos.",
      "Interpreta el resumen recibido: pendiente con sus unidades, R² y observaciones utilizadas.",
      "No inventes resultados ni interpretes la asociación como causalidad."
    )
  )

  chat$register_tool(tool(
    ajustar_regresion,
    "Ajusta Y ~ X para una especie y devuelve summary(lm) como texto.",
    arguments = list(
      especie = type_string("Especie: Adelia, Barbijo o Papúa."),
      x = type_string("X: largo_pico_mm, alto_pico_mm, largo_aleta_mm o masa_corporal_g."),
      y = type_string("Y: largo_pico_mm, alto_pico_mm, largo_aleta_mm o masa_corporal_g.")
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(!!!input$chat_user_input, stream = "content")
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
