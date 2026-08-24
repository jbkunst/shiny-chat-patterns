library(datos)
library(ellmer)

# data --------------------------------------------------------------------
paises <- datos::paises |> subset(anio == max(anio)) |> dplyr::select(-anio)

# tool --------------------------------------------------------------------
resumir_continente <- function(continente) {
  indice <- match(tolower(continente), tolower(unique(paises$continente)))
  if (is.na(indice)) stop("Continente no disponible.")

  continente <- unique(paises$continente)[indice]
  df <- paises[paises$continente == continente, ]

  list(
    continente = continente,
    registros = nrow(df),
    poblacion_total = sum(df$poblacion),
    esperanza_promedio = round(mean(df$esperanza_de_vida), 1),
    pib_promedio = round(mean(df$pib_per_capita))
  )
}

# chat --------------------------------------------------------------------
chat <- chat_openai(
  model = "gpt-5-nano",
  system_prompt = paste(
    "Responde brevemente en español.",
    "Usa resumir_continente para toda pregunta sobre los datos y no inventes resultados."
  )
)

chat$register_tool(tool(
  resumir_continente,
  "Resume un continente usando los datos reales de Gapminder.",
  arguments = list(
    continente = type_enum(unique(as.character(paises$continente)), "Continente que se quiere resumir.")
  )
))

if (interactive()) live_console(chat)
