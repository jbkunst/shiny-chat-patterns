library(ellmer)

# tools -------------------------------------------------------------------
mostrar_puntos <- function() {
  puntos <- data.frame(x = rnorm(12), y = rnorm(12))
  puntos[12, ] <- runif(2, min = 4, max = 6)
  puntos <- puntos[sample(nrow(puntos)), ]
  puntos$nombre <- LETTERS[seq_len(nrow(puntos))]

  dibujar <- function() {
    plot(
      puntos$x, puntos$y, pch = 19, col = "#0E4F5A",
      xlim = range(puntos$x) + c(-0.5, 0.5), ylim = range(puntos$y) + c(-0.5, 0.5),
      xlab = "X", ylab = "Y", main = "¿Qué punto se separa del grupo?"
    )
    text(puntos$x, puntos$y, labels = puntos$nombre, pos = 3)
  }

  if (interactive()) dibujar()

  archivo <- tempfile(fileext = ".png")
  png(archivo, width = 700, height = 500)
  tryCatch(dibujar(), finally = dev.off())
  on.exit(unlink(archivo))
  content_image_file(archivo, resize = "none")
}

# prompt ------------------------------------------------------------------
pregunta <- "Genera un gráfico e identifica el punto más separado del grupo. Explica por qué."

# chat --------------------------------------------------------------------
# Prueba la función y revisa el objeto de imagen sin llamar al modelo.
resultado <- mostrar_puntos()
class(resultado)
str(resultado, max.level = 1)

chat <- chat_openai(
  model = "gpt-5-nano",
  system_prompt = paste(
    "Responde brevemente en español. Usa mostrar_puntos para observar el gráfico.",
    "Si no tienes la tool disponible, explica que no puedes observar los puntos."
  )
)

chat$chat(pregunta)

chat$register_tool(tool(
  mostrar_puntos,
  "Genera y devuelve un gráfico aleatorio con puntos identificados por letras."
))

chat$chat(paste("Ahora usa la herramienta disponible.", pregunta))
