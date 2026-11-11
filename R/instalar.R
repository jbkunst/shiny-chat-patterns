paquetes <- c(
  "brand.yml", "bslib", "countrycode", "datos", "DBI", "dplyr", "duckdb", "ellmer", "forecast",
  "gapminder", "ggplot2", "httr", "httr2", "jsonlite", "mapgl", "ragg", "readr",
  "remotes", "rnaturalearthdata", "sf", "shiny", "shinychat", "stringr", "thematic",
  "tinyplot", "xml2"
)
install.packages(paquetes, repos = "https://cloud.r-project.org")

remotes::install_github(
  "posit-dev/mcptools@714803bdfce903707a27d9c4740591d87f601aae",
  upgrade = "never", repos = "https://cloud.r-project.org"
)

if (!file.exists(".Renviron")) message("Falta crear .Renviron con tu clave de API.")
