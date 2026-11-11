library(datos)
library(ellmer)
library(dplyr)

# data --------------------------------------------------------------------
pinguinos <- datos::pinguinos

# tools -------------------------------------------------------------------
ajustar_regresion <- function(especie, x, y) {
  df <- pinguinos |>
    filter(especie == !!especie) |>
    rename(x = !!x, y = !!y)
  modelo <- lm(y ~ x, data = df)
  resumen <- capture.output(summary(modelo))
  paste(resumen, collapse = "\n")
}

# Comprueba el resultado en R antes de registrarlo como tool.
cat(ajustar_regresion("Adelia", "largo_aleta_mm", "masa_corporal_g"))

# chat --------------------------------------------------------------------
chat <- ellmer::chat(
  "openai/gpt-5-nano",
  system_prompt = paste(
    "Responde en español. Usa ajustar_regresion para calcular regresiones con pingüinos.",
    "Interpreta el summary recibido: pendiente con sus unidades, R² y observaciones utilizadas.",
    "No inventes resultados ni interpretes la asociación como causalidad. No generes gráficos."
  )
)

chat$register_tool(tool(
  ajustar_regresion,
  "Ajusta una regresión lineal Y ~ X para una especie y devuelve summary(lm) como texto.",
  arguments = list(
    especie = type_string("Especie: Adelia, Barbijo o Papúa."),
    x = type_string("X: largo_pico_mm, alto_pico_mm, largo_aleta_mm o masa_corporal_g."),
    y = type_string("Y: largo_pico_mm, alto_pico_mm, largo_aleta_mm o masa_corporal_g.")
  )
))

chat$chat(paste(
  "Para Adelia, ajusta la masa corporal según el largo de la aleta.",
  "Interpreta la pendiente y el R²."
))
