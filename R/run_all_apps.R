port_is_open <- function(port) {
  connection <- suppressWarnings(try(
    socketConnection("127.0.0.1", port, open = "r+", blocking = TRUE, timeout = 0.2),
    silent = TRUE
  ))
  if (inherits(connection, "try-error")) return(FALSE)
  close(connection)
  TRUE
}

url_is_ready <- function(url, apps = NULL) {
  response <- suppressWarnings(try(
    httr::GET(url, httr::timeout(1)),
    silent = TRUE
  ))
  if (inherits(response, "try-error") || httr::status_code(response) >= 400) return(FALSE)
  if (is.null(apps)) return(TRUE)
  html <- httr::content(response, as = "text", encoding = "UTF-8")
  ids <- regmatches(html, gregexpr('id="app-[^"]+"', html))[[1]]
  expected <- paste0('id="', apps$app, '"')
  setequal(ids, expected) && all(vapply(apps$url, grepl, logical(1), x = html, fixed = TRUE))
}

read_process_log <- function(process) {
  output <- c(process$read_output_lines(), process$read_error_lines())
  if (!length(output)) return("Sin salida del proceso.")
  paste(output, collapse = "\n")
}

wait_for_process <- function(process, url, label, timeout = 180, apps = NULL) {
  deadline <- Sys.time() + timeout
  while (Sys.time() < deadline) {
    if (!process$is_alive()) {
      stop(label, " terminó antes de responder.\n", read_process_log(process), call. = FALSE)
    }
    if (url_is_ready(url, apps)) return(invisible(TRUE))
    Sys.sleep(0.25)
  }
  problem <- if (is.null(apps)) " no respondió en " else " no mostró todas las apps en "
  stop(
    label, problem, url, " después de ", timeout, " segundos.\n",
    read_process_log(process),
    call. = FALSE
  )
}

stop_all_apps <- function(course, timeout = 10) {
  cli::cli_alert_info("Deteniendo apps y catálogo.")
  processes <- c(list(course$catalog_process), course$app_processes)
  for (process in processes) {
    if (is.null(process) || !process$is_alive()) next
    tryCatch(process$kill_tree(), error = function(error) {
      cli::cli_alert_warning("No se pudo detener un proceso: {conditionMessage(error)}")
    })
  }

  ports <- course$apps$port[course$apps$app %in% names(course$app_processes)]
  if (!is.null(course$catalog_process)) {
    ports <- c(ports, as.integer(sub(".*:", "", course$catalog_url)))
  }

  deadline <- Sys.time() + timeout
  repeat {
    alive <- vapply(processes, function(process) {
      !is.null(process) && process$is_alive()
    }, logical(1))
    occupied <- ports[vapply(ports, port_is_open, logical(1))]
    if (!any(alive) && !length(occupied)) break
    if (Sys.time() >= deadline) {
      details <- c(
        if (any(alive)) "quedaron procesos activos",
        if (length(occupied)) paste0("puertos ocupados: ", paste(occupied, collapse = ", "))
      )
      detail <- paste(details, collapse = "; ")
      cli::cli_abort("No fue posible detener todo: {detail}.")
    }
    Sys.sleep(0.2)
  }

  cli::cli_alert_success("Procesos detenidos y puertos liberados.")
  invisible(TRUE)
}

open_catalog <- function(course) {
  url <- course$catalog_url
  if (!url_is_ready(url, course$apps)) {
    stop("El catálogo no contiene la lista completa de apps en ", url, ".", call. = FALSE)
  }
  link <- cli::style_hyperlink(url, url)
  cli::cli_alert_info("Abriendo el catálogo: {link}")
  utils::browseURL(url)
  invisible(url)
}

plan_apps <- function(root, include_experimental = FALSE, first_app_port = 8000L) {
  directories <- list.dirs(root, full.names = FALSE, recursive = FALSE)
  stable <- directories[
    grepl("^app-[0-9]+(-[a-z0-9-]+)?$", directories) &
      !grepl("-experimental$", directories)
  ]
  experimental <- directories[grepl("^app-[0-9]+-experimental$", directories)]
  apps <- if (include_experimental) c(stable, experimental) else stable
  apps <- apps[file.exists(file.path(root, apps, "app.R"))]
  numbers <- as.integer(sub("^app-([0-9]+).*$", "\\1", apps))
  apps <- apps[order(grepl("-experimental$", apps), numbers)]

  if (!length(apps)) stop("No se encontraron apps R desde ", root, ".", call. = FALSE)

  ports <- first_app_port + seq_along(apps) - 1L
  descriptions <- lapply(apps, function(app) {
    path <- file.path(root, app)
    parse(file.path(path, "app.R"), encoding = "UTF-8")
    metadata <- read.dcf(file.path(path, "DESCRIPTION"))[1, ]
    fields <- c("Title", "Description")
    if (!all(fields %in% names(metadata)) || any(!nzchar(trimws(metadata[fields])))) {
      stop(app, " necesita Title y Description en DESCRIPTION.", call. = FALSE)
    }
    unname(metadata[fields])
  })
  data.frame(
    app = apps,
    port = ports,
    url = sprintf("http://127.0.0.1:%d", ports),
    title = vapply(descriptions, `[`, character(1), 1L),
    description = vapply(descriptions, `[`, character(1), 2L)
  )
}

run_all_apps <- function(
  include_experimental = FALSE,
  root = ".",
  first_app_port = 8000L,
  catalog_port = 7999L,
  startup_timeout = 180
) {
  for (package in c("callr", "processx", "cli", "httr", "yaml")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("Instala ", package, " con install.packages(\"", package, "\").", call. = FALSE)
    }
  }
  quarto <- Sys.which("quarto")
  if (!nzchar(quarto)) stop("Instala Quarto y asegúrate de que esté en PATH.", call. = FALSE)

  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  apps <- plan_apps(root, include_experimental, first_app_port)
  ports <- apps$port
  occupied <- ports[vapply(ports, port_is_open, logical(1))]
  if (length(occupied)) {
    stop("Estos puertos ya están ocupados: ", paste(occupied, collapse = ", "), ".", call. = FALSE)
  }
  requested_catalog_port <- catalog_port
  while (catalog_port %in% ports || port_is_open(catalog_port)) {
    catalog_port <- catalog_port + 1L
  }
  if (catalog_port != requested_catalog_port) {
    cli::cli_alert_warning(
      "El puerto {requested_catalog_port} está ocupado; se usará {catalog_port}."
    )
  }

  cli::cli_h1("Apps del taller")
  manifest <- file.path(root, "catalog", "apps.yml")
  items <- lapply(seq_len(nrow(apps)), function(index) as.list(apps[index, ]))
  yaml::write_yaml(list(items = items), manifest)
  cli::cli_alert_success("Plan guardado en catalog/apps.yml: {nrow(apps)} apps.")
  print(apps[c("app", "port", "title")], row.names = FALSE)
  apps <- do.call(rbind, lapply(yaml::read_yaml(manifest)$items, as.data.frame))
  cli::cli_alert_info("Iniciando {nrow(apps)} apps en procesos de fondo.")
  course <- list(
    apps = apps,
    app_processes = list(),
    catalog_process = NULL,
    catalog_url = sprintf("http://127.0.0.1:%d", catalog_port)
  )
  ready <- FALSE
  on.exit({
    if (!ready) stop_all_apps(course)
  }, add = TRUE)

  for (index in seq_len(nrow(apps))) {
    app <- apps$app[index]
    port <- apps$port[index]
    url <- apps$url[index]
    cli::cli_alert_info("Iniciando {.code {app}}.")
    process <- callr::r_bg(
      function(path, port) {
        if (.Platform$OS.type == "windows") invisible(Sys.setlocale("LC_CTYPE", ".UTF-8"))
        shiny::runApp(path, host = "127.0.0.1", port = port, launch.browser = FALSE)
      },
      args = list(path = file.path(root, app), port = port),
      stdout = "|",
      stderr = "|",
      supervise = TRUE
    )
    course$app_processes[[app]] <- process
    wait_for_process(process, url, app, startup_timeout)
    cli::cli_alert_success("{.code {app}} lista en {.url {url}}")
  }

  cli::cli_alert_info("Preparando el catálogo Quarto.")
  course$catalog_process <- processx::process$new(
    quarto,
    c("preview", "catalog", "--render", "html", "--host", "127.0.0.1",
      "--port", catalog_port, "--no-browser"),
    wd = root,
    stdout = "|",
    stderr = "|",
    cleanup = TRUE,
    cleanup_tree = TRUE
  )
  wait_for_process(course$catalog_process, course$catalog_url, "El catálogo Quarto", startup_timeout, apps)
  link <- cli::style_hyperlink(course$catalog_url, course$catalog_url)
  cli::cli_alert_success("Catálogo listo: {link}")
  cli::cli_inform("Para detener todo: {.code stop_all_apps(course)}")
  open_catalog(course)
  ready <- TRUE
  course
}

# launch ------------------------------------------------------------------
if (.Platform$OS.type == "windows") invisible(Sys.setlocale("LC_CTYPE", ".UTF-8"))
if (!nzchar(Sys.getenv("RENV_PROJECT"))) {
  source("renv/activate.R")
  cli::cli_alert_success("Entorno renv activado para el proyecto.")
} else {
  cli::cli_alert_info("El entorno renv ya está activo.")
}

if (
  exists("course", inherits = FALSE) &&
    is.list(course) &&
    all(c("app_processes", "catalog_process") %in% names(course))
) {
  stop_all_apps(course)
}
course <- run_all_apps()
