library(mcptools)
library(ellmer)

# tools -------------------------------------------------------------------
tools <- mcptools::mcp_tools("mcp.json")
tools <- Filter(function(x) x@name %in% c(
  "worldbank_search_indicators", "worldbank_get_indicator", "worldbank_get_data"
), tools)
names(tools) <- vapply(tools, function(x) x@name, "")

# El taller consulta un año o el último dato por país; omite mrv/frequency.
# La unión opcional de frequency del esquema completo produce respuestas vacías en OpenAI.
for (i in seq_along(tools)) {
  if (tools[[i]]@name == "worldbank_get_data") {
    tools[[i]]@arguments@properties <- tools[[i]]@arguments@properties[
      c("indicator_id", "countries", "date_range", "mrnev", "page", "per_page")
    ]
  }
}

