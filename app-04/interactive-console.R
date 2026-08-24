library(datos)
library(DBI)
library(duckdb)
library(ellmer)

# database ----------------------------------------------------------------
paises <- datos::paises |> subset(anio == max(anio)) |> dplyr::select(-anio)

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
DBI::dbWriteTable(con, "paises", paises)
DBI::dbExecute(con, "SET enable_external_access = false")

validar_select <- function(consulta) {
  consulta <- trimws(consulta)
  if (!grepl("^SELECT\\b", consulta, ignore.case = TRUE)) stop("Solo se permiten consultas SELECT.")
  if (!grepl("\\bpaises\\b", consulta, ignore.case = TRUE)) stop("La consulta debe usar paises.")
  if (grepl(";", consulta, fixed = TRUE)) stop("Envía una sola consulta y no incluyas punto y coma.")
  consulta
}

# tool --------------------------------------------------------------------
consultar_paises <- function(consulta) {
  DBI::dbGetQuery(con, validar_select(consulta))
}

# chat --------------------------------------------------------------------
prompt_sistema <- paste(readLines("app-04/prompt.md", warn = FALSE), collapse = "\n")
chat <- chat_openai(model = "gpt-5-nano", system_prompt = prompt_sistema)

chat$register_tool(tool(
  consultar_paises,
  "Ejecuta una consulta SELECT de solo lectura sobre la tabla DuckDB paises.",
  arguments = list(
    consulta = type_string("Consulta DuckDB SELECT sobre la tabla paises, sin punto y coma.")
  )
))

if (interactive()) {
  live_console(chat)
  DBI::dbDisconnect(con, shutdown = TRUE)
}
