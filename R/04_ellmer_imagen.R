library(ellmer)

# tools -------------------------------------------------------------------
mostrar_puntos <- function() {
  puntos <- data.frame(x = runif(24, -3, 3))
  puntos$y <- switch(sample(c("grupos", "tendencia", "curva", "aislado"), 1),
    grupos = rep(c(-2, 2), each = 12) + rnorm(24, sd = 0.3),
    tendencia = sample(c(-1, 1), 1) * puntos$x + rnorm(24, sd = 0.3),
    curva = puntos$x^2 + rnorm(24, sd = 0.3),
    aislado = c(rnorm(23), 6)
  )
  puntos <- puntos[sample(nrow(puntos)), ]
  puntos$nombre <- LETTERS[seq_len(nrow(puntos))]

  dibujar <- function() {
    plot(
      puntos$x, puntos$y, pch = 19, col = "#0E4F5A",
      xlim = range(puntos$x) + c(-0.5, 0.5), ylim = range(puntos$y) + c(-0.5, 0.5),
      xlab = "X", ylab = "Y", main = "¿Qué patrón ves?"
    )
    text(puntos$x, puntos$y, labels = puntos$nombre, pos = 3)
  }

  if (interactive()) dibujar()

  archivo <- tempfile(fileext = ".png")
  png(archivo, width = 700, height = 500)
  tryCatch(dibujar(), finally = dev.off())
  on.exit(unlink(archivo))
  list(
    ContentText("Gráfico generado. Analiza la imagen adjunta y responde."),
    content_image_file(archivo, resize = "none")
  )
}

# prompt ------------------------------------------------------------------
pregunta <- "Genera un gráfico y describe lo que ves. Identifica patrones y puntos que llamen la atención."

# chat --------------------------------------------------------------------
# Prueba la función y revisa el objeto de imagen sin llamar al modelo.
resultado <- mostrar_puntos()
lapply(resultado, class)
str(resultado, max.level = 1)

chat <- ellmer::chat(
  "openai/gpt-5.6-luna",
  system_prompt = paste(
    "No describas ningún gráfico sin recibir su imagen mediante mostrar_puntos.",
    "Cada petición de un gráfico nuevo requiere una nueva llamada a mostrar_puntos.",
    "Tras recibir la imagen, descríbela y responde sin llamar otra vez a la tool para esa petición.",
    "Responde brevemente en español; si no tienes la tool, di que no puedes observar el gráfico."
  )
)

chat$chat(pregunta)

chat$register_tool(tool(
  mostrar_puntos,
  "Genera y devuelve un gráfico de puntos con un patrón aleatorio y letras."
))

chat$chat(paste("Ahora usa la herramienta disponible.", pregunta))

chat$chat("Genera otro gráfico y describe lo que ves.")
