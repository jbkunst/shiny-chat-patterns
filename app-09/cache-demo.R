library(shiny)
library(jsonlite)

# actual app --------------------------------------------------------------
if (!nzchar(Sys.getenv("OPENAI_API_KEY"))) stop("Falta OPENAI_API_KEY; la caché anterior se conserva.")
app <- new.env()
expresiones <- parse("app.R", encoding = "UTF-8")
for (x in expresiones[-length(expresiones)]) eval(x, app)
temporal <- tempfile(fileext = ".json")
preguntas <- c(
  "Colorea el mapa con el último dato disponible de esperanza de vida de Chile, Perú y Colombia.",
  paste(
    "Para Chile, Perú y Colombia en 2023, muestra una dispersión con PIB por habitante en USD",
    "corrientes en X, esperanza de vida en Y y población como tamaño. Colorea el mapa por esperanza de vida."
  ),
  "Colorea ahora el mapa por el PIB por habitante ya cargado. Conserva la dispersión sin descargar otra vez.",
  "Descarga esas tres variables para 2022 y actualiza toda la vista. Colorea el mapa por PIB por habitante.",
  "Quiero una serie temporal de la esperanza de vida de Chile entre 2015 y 2023.",
  "Deja solo Chile en toda la vista, reutilizando la carga actual sin descargar otra vez.",
  "Usa ver_datos para decirme qué países, variables y año hay cargados, sin modificar nada."
)

# real conversation -------------------------------------------------------
shiny::testServer(app$server, {
  capturar <- function() {
    llamadas <- list()
    for (turno in chat$get_turns()) {
      for (contenido in turno@contents) {
        if (!inherits(contenido, "ellmer::ContentToolResult")) next
        llamadas[[length(llamadas) + 1L]] <- list(
          nombre = contenido@request@name, argumentos = contenido@request@arguments,
          resultado = contenido@value,
          error = if (is.null(contenido@error)) NULL else as.character(contenido@error)
        )
      }
    }
    llamadas
  }
  pasos <- lapply(preguntas, function(pregunta) {
    inicio <- length(capturar())
    respuesta <- as.character(chat$chat(pregunta, echo = "none"))
    session$flushReact()
    nuevas <- capturar()
    nuevas <- if (length(nuevas) > inicio) nuevas[seq.int(inicio + 1L, length(nuevas))] else list()
    cat("Pregunta:", pregunta, "\nRespuesta:", respuesta, "\n")
    list(
      pregunta = pregunta, respuesta = respuesta, llamadas = nuevas,
      carga = isolate(data())
    )
  })
  cache <- list(
    generado_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%d %H:%M:%S UTC"),
    formato = "carga-unica", endpoint = "https://worldbank.caseyjhand.com/mcp",
    modelo = chat$get_model(), pasos = pasos
  )
  write_json(cache, temporal, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
})
# publish only after the offline check ------------------------------------
source("verify-demo.R", local = list2env(list(archivo_demo = temporal)), encoding = "UTF-8")
stopifnot(file.copy(temporal, "data/demo.json", overwrite = TRUE))
unlink(temporal)
cat("Demo real guardada: carga única, mapa, dispersión, fechas y reutilización.\n")
