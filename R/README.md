# Ejemplos de consola

Ejecuta estos scripts desde la raíz del repositorio, con los paquetes instalados y la clave cargada.
Puedes usar la [instalación simple desde ZIP o la ruta Git + renv](../README.md#instalar).
Los ejemplos 01–04 tienen versiones equivalentes en [python/](../python/).

| Script | Qué permite observar |
|---|---|
| [01_ellmer.R](01_ellmer.R) | Conversación, historial y consola interactiva. |
| [02_ellmer_tool.R](02_ellmer_tool.R) | La diferencia entre preguntar sin una tool y registrarla. |
| [03_ellmer_dos_tools.R](03_ellmer_dos_tools.R) | Coordinación de dos herramientas del clima. |
| [04_ellmer_imagen.R](04_ellmer_imagen.R) | Entregar una imagen al modelo para que pueda interpretarla. |
| [06_ellmer_mcp.R](06_ellmer_mcp.R) | Registrar las herramientas del MCP del FMI y seguir conversando. |

En 02–04 se pregunta sin tools, se registran y se vuelve a preguntar en la misma conversación.
Las llamadas directas a las funciones permiten inspeccionar sus resultados sin llamar al modelo.
El ejemplo 04 genera puntos nuevos en cada llamada; R y Python no producen muestras idénticas.

```r
readRenviron(".Renviron")
source("R/06_ellmer_mcp.R", encoding = "UTF-8")
```

Los scripts de preparación de datos y `run_all_apps.R` son utilidades del repositorio,
no pasos adicionales de esta secuencia. El lanzador se documenta en [catalog/](../catalog/).

## Ejercicio con pingüinos

Después de App 05, las slides proponen crear `ajustar_regresion(especie, x, y)` con
`datos::pinguinos`. Filtra una especie, ajusta `lm()` y devuelve `summary()` como texto para que
el chat interprete la pendiente y el R². Actualizar un gráfico X/Y queda como desafío adicional.
La [solución en Shiny](../app-99/app.R) reúne todo en un archivo y usa `dplyr`, del tidyverse.
El [punto de partida](ejercicio_pinguinos.R) incluye paquetes, datos, la función, su prueba directa,
la UI y el servidor del chat. El registro de la herramienta queda pendiente para completarlo en el ejercicio.
