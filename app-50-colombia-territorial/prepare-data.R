library(tidyverse)
library(sf)

# Descargar los anexos generales de la ECV 2025 publicados por el DANE.
url_ecv <- paste0(
  "https://www.dane.gov.co/files/operaciones/ECV/",
  "anex-ECV-2025.xlsx"
)
archivo_ecv <- tempfile(fileext = ".xlsx")
download.file(url_ecv, archivo_ecv, mode = "wb")

# Leer población, hogares, viviendas y promedios del Cuadro 1.
demografia <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 1", skip = 14,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 3, 8, 13, 18, 23) |>
  setNames(c(
    "departamento", "area", "viviendas", "hogares", "poblacion",
    "hogares_por_vivienda", "personas_por_hogar"
  )) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(across(-c(departamento, area), as.numeric)) |>
  select(-area)

# Leer los porcentajes de acceso a servicios del Cuadro 5.
servicios <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 5", skip = 14,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 11, 19, 27, 35, 43) |>
  setNames(c(
    "departamento", "area", "energia_pct", "gas_natural_pct",
    "acueducto_pct", "alcantarillado_pct", "recoleccion_basura_pct"
  )) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(across(-c(departamento, area), as.numeric)) |>
  select(-area)

# Leer el porcentaje de hogares con internet del Cuadro 9.
internet_hogares <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 9", skip = 15,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 12) |>
  setNames(c("departamento", "area", "hogares_internet_pct")) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(hogares_internet_pct = as.numeric(hogares_internet_pct)) |>
  select(-area)

# Leer los tres indicadores principales de déficit habitacional del Cuadro 12.
deficit <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 12", skip = 15,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 12, 21, 30) |>
  setNames(c(
    "departamento", "area", "deficit_cuantitativo_pct",
    "deficit_cualitativo_pct", "deficit_habitacional_pct"
  )) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(across(-c(departamento, area), as.numeric)) |>
  select(-area)

# Leer la afiliación al sistema de salud del Cuadro 20.
salud <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 20", skip = 15,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 11) |>
  setNames(c("departamento", "area", "afiliacion_salud_pct")) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(afiliacion_salud_pct = as.numeric(afiliacion_salud_pct)) |>
  select(-area)

# Leer los años promedio de educación de las personas de 5 años y más.
educacion <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 32", skip = 15,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 3) |>
  setNames(c("departamento", "area", "anios_educacion")) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(anios_educacion = as.numeric(anios_educacion)) |>
  select(-area)

# Leer el uso de computador, internet y teléfono celular del Cuadro 34.
uso_tecnologia <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 34", skip = 14,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 11, 19, 27) |>
  setNames(c(
    "departamento", "area", "uso_computador_pct", "uso_internet_pct",
    "uso_celular_pct"
  )) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(across(-c(departamento, area), as.numeric)) |>
  select(-area)

# Leer la percepción de pobreza del Cuadro 36.
pobreza <- readxl::read_excel(
  archivo_ecv, sheet = "Cuadro 36", skip = 14,
  col_names = FALSE, col_types = "text", .name_repair = "unique_quiet"
) |>
  select(1, 2, 11) |>
  setNames(c("departamento", "area", "pobreza_percibida_pct")) |>
  fill(departamento) |>
  filter(area == "Total", departamento != "Total nacional") |>
  mutate(pobreza_percibida_pct = as.numeric(pobreza_percibida_pct)) |>
  select(-area)

# Reunir los indicadores en una fila por departamento.
indicadores <- demografia |>
  left_join(servicios, by = "departamento") |>
  left_join(internet_hogares, by = "departamento") |>
  left_join(deficit, by = "departamento") |>
  left_join(salud, by = "departamento") |>
  left_join(educacion, by = "departamento") |>
  left_join(uso_tecnologia, by = "departamento") |>
  left_join(pobreza, by = "departamento") |>
  mutate(across(c(viviendas, hogares, poblacion), ~ round(.x * 1000)))

# Crear una clave sencilla para unir los nombres de los dos archivos oficiales.
indicadores <- indicadores |>
  mutate(
    clave = departamento |>
      stringi::stri_trans_general("Latin-ASCII") |>
      str_to_upper() |>
      str_remove_all("[^A-Z]")
  )

# Descargar desde data_ColOpenData el objeto sf derivado del MGN 2018.
url_geometria <- paste0(
  "https://raw.githubusercontent.com/biomac-lab/data_ColOpenData/main/",
  "MGN/MGN_CNPV_2018/MGN_NivelDepartamentoIntegrado_CNPV/",
  "MGN_AMN_DPTOS.RDS"
)
archivo_geometria <- tempfile(fileext = ".rds")
download.file(url_geometria, archivo_geometria, mode = "wb")

# Seleccionar solamente la identificación y geometría que necesita la app.
geometria <- readRDS(archivo_geometria) |>
  transmute(
    codigo = DPTO_CCDGO,
    departamento_mgn = DPTO_CNMBR,
    area_m2 = AREA,
    latitud = LATITUD,
    longitud = LONGITUD,
    geometry
  ) |>
  st_make_valid() |>
  st_transform(9377) |>
  st_simplify(dTolerance = 2000, preserveTopology = TRUE) |>
  st_transform(4326) |>
  mutate(
    clave = departamento_mgn |>
      stringi::stri_trans_general("Latin-ASCII") |>
      str_to_upper() |>
      str_remove_all("[^A-Z]"),
    clave = case_when(
      codigo == "88" ~ "SANANDRES",
      codigo == "76" ~ "VALLE",
      TRUE ~ clave
    )
  )

# Unir indicadores y geometría, y comprobar que quedaron los 33 territorios.
departamentos <- geometria |>
  left_join(indicadores, by = "clave") |>
  select(
    codigo, departamento, area_m2, latitud, longitud,
    poblacion, hogares, viviendas, hogares_por_vivienda,
    personas_por_hogar, energia_pct, gas_natural_pct, acueducto_pct,
    alcantarillado_pct, recoleccion_basura_pct, hogares_internet_pct,
    deficit_cuantitativo_pct, deficit_cualitativo_pct,
    deficit_habitacional_pct, afiliacion_salud_pct, anios_educacion,
    uso_computador_pct, uso_internet_pct, uso_celular_pct,
    pobreza_percibida_pct
  )

stopifnot(nrow(departamentos) == 33, !anyNA(departamentos$departamento))

# Guardar el objeto que consume app.R.
dir.create("data", showWarnings = FALSE)
saveRDS(departamentos, "data/colombia_departamentos.rds", compress = "xz")
