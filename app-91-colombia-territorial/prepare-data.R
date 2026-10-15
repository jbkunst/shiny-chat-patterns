library(sf)

url <- paste0(
  "https://services.arcgis.com/deQSb0Gn7gDPf3uV/ArcGIS/rest/services/",
  "Distribuci%C3%B3n_de_Poblaci%C3%B3n_y_Vivienda_Censo_Nacional_del_2018_",
  "An%C3%A1lisis_Departamental_de_Colombia/FeatureServer/0/query?",
  "where=1%3D1&outFields=DPTO_CCDGO%2CDPTO_CNMBR%2CAREA%2CLATITUD%2CLONGITUD%2C",
  "STP27_PERS%2CTSP16_HOG%2CSTVIVIENDA&returnGeometry=true&outSR=4326&f=geojson"
)

departamentos <- st_read(url, quiet = TRUE) |>
  st_make_valid() |>
  st_transform(9377) |>
  st_simplify(dTolerance = 2000, preserveTopology = TRUE) |>
  st_transform(4326)

names(departamentos)[match(
  c("DPTO_CCDGO", "DPTO_CNMBR", "AREA", "LATITUD", "LONGITUD", "STP27_PERS",
    "TSP16_HOG", "STVIVIENDA"),
  names(departamentos)
)] <- c(
  "codigo", "departamento", "area_m2", "latitud", "longitud", "poblacion",
  "hogares", "viviendas"
)

departamentos <- departamentos[
  c("codigo", "departamento", "area_m2", "latitud", "longitud", "poblacion",
    "hogares", "viviendas")
]
dir.create("data", showWarnings = FALSE)
saveRDS(departamentos, "data/colombia_departamentos.rds", compress = "xz")
