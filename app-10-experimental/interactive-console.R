library(bcchr)
library(dplyr)

token <- Sys.getenv("BCCH_TOKEN")

# Desempleo ---------------------------------------------------------------
candidatos <- resolve_series("desocupación INE", token = token)
candidatos |>
  select(spanish_title, series_id, frequency)

codigo <- "F049.DES.TAS.INE9.10.M"

candidatos |>
  filter(series_id == codigo) |>
  select(spanish_title, series_id, frequency)


datos <- get_series(codigo, from = "2020-01-01", token = token)
datos

grafico <- plot_series(datos)
grafico

# Dólar observado ---------------------------------------------------------
candidatos <- resolve_series("dólar observado", token = token)
candidatos |>
  select(spanish_title, series_id, frequency)

codigo <- "F073.TCO.PRE.Z.D"

datos <- get_series(codigo, from = "2020-01-01", token = token)
datos

grafico <- plot_series(datos)
grafico


# TPM ---------------------------------------------------------------------
candidatos <- resolve_series("tasa política monetaria porcentaje", token = token)
candidatos |>
  select(spanish_title, series_id, frequency)

codigo <- "F022.TPM.TIN.D001.NO.Z.D"

datos <- get_series(codigo, from = "2020-01-01", token = token)
datos

grafico <- plot_series(datos)
grafico
