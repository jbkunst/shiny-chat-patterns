# data --------------------------------------------------------------------
paises <- datos::paises |>
  subset(anio == max(anio)) |>
  dplyr::select(-anio)

# save --------------------------------------------------------------------
utils::write.csv(
  paises,
  "data/paises.csv",
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
