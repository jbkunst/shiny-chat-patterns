library(mcptools)
library(ellmer)

# Banco Mundial: ajuste de compatibilidad para este MCP; no se usa con el FMI.
# tools -------------------------------------------------------------------
tools <- mcptools::mcp_tools("mcp-worldbank.json")
tools <- Filter(function(x) x@name %in% c(
  "worldbank_search_indicators", "worldbank_get_indicator", "worldbank_get_data"
), tools)
names(tools) <- vapply(tools, function(x) x@name, "")

# El taller consulta un año o el último dato por país; omite mrv/frequency.
# Este esquema acotado funcionó con ellmer 0.4.2 y Luna en las pruebas del taller.
for (i in seq_along(tools)) {
  if (tools[[i]]@name == "worldbank_get_data") {
    tools[[i]]@arguments@properties <- tools[[i]]@arguments@properties[
      c("indicator_id", "countries", "date_range", "mrnev", "page", "per_page")
    ]
  }
}

