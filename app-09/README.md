# App 09 · MCP + datos del FMI

Parte del recorrido principal, por ahora solo en R. La idea nueva es registrar tools remotas con
MCP. La tool local `graficar_serie()` reutiliza el patrón de actualización reactiva para mostrar los datos.

El [servidor MCP comunitario de cyanheads](https://github.com/cyanheads/imf-mcp-server) consulta datos
del FMI; no es un servidor oficial del Fondo. Su endpoint público no requiere una clave propia.
El modelo usa `OPENAI_API_KEY`, igual que las otras apps. Las respuestas dependen de la disponibilidad
del servidor y de la publicación de cada base.

## Ejecutar

Restaura las dependencias desde la raíz con `renv::restore()` y abre la app:

```r
shiny::runApp("app-09")
```

`renv.lock` fija la revisión de `posit-dev/mcptools` comprobada con este endpoint HTTP:
`714803bdfce903707a27d9c4740591d87f601aae`. Esta revisión conserva los campos JSON `null` al ocultar
datos sensibles, y evita un fallo del cliente al procesar algunas respuestas del servidor.

Si `renv::restore()` falla en Windows al extraer el archivo `AGENTS.md` de esa dependencia, la instalación
con `remotes` permite completar la compilación del paquete. Con el entorno del proyecto activo:

```r
install.packages("remotes") # Solo si aún no está instalado.
remotes::install_github(
  "posit-dev/mcptools@714803bdfce903707a27d9c4740591d87f601aae",
  dependencies = FALSE, upgrade = "never", build_vignettes = FALSE
)
```

Prueba: «Consulta la población de Chile entre 2020 y 2025 y grafícala».
El chat muestra las llamadas MCP y la llamada local de gráficos. La tabla permite comparar los valores
graficados con los devueltos por la consulta. Comprueba indicador, unidad y años de proyección.
La prueba completa verificó que el gráfico coincide con la consulta a la precisión publicada por WEO.

## Qué hace cada parte

- `imf_list_databases`: descubre bases disponibles.
- `imf_get_database`: obtiene dimensiones y códigos para construir la consulta.
- `imf_query_dataset`: recupera observaciones, unidades y fuente.
- `graficar_serie`: recibe los valores recuperados y actualiza el gráfico y la tabla en Shiny.

El endpoint también ofrece tools de consulta SQL sobre resultados almacenados. No son necesarias para
la demostración inicial. El gráfico se genera en R, no en el servidor MCP.

## Comparación cacheada para las slides

`data/comparacion.json` guarda una pregunta con el mismo modelo (`gpt-5-nano`) y el mismo prompt,
en conversaciones independientes, sin y con MCP. Conserva respuestas y llamadas completas a tools:
argumentos, resultados y errores. `data/comparacion.rds` guarda los mismos datos en formato R.
No contiene claves ni razonamiento interno del modelo. Las slides leen el JSON sin consultar la API.

La pregunta es «¿Cuál fue la tasa de desempleo de España en 2025?», sin exigir una fuente en la pregunta.
El prompt solo pide una respuesta breve en español con año, unidad y fuente;
no menciona MCP, herramientas ni el taller. La respuesta
sin MCP puede acertar de memoria o dar una aproximación: la comparación permite revisar precisión
y procedencia de los datos. Las preguntas y el prompt no piden al modelo que se equivoque.

La respuesta con MCP se contrasta con las observaciones guardadas de España, desempleo anual y año 2025,
respetando la precisión mostrada. El servidor ofrece esta serie en Labor Statistics y World Economic Outlook.
La ejecución guardada usa Labor Statistics (`ESP.U.PT.A`).
Las respuestas sin MCP se conservan tal como las dio el modelo; no se presentan como datos verificados.
Para repetir esa comprobación sin internet ni llamadas al modelo, ejecuta dentro de `app-09`:

```r
source("verify-comparison.R", encoding = "UTF-8")
```

Para regenerar las respuestas con consultas reales, ejecuta en esa misma carpeta:

```r
source("cache-comparison.R", encoding = "UTF-8")
```

Esto usa la API del modelo y reemplaza ambos archivos de caché. Revisa el resultado antes de publicarlo:
el script comprueba las respuestas, pero los datos del servidor pueden cambiar con nuevas publicaciones.
