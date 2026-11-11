# Ejecuta desde la carpeta extraída del ZIP de GitHub, antes de cargar paquetes.
local({
  if (!file.exists("renv.lock") || !dir.exists("app-00")) {
    stop("Abre shiny-chat-patterns.Rproj y ejecuta instalar.R desde la raíz del proyecto.")
  }
  if (getRversion() < "4.6.1") stop("Instala R 4.6.1 o posterior antes de continuar.")

  # Esta copia usa la biblioteca habitual de R, sin activar renv al reiniciar.
  if (!file.exists(".Renviron")) file.copy(".Renviron.example", ".Renviron")
  entorno <- readLines(".Renviron", warn = FALSE)
  entorno <- entorno[!grepl("^\\s*RENV_CONFIG_AUTOLOADER_ENABLED\\s*=", entorno)]
  writeLines(c(entorno, "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE"), ".Renviron")
  Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
  if (nzchar(Sys.getenv("RENV_PROJECT"))) {
    stop("Reinicia R (Session > Restart R) y vuelve a ejecutar instalar.R; la instalación aún no comenzó.")
  }

  paquetes <- c(
    "brand.yml", "bslib", "countrycode", "DBI", "dplyr", "duckdb", "ellmer", "forecast",
    "gapminder", "ggplot2", "httr", "httr2", "jsonlite", "mapgl", "ragg", "readr",
    "remotes", "rnaturalearthdata", "sf", "shiny", "shinychat", "stringr", "thematic",
    "tinyplot", "xml2"
  )
  utils::install.packages(paquetes, repos = "https://cloud.r-project.org")
  faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
  if (length(faltantes)) stop("Faltó instalar: ", paste(faltantes, collapse = ", "))

  # Única dependencia del recorrido que requiere una versión de GitHub; no necesita Git instalado.
  remotes::install_github(
    "posit-dev/mcptools@714803bdfce903707a27d9c4740591d87f601aae",
    upgrade = "never", repos = "https://cloud.r-project.org"
  )
  if (!requireNamespace("mcptools", quietly = TRUE)) stop("No se pudo instalar mcptools para App 09.")

  message("Instalación terminada. Completa tu clave en .Renviron y continúa con las slides del taller.")
})
