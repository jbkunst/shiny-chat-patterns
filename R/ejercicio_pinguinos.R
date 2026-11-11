library(datos)
library(ellmer)

# data --------------------------------------------------------------------
pinguinos <- datos::pinguinos
variables <- c("largo_pico_mm", "alto_pico_mm", "largo_aleta_mm", "masa_corporal_g")

# tools -------------------------------------------------------------------
ajustar_regresion <- function(especie, x, y) {
  df <- pinguinos[pinguinos$especie == especie, ]
  modelo <- lm(reformulate(x, response = y), data = df)
  paste(capture.output(summary(modelo)), collapse = "\n")
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
    especie = type_enum("Especie de pingüino.", values = levels(pinguinos$especie)),
    x = type_enum("Variable explicativa: pico y aleta en mm; masa corporal en g.", values = variables),
    y = type_enum("Variable respuesta: pico y aleta en mm; masa corporal en g.", values = variables)
  )
))

chat$chat(paste(
  "Para Adelia, ajusta la masa corporal según el largo de la aleta.",
  "Interpreta la pendiente y el R²."
))
