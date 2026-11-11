# App 09 · Conectar herramientas externas con MCP

Dashboard sencillo en R con el MCP comunitario de datos del FMI mantenido por cyanheads.
Registra todas sus tools directamente y agrega solo `guardar_datos()` y `ver_datos()`.
La app empieza vacía: una única carga alimenta mapa, dispersión, tabla e indicadores.

## Ejecutar

Desde la raíz, con la [configuración del taller](../README.md#configurar-la-api):

```r
readRenviron(".Renviron")
shiny::runApp("app-09")
```

El endpoint de `mcp.json` no necesita un token propio; el modelo usa `OPENAI_API_KEY`.
El servidor de [cyanheads](https://github.com/cyanheads/imf-mcp-server) no es oficial del FMI.
La versión Python queda pendiente de revisar el ejemplo R.

## Cuatro columnas para toda la vista

| Columna | Uso |
|---|---|
| `pais` | Código ISO3 para unir con Natural Earth. |
| `anio` | Año común de las observaciones. |
| `x` | Eje horizontal del gráfico. |
| `y` | Variable de interés: eje vertical del gráfico y color del mapa. |

`data()` contiene `datos` y `variables`. Los metadatos conservan columna (`x` o `y`), indicador,
nombre y unidad de la fuente. La tabla muestra `pais`, `anio`, `x` e `y`.
El gráfico usa puntos de tamaño fijo, color uniforme y ejes lineales.
Para mostrar solo un mapa, se envía `y` y se deja `x` en `null`.

`guardar_datos(datos, variables)` convierte las listas de filas con `bind_rows()` y reemplaza la carga.
`filas_vacias` conserva las cuatro columnas cuando alguna variable es opcional o llega en `null`.
`ver_datos()` devuelve la carga actual sin modificarla, para reutilizar o explicar sus valores.
La app no analiza cadenas JSON: ellmer entrega los argumentos estructurados como listas de R.

El agente decide países, año y variables, y obtiene todos los valores mediante MCP.
Mapa y dispersión dibujan solo las filas recibidas que tengan los valores necesarios.
El mapa usa `inner_join()`; la cartografía base da contexto y no agrega observaciones.
Sin datos para la dispersión, se muestran ejes vacíos. Las unidades aparecen en ejes, leyenda y tooltip.
Debajo de los indicadores, Visualización contiene Mapa y Gráfico; Datos contiene la tabla.
No hay SQL, series temporales, tamaño variable ni escalas configurables.

## Demo

1. «Colorea los países de América Latina según su inflación promedio anual en 2023».
2. «Ahora agrega crecimiento real del PIB en X y conserva la inflación en Y y en el mapa».
3. «Ahora consulta las mismas variables para 2020 y actualiza la vista».

También se puede pedir «población por crecimiento»: crecimiento va en X; población va en Y y en el mapa.
El agente debe conservar la unidad y escala de población que indique la edición de WEO consultada.
La app compara países en un año común; permite crecimientos negativos con ejes lineales.

## Verificación sin internet

```r
source("app-09/verify-demo.R", chdir = TRUE, encoding = "UTF-8")
```

La caché `data/demo-fmi.json` conserva la conversación real original, sin reescribir sus llamadas.
Si tiene el formato anterior, el verificador proyecta sus observaciones a `x` e `y` solo para el replay.
Contrasta valores con las respuestas MCP y comprueba mapa, gráfico, tabla, metadatos y columnas opcionales.
Esto no representa una conversación nueva del agente con la versión simplificada.

`cache-demo.R` puede generar una conversación nueva en formato `fmi-xy`; consulta al modelo y al MCP:

```r
readRenviron(".Renviron")
source("app-09/cache-demo.R", chdir = TRUE, encoding = "UTF-8")
```

La comparación sin y con MCP sigue siendo la caché histórica del Banco Mundial sobre esperanza de vida
al nacer en Colombia en 2023. `verify-comparison.R` la contrasta con sus llamadas reales,
sin consultar al modelo.
`mcp-worldbank.json` y `mcp-tools.R` se conservan solo para esa alternativa; la app del FMI no los carga.

## Variantes

Las slides muestran esta app y [App 09 v2](../app-09-v2/), el chat con MCP sin dashboard.
[App 09 v3](../app-09-v3/) conserva el dashboard anterior con tamaño, colores y escalas configurables.
Se ejecuta manualmente y queda fuera de las slides y del catálogo por defecto.
