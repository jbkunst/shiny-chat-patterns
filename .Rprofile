# Use Posit Package Manager so renv can restore pinned package versions from binaries.
options(renv.config.repos.override = "https://packagemanager.posit.co/cran/latest")

source("renv/activate.R")
options(
  bslib.color_contrast_warnings = FALSE,
  shiny.minified = TRUE,
  shiny.autoreload = FALSE,
  shiny.autoreload.legacy_warning = FALSE,
  sass.cache = TRUE,
  bslib.precompiled = TRUE
)

conflictRules("bslib", mask.ok = "page")
