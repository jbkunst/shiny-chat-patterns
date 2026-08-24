if (!requireNamespace("callr", quietly = TRUE)) {
  stop("Instala callr con install.packages(\"callr\").", call. = FALSE)
}

apps <- list.dirs(".", full.names = FALSE, recursive = FALSE)
apps <- apps[grepl("^app-[0-9]+$", apps) & file.exists(file.path(apps, "app.R"))]
apps <- apps[order(as.integer(sub("app-", "", apps)))]

if (!length(apps)) stop("No se encontraron carpetas app-* con un app.R.", call. = FALSE)

ports <- 8000L + seq_along(apps) - 1L

app_processes <- Map(
  function(app, port) {
    callr::r_bg(
      function(app, port) {
        shiny::runApp(app, host = "127.0.0.1", port = port, launch.browser = FALSE)
      },
      args = list(app = normalizePath(app), port = port),
      supervise = FALSE
    )
  },
  apps,
  ports
)

names(app_processes) <- apps
Sys.sleep(2)

urls <- sprintf("http://127.0.0.1:%d", ports)
invisible(lapply(urls, utils::browseURL))

stop_all_apps <- function() {
  invisible(lapply(app_processes, function(process) {
    if (process$is_alive()) process$kill()
  }))
}

data.frame(app = apps, port = ports, url = urls)
