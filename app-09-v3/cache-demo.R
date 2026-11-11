library(shiny)
library(jsonlite)

# actual app --------------------------------------------------------------
if (!nzchar(Sys.getenv("OPENAI_API_KEY"))) stop("Falta OPENAI_API_KEY; la caché anterior se conserva.")
app <- new.env()
expresiones <- parse("app.R", encoding = "UTF-8")
for (x in expresiones[-length(expresiones)]) eval(x, app)
temporal <- "data/demo-fmi.pending.json"
preguntas <- c(
  "Colorea los países de América Latina según su inflación promedio anual en 2023.",
  paste(
    "Ahora agrega un gráfico con crecimiento real del PIB en X, inflación en Y y población como tamaño.",
    "Conserva el mapa."
  ),
  "Ahora consulta las mismas variables para 2020 y actualiza la vista."
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
    formato = "fmi-crecimiento-inflacion", endpoint = "https://imf.caseyjhand.com/mcp",
    modelo = chat$get_model(), pasos = pasos
  )
  write_json(cache, temporal, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
})
# publish only after the offline check ------------------------------------
source("verify-demo.R", local = list2env(list(archivo_demo = temporal)), encoding = "UTF-8")
stopifnot(file.copy(temporal, "data/demo-fmi.json", overwrite = TRUE))
unlink(temporal)
cat("Demo FMI guardada: inflación, crecimiento, población y cambio de año.\n")
