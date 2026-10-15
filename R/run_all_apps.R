port_is_open <- function(port) {
  connection <- suppressWarnings(try(
    socketConnection("127.0.0.1", port, open = "r+", blocking = TRUE, timeout = 0.2),
    silent = TRUE
  ))
  if (inherits(connection, "try-error")) return(FALSE)
  close(connection)
  TRUE
}

url_is_ready <- function(url) {
  response <- suppressWarnings(try(
    httr::GET(url, httr::timeout(1)),
    silent = TRUE
  ))
  !inherits(response, "try-error") && httr::status_code(response) < 400
}

read_process_log <- function(process) {
  output <- c(process$read_output_lines(), process$read_error_lines())
  if (!length(output)) return("Sin salida del proceso.")
  paste(output, collapse = "\n")
}

wait_for_process <- function(process, url, label, timeout = 180) {
  deadline <- Sys.time() + timeout
  while (Sys.time() < deadline) {
    if (!process$is_alive()) {
      stop(label, " terminó antes de responder.\n", read_process_log(process), call. = FALSE)
    }
    if (url_is_ready(url)) return(invisible(TRUE))
    Sys.sleep(0.25)
  }
  stop(
    label, " no respondió en ", url, " después de ", timeout, " segundos.\n",
    read_process_log(process),
    call. = FALSE
  )
}

stop_all_apps <- function(course, timeout = 10) {
  cli::cli_alert_info("Deteniendo apps y catálogo.")
  processes <- c(list(course$catalog_process), course$app_processes)
  invisible(lapply(processes, function(process) {
    if (!is.null(process) && process$is_alive()) process$kill_tree()
  }))

  deadline <- Sys.time() + timeout
  repeat {
    alive <- vapply(processes, function(process) {
      !is.null(process) && process$is_alive()
    }, logical(1))
    ports <- course$apps$port
    if (!is.null(course$catalog_url)) {
      ports <- c(ports, as.integer(sub(".*:", "", course$catalog_url)))
    }
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
  if (!url_is_ready(url)) {
    stop("El catálogo no está respondiendo en ", url, ".", call. = FALSE)
  }
  link <- cli::style_hyperlink(url, url)
  cli::cli_alert_info("Abriendo el catálogo: {link}")
  utils::browseURL(url)
  invisible(url)
}

run_all_apps <- function(
  include_experimental = FALSE,
  root = ".",
  first_app_port = 8000L,
  catalog_port = 7999L,
  startup_timeout = 180
) {
  if (!requireNamespace("callr", quietly = TRUE)) {
    stop("Instala callr con install.packages(\"callr\").", call. = FALSE)
  }
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop("Instala processx con install.packages(\"processx\").", call. = FALSE)
  }
  if (!requireNamespace("cli", quietly = TRUE)) {
    stop("Instala cli con install.packages(\"cli\").", call. = FALSE)
  }
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Instala httr con install.packages(\"httr\").", call. = FALSE)
  }
  quarto <- Sys.which("quarto")
  if (!nzchar(quarto)) stop("Instala Quarto y asegúrate de que esté en PATH.", call. = FALSE)

  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
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
  cli::cli_alert_info("Iniciando {length(apps)} apps en procesos de fondo.")
  app_processes <- list()
  catalog_process <- NULL
  ready <- FALSE
  on.exit({
    if (!ready) stop_all_apps(list(
      app_processes = app_processes,
      catalog_process = catalog_process
    ))
  }, add = TRUE)

  for (index in seq_along(apps)) {
    app <- apps[index]
    port <- ports[index]
    url <- sprintf("http://127.0.0.1:%d", port)
    cli::cli_alert_info("Iniciando {.code {app}}.")
    process <- callr::r_bg(
      function(path, port) {
        shiny::runApp(path, host = "127.0.0.1", port = port, launch.browser = FALSE)
      },
      args = list(path = file.path(root, app), port = port),
      stdout = "|",
      stderr = "|",
      supervise = TRUE
    )
    app_processes[[app]] <- process
    wait_for_process(process, url, app, startup_timeout)
    cli::cli_alert_success("{.code {app}} lista en {.url {url}}")
  }

  cli::cli_alert_info("Preparando el catálogo Quarto.")
  catalog_env <- Sys.getenv()
  catalog_env[c("SHINY_APP_ROOT", "SHINY_APP_NAMES", "SHINY_APP_PORTS")] <- c(
    root,
    paste(apps, collapse = ";"),
    paste(ports, collapse = ";")
  )
  catalog_process <- processx::process$new(
    quarto,
    c("preview", "catalog", "--host", "127.0.0.1", "--port", catalog_port, "--no-browser"),
    wd = root,
    env = catalog_env,
    stdout = "|",
    stderr = "|",
    cleanup = TRUE,
    cleanup_tree = TRUE
  )
  catalog_url <- sprintf("http://127.0.0.1:%d", catalog_port)
  wait_for_process(catalog_process, catalog_url, "El catálogo Quarto", startup_timeout)
  ready <- TRUE

  result <- list(
    apps = data.frame(app = apps, port = ports, url = sprintf("http://127.0.0.1:%d", ports)),
    app_processes = app_processes,
    catalog_process = catalog_process,
    catalog_url = catalog_url
  )
  link <- cli::style_hyperlink(catalog_url, catalog_url)
  cli::cli_alert_success("Catálogo listo: {link}")
  cli::cli_inform("Para detener todo: {.code stop_all_apps(course)}")
  open_catalog(result)
  result
}

# launch ------------------------------------------------------------------
if (
  exists("course", inherits = FALSE) &&
    is.list(course) &&
    all(c("app_processes", "catalog_process") %in% names(course))
) {
  stop_all_apps(course)
}
course <- run_all_apps()
