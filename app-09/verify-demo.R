library(shiny)
library(jsonlite)

# cached observations -----------------------------------------------------
if (!exists("archivo_demo", inherits = FALSE)) archivo_demo <- "data/demo-fmi.json"
cache <- read_json(archivo_demo)
stopifnot(cache$endpoint == "https://imf.caseyjhand.com/mcp", length(cache$pasos) == 3L)
stopifnot(cache$formato %in% c("fmi-crecimiento-inflacion", "fmi-xy"))

# actual app without chat or MCP ------------------------------------------
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

shiny::testServer(app$server, {
  thematic::thematic_on(bg = "white", fg = "#202326", accent = "#0E4F5A", font = "sans")
  session$flushReact()
  stopifnot(output$n_paises == "0", output$n_variables == "0", !is.null(output$plot))
  stopifnot(length(fromJSON(output$map, simplifyVector = FALSE)$x$layers) == 0L)
  consultas <- list()
  for (i in seq_along(cache$pasos)) {
    paso <- cache$pasos[[i]]
    for (llamada in paso$llamadas) {
      if (llamada$nombre == "imf_query_dataset" && is.null(llamada$error)) {
        consultas[[length(consultas) + 1L]] <- llamada
      }
    }
    args <- paso$carga
    if (cache$formato == "fmi-crecimiento-inflacion") {
      # Replay of the original trace: project its real observations to x/y without rewriting it.
      args$datos <- lapply(args$datos, function(fila) {
        list(pais = fila$pais, anio = fila$anio, x = fila$x_var, y = fila$map_var)
      })
      args$variables <- Filter(function(info) info$columna %in% c("x_var", "map_var"), args$variables)
      args$variables <- lapply(args$variables, function(info) {
        info$columna <- if (info$columna == "x_var") "x" else "y"
        info
      })
    }
    filas <- dplyr::bind_rows(filas_vacias, args$datos)
    info <- dplyr::bind_rows(args$variables)
    for (j in seq_len(nrow(info))) {
      observaciones <- unlist(lapply(consultas, function(x) x$resultado$observations), recursive = FALSE)
      observaciones <- rev(Filter(function(x) {
        strsplit(x$series_key, ".", fixed = TRUE)[[1]][2] == info$indicador[j] && !is.null(x$value)
      }, observaciones))
      claves <- vapply(observaciones, function(x) {
        paste(strsplit(x$series_key, ".", fixed = TRUE)[[1]][1], x$time_period)
      }, "")
      valores <- vapply(observaciones, function(x) x$value, numeric(1))
      usados <- !is.na(filas[[info$columna[j]]])
      idx <- match(paste(filas$pais[usados], filas$anio[usados]), claves)
      stopifnot(!anyNA(idx))
      stopifnot(all(abs(filas[[info$columna[j]]][usados] - valores[idx]) <= 0.00005 + 1e-8))
    }
    do.call(guardar_datos, args)
    session$flushReact()
    stopifnot(identical(names(data()$datos), c("pais", "anio", "x", "y")))
    stopifnot(isTRUE(all.equal(data()$datos, filas)), identical(ver_datos(), data()))
    stopifnot(output$n_paises == as.character(nrow(filas)))
    stopifnot(output$n_variables == as.character(dplyr::n_distinct(info$indicador)))
    stopifnot(all(filas$anio == if (i == 3L) 2020L else 2023L))
    mapa <- fromJSON(output$map, simplifyVector = FALSE)
    features <- mapa$x$layers[[1]]$source$data$features
    esperados <- filas$pais[!is.na(filas$y) & filas$pais %in% app$mundo$adm0_a3]
    stopifnot(setequal(vapply(features, function(x) x$properties$adm0_a3, ""), esperados))
    for (feature in features) {
      idx <- match(feature$properties$adm0_a3, filas$pais)
      stopifnot(isTRUE(all.equal(feature$properties$y, unname(filas$y[idx]))))
      stopifnot(grepl(info$unidad[info$columna == "y"], feature$properties$detalle, fixed = TRUE))
    }
    stopifnot(length(mapa$x$legend_html) > 0L, !is.null(output$plot))
    tabla <- output$table
    stopifnot(length(regmatches(tabla, gregexpr("<tr>", tabla, fixed = TRUE))[[1]]) == nrow(filas) + 1L)
    if (i >= 2L) {
      construido <- ggplot2::ggplot_build(isolate(eval(expresion_plot)))
      puntos <- dplyr::filter(filas, !is.na(x), !is.na(y))
      stopifnot(isTRUE(all.equal(construido$data[[1]]$x, puntos$x)))
      stopifnot(isTRUE(all.equal(construido$data[[1]]$y, puntos$y)))
      stopifnot(all(construido$data[[1]]$size == 3), all(construido$data[[1]]$colour == "#0E4F5A"))
      stopifnot(construido$plot$labels$y == paste(info$nombre[info$columna == "y"],
        info$unidad[info$columna == "y"], sep = " · "))
    }
    cat("Paso", i, "verificado: mapa(y), gráfico(x, y), tabla(x, y).\n")
  }
  # Missing x, a single country and replacement instead of accumulation.
  fila <- args$datos[[1]]
  fila$x <- NULL
  guardar_datos(list(fila), Filter(function(info) info$columna == "y", args$variables))
  session$flushReact()
  stopifnot(nrow(data()$datos) == 1L, all(is.na(data()$datos$x)), !is.null(output$plot))
  stopifnot(length(fromJSON(output$map, simplifyVector = FALSE)$x$layers) == 1L)
  if (cache$formato == "fmi-crecimiento-inflacion") {
    poblacion <- cache$pasos[[2]]$carga
    filas <- lapply(poblacion$datos, function(fila) {
      list(pais = fila$pais, anio = fila$anio, x = fila$x_var, y = fila$size_var)
    })
    info <- Filter(function(info) info$columna %in% c("x_var", "size_var"), poblacion$variables)
    info <- lapply(info, function(info) {
      info$columna <- if (info$columna == "x_var") "x" else "y"
      info
    })
    guardar_datos(filas, info)
    session$flushReact()
    construido <- ggplot2::ggplot_build(isolate(eval(expresion_plot)))
    stopifnot(isTRUE(all.equal(construido$data[[1]]$y, data()$datos$y)))
    mapa <- fromJSON(output$map, simplifyVector = FALSE)
    for (feature in mapa$x$layers[[1]]$source$data$features) {
      idx <- match(feature$properties$adm0_a3, data()$datos$pais)
      stopifnot(isTRUE(all.equal(feature$properties$y, unname(data()$datos$y[idx]))))
    }
    cat("Población por crecimiento: población en Y y en el mapa, verificado.\n")
  }
})
cat("Replay offline correcto: cifras MCP, columnas opcionales, mapa y gráfico comparten Y.\n")
