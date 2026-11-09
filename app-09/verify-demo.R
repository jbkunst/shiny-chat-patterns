library(shiny)
library(jsonlite)

# cached conversation -----------------------------------------------------
if (!exists("archivo_demo", inherits = FALSE)) archivo_demo <- "data/demo.json"
cache <- read_json(archivo_demo)
stopifnot(cache$endpoint == "https://worldbank.caseyjhand.com/mcp", cache$formato == "carga-unica")
stopifnot(length(cache$pasos) == 7L)
roles_anteriores <- c(varx = "x_var", vary = "y_var", varz = "size_var", varmapa = "map_var")
columna_actual <- function(x) unname(ifelse(x %in% names(roles_anteriores), roles_anteriores[x], x))

# actual app without the chat or an MCP connection -------------------------
app <- new.env()
expresiones <- parse("app.R", encoding = "UTF-8")
for (x in expresiones[-length(expresiones)]) eval(x, app)
pasos <- as.list(body(app$server))
inicio_chat <- which(vapply(pasos, function(x) {
  is.call(x) && identical(x[[1]], as.name("<-")) && identical(x[[2]], as.name("chat"))
}, logical(1)))
body(app$server) <- as.call(pasos[seq_len(inicio_chat - 1L)])
expresion_plot <- Filter(function(x) {
  is.call(x) && identical(x[[1]], as.name("<-")) && identical(x[[2]], quote(output$plot))
}, pasos)[[1]][[3]][[2]]
puntos <- NULL
app$ggplot <- function(data = NULL, mapping = ggplot2::aes(), ...) {
  puntos <<- list(datos = data, mapping = mapping)
  ggplot2::ggplot(data, mapping, ...)
}

shiny::testServer(app$server, {
  thematic::thematic_on(bg = "white", fg = "#202326", accent = "#0E4F5A", font = "sans")
  session$flushReact()
  stopifnot(output$n_paises == "0", output$n_variables == "0")
  stopifnot(!is.null(output$plot), is.null(puntos$datos))
  mapa <- fromJSON(output$map, simplifyVector = FALSE)
  stopifnot(length(mapa$x$layers) == 0L)
  consultas <- list()
  for (i in seq_along(cache$pasos)) {
    paso <- cache$pasos[[i]]
    anterior <- data()
    for (llamada in paso$llamadas) {
      if (!is.null(llamada$error)) next
      if (llamada$nombre == "worldbank_get_data") consultas[[length(consultas) + 1L]] <- llamada
      if (llamada$nombre == "guardar_datos") {
        args <- llamada$argumentos
        # Adapta en memoria la caché histórica; conserva el JSON de la ejecución real.
        args$datos <- lapply(args$datos, function(x) setNames(x, columna_actual(names(x))))
        args$variables <- lapply(args$variables, function(x) {
          x$columna <- columna_actual(x$columna)
          x
        })
        filas <- dplyr::bind_rows(args$datos)
        info <- dplyr::bind_rows(args$variables)
        stopifnot(all(info$columna %in% c("x_var", "y_var", "size_var", "color_var", "map_var")))
        stopifnot(all(nzchar(info$unidad)), all(nzchar(info$indicador)))
        for (j in seq_len(nrow(info))) {
          fuentes <- Filter(function(x) identical(x$resultado$indicator$id, info$indicador[j]), consultas)
          recibidos <- unlist(lapply(fuentes, function(x) x$resultado$data), recursive = FALSE)
          recibidos <- rev(Filter(function(x) !isTRUE(x$isAggregate) && !is.null(x$value), recibidos))
          claves <- vapply(recibidos, function(x) paste(x$countryIso3, x$date), "")
          valores <- vapply(recibidos, function(x) x$value, numeric(1))
          usados <- !is.na(filas[[info$columna[j]]])
          idx <- match(paste(filas$pais[usados], filas$anio[usados]), claves)
          stopifnot(!anyNA(idx))
          stopifnot(all(abs(filas[[info$columna[j]]][usados] - valores[idx]) <= 0.00005 + 1e-8))
        }
        do.call(guardar_datos, args)
        stopifnot(isTRUE(all.equal(data()$datos[names(filas)], filas)))
      }
      if (llamada$nombre == "ver_datos") stopifnot(identical(ver_datos(), data()))
      if (llamada$nombre == "configurar_grafico") do.call(configurar_grafico, llamada$argumentos)
    }
    session$flushReact()
    df <- data()$datos
    info <- data()$variables
    stopifnot(nrow(df) == if (i >= 6L) 1L else 3L)
    stopifnot(setequal(df$pais, if (i >= 6L) "CHL" else c("CHL", "PER", "COL")))
    stopifnot(output$n_paises == as.character(nrow(df)))
    stopifnot(output$n_variables == as.character(dplyr::n_distinct(info$indicador)))

    mapa <- fromJSON(output$map, simplifyVector = FALSE)
    stopifnot(length(mapa$x$layers) == 1L)
    features <- mapa$x$layers[[1]]$source$data$features
    esperados <- df$pais[!is.na(df$map_var) & df$pais %in% app$mundo$adm0_a3]
    stopifnot(setequal(vapply(features, function(x) x$properties$adm0_a3, ""), esperados))
    for (feature in features) {
      p <- feature$properties
      idx <- match(p$adm0_a3, df$pais)
      stopifnot(isTRUE(all.equal(p$map_var, unname(df$map_var[idx]))))
      stopifnot(grepl(as.character(df$anio[idx]), p$detalle, fixed = TRUE))
      stopifnot(grepl(info$unidad[info$columna == "map_var"], p$detalle, fixed = TRUE))
    }
    stopifnot(length(mapa$x$legend_html) > 0L)
    tabla <- output$table
    stopifnot(length(regmatches(tabla, gregexpr("<tr>", tabla, fixed = TRUE))[[1]]) == nrow(df) + 1L)

    if (i >= 2L) {
      imagen <- output$plot
      stopifnot(!is.null(imagen))
      stopifnot(identical(puntos$datos, df))
      stopifnot(identical(rlang::eval_tidy(puntos$mapping$x, puntos$datos), df$x_var))
      stopifnot(identical(rlang::eval_tidy(puntos$mapping$y, puntos$datos), df$y_var))
      stopifnot(identical(rlang::eval_tidy(puntos$mapping$size, puntos$datos), df$size_var))
      stopifnot(all(df$anio == if (i <= 3L) 2023L else 2022L))
    }
    nombres <- vapply(paso$llamadas, function(x) x$nombre, "")
    if (i %in% c(3L, 6L, 7L)) stopifnot(!"worldbank_get_data" %in% nombres)
    if (i == 5L || i == 7L) stopifnot(identical(data(), anterior), !"guardar_datos" %in% nombres)
    if (i == 3L) {
      stopifnot(identical(df$x_var, anterior$datos$x_var), identical(df$y_var, anterior$datos$y_var))
      stopifnot(identical(df$size_var, anterior$datos$size_var), identical(df$map_var, df$x_var))
    }
    if (i == 6L) stopifnot(identical(df, dplyr::filter(anterior$datos, pais == "CHL")))
    cat("Paso", i, "verificado:", paso$pregunta, "\n")
  }

  # Color independiente y escalas: los números guardados conservan la unidad original.
  original <- data()
  filas <- original$datos
  filas$color_var <- filas$y_var
  info <- original$variables
  color <- dplyr::filter(info, columna == "y_var")
  color$columna <- "color_var"
  info <- dplyr::bind_rows(info, color)
  como_filas <- function(x) lapply(seq_len(nrow(x)), function(i) as.list(x[i, ]))
  guardar_datos(como_filas(filas), como_filas(info))
  carga_guardada <- data()
  configurar_grafico(log = "x")
  stopifnot(identical(data(), carga_guardada))
  session$flushReact()
  imagen <- output$plot
  stopifnot(!is.null(imagen), identical(data()$datos, filas))
  stopifnot(identical(rlang::eval_tidy(puntos$mapping$colour, puntos$datos), filas$color_var))
  construido <- ggplot2::ggplot_build(isolate(eval(expresion_plot)))
  stopifnot(isTRUE(all.equal(construido$data[[1]]$x, log10(filas$x_var))))
  stopifnot(isTRUE(all.equal(construido$data[[1]]$y, filas$y_var)))
  stopifnot(identical(data()$datos$map_var, original$datos$map_var))
  configurar_grafico(log = "xy")
  session$flushReact()
  construido <- ggplot2::ggplot_build(isolate(eval(expresion_plot)))
  stopifnot(isTRUE(all.equal(construido$data[[1]]$y, log10(filas$y_var))))
  stopifnot(identical(data()$datos, filas))

  # El área es proporcional al valor; el log comprime el tamaño sin tocar los datos ni los ejes.
  filas_tamano <- filas[rep(1L, 3L), ]
  filas_tamano$size_var <- c(10, 100, 1000)
  guardar_datos(como_filas(filas_tamano), como_filas(info))
  configurar_grafico(log = "", tamano = "area")
  construido <- ggplot2::ggplot_build(isolate(eval(expresion_plot)))
  areas <- construido$data[[1]]$size ^ 2
  stopifnot(isTRUE(all.equal(areas / max(areas), c(0.01, 0.1, 1))))
  carga_guardada <- data()
  configurar_grafico(tamano = "log10")
  construido <- ggplot2::ggplot_build(isolate(eval(expresion_plot)))
  escala_size <- construido$plot$scales$get_scales("size")
  stopifnot(identical(escala_size$transform(c(10, 100, 1000)), c(1, 2, 3)))
  stopifnot(identical(data(), carga_guardada), identical(isolate(escala()), ""))
  configurar_grafico(tamano = "area")

  # X e Y bastan: tamaño fijo y color uniforme si no se solicitan esos papeles.
  xy <- filas[c("pais", "anio", "x_var", "y_var")]
  guardar_datos(como_filas(xy), como_filas(dplyr::filter(info, columna %in% c("x_var", "y_var"))))
  configurar_grafico(log = "")
  session$flushReact()
  imagen <- output$plot
  stopifnot(!is.null(imagen))
  construido <- ggplot2::ggplot_build(isolate(eval(expresion_plot)))
  stopifnot(all(construido$data[[1]]$colour == "#0E4F5A"), all(construido$data[[1]]$size == 3))
  cat("Canvas vacío, color, tamaño opcional y escalas x/xy verificados sin alterar valores.\n")
})
cat("Demo offline: carga única, cifras MCP, tabla, mapa sin países extra y puntos actuales correctos.\n")
