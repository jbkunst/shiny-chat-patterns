# shiny-chat-patterns

Ejemplos progresivos de patrones para construir aplicaciones Shiny con chat y tools.

## Sobre el taller

**Shiny + ellmer: patrones para conectar conversación, datos e interfaz** es un taller
práctico que recorre, paso a paso, distintas formas de incorporar modelos de lenguaje en una
aplicación Shiny usando `ellmer`. Partiremos desde una aplicación simple y agregaremos
conversación, acceso controlado a datos, consultas SQL, actualización del estado y acciones sobre la
interfaz, para finalizar con un dashboard conversacional que controla gráficos, tablas y mapas.

Cada patrón se presenta como una aplicación independiente que cambia una sola idea respecto de la
anterior. Esto permite identificar con claridad qué código habilita cada patrón y cuándo resulta útil.
El objetivo no es reemplazar la interfaz tradicional con un chat, sino
entender cómo ambas formas de interacción pueden complementarse.

| | |
|---|---|
| **Duración** | 3 horas, con una pausa intermedia |
| **Nivel** | Intermedio; no se requiere experiencia avanzada en Shiny |
| **Audiencia** | Personas que hayan construido al menos una aplicación con R y Shiny |
| **Conocimientos previos** | R, reactividad básica y estructura de interfaz/servidor |
| **Experiencia con IA** | No se requiere experiencia previa con LLMs, chat o tools |

### Objetivos

Al finalizar el taller, quienes participen podrán:

- Integrar un chat en una aplicación Shiny y reconocer qué contexto puede utilizar el modelo.
- Definir tools pequeñas con nombres y argumentos explícitos para consultar datos reales.
- Permitir que una tool actualice valores reactivos y ejecute acciones de interfaz.
- Combinar controles tradicionales con consultas expresadas en lenguaje natural.
- Reconocer los límites de seguridad entre el navegador, la aplicación y servicios externos.

### Contenidos

**Capítulo 1 · Preparar y conversar · App 00–02**

- Dashboard y reactividad como punto de partida.
- Chat sin acceso a los datos de la aplicación.

**Capítulo 2 · Consultar y actualizar · App 03–05**

- Primera tool para consultar los datos visibles.
- Consultas SQL de solo lectura.
- Actualización del estado reactivo desde una tool.

**Pausa**

**Capítulo 3 · Actuar sobre la interfaz · App 06–08**

- Acciones de interfaz: tablas, gráficos y modales.
- Comparación entre filtros tradicionales y consultas por chat.
- Control de una visualización geográfica y su cámara.

**Extensión · Conectar herramientas externas con MCP · App 09**

- Comparación real y cacheada con el mismo modelo, sin y con MCP.
- Consulta de datos del FMI mediante un servidor MCP comunitario.
- Una tool local de R grafica las observaciones recuperadas.

La presentación vive en `slides/` y se publica en
<https://jkunst.com/shiny-chat-patterns/>. El QMD, el tema y los scripts se mantienen juntos para que
la carpeta pueda publicarse como una unidad. El render también lee los scripts de `R/` y de las apps.

## Sobre el repositorio

`app-00` establece el punto de partida y `app-01` presenta el dashboard común de países. Desde
`app-02` hasta `app-06`, cada aplicación incorpora **una sola idea nueva** y conserva tanto como sea
posible del paso anterior. `app-07` es una pausa comparativa; `app-08` retoma la línea principal desde
`app-06` y agrega el mapa. Así, cada cambio se reconoce en el código y puede mostrarse en un taller.

Las apps del recorrido principal usan `page_sidebar()` para mantener una estructura consistente
y concentrar cada ejemplo en el patrón que introduce. Desde `app-00` hasta
`app-08`, cada carpeta contiene `app.R` y `app.py` para comparar la misma idea
en ambos lenguajes. Las versiones de chat usan `ellmer` y `chatlas`, respectivamente.

## Ejemplos de consola

Los ejemplos de consola también tienen versiones equivalentes en R (`ellmer`) y Python (`chatlas`).
Ejecuta los scripts desde la raíz del repositorio y carga primero todas sus librerías o imports.

| Patrón | R | Python |
|---|---|---|
| Conversación e historial | `R/01_ellmer.R` | `python/01_chatlas.py` |
| Pronóstico con una tool | `R/02_ellmer_tool.R` | `python/02_chatlas_tool.py` |
| Fecha actual y pronóstico con dos tools | `R/03_ellmer_dos_tools.R` | `python/03_chatlas_dos_tools.py` |
| Imagen de puntos aleatorios | `R/04_ellmer_imagen.R` | `python/04_chatlas_imagen.py` |

En los ejemplos 02–04 se pregunta primero sin tools, se registran y se vuelve a preguntar en la misma
conversación. Las llamadas directas permiten inspeccionar los resultados sin llamar al modelo.
El ejemplo de imagen muestra el gráfico en una sesión interactiva y devuelve esa misma imagen al agente.
Cada llamada genera puntos nuevos; los generadores aleatorios de R y Python producen muestras distintas.

```r
source("R/02_ellmer_tool.R", encoding = "UTF-8")
```

```console
uv run python python/02_chatlas_tool.py
```

Las consolas auxiliares de `app-02`, `app-03` y `app-04` tienen `interactive-console.R` y
`interactive-console.py`. Las de datos comparten `data/paises.csv` con las apps; la de SQL comparte
también `app-04/prompt.md`. Desde la raíz, usa `source("app-03/interactive-console.R")` o
`uv run python app-03/interactive-console.py` para abrir la conversación.

Los scripts de preparación de datos, el lanzador del catálogo y las apps experimentales son utilidades
o exploraciones en R; todavía no tienen una pareja Python. No forman parte de estos ejemplos de consola.

## Recorrido principal

| App | Rol | Qué incorpora |
|---|---|---|
| `app-00` | Punto de partida | Presenta widgets y outputs, todavía sin chat |
| `app-01` | Nueva base | Establece el dashboard reactivo de países y el filtro manual |
| `app-02` | Incremental | Agrega un chat que todavía no conoce los datos |
| `app-03` | Incremental | Entrega al modelo un resumen de los países visibles |
| `app-04` | Incremental | Incorpora DuckDB mediante una tool SQL de solo lectura |
| `app-05` | Incremental | Permite que la consulta del chat actualice el dashboard |
| `app-06` | Incremental | Agrega tools que abren modales y retornan datos o imágenes |
| `app-07` | Comparativa | Contrasta filtros manuales con consultas solicitadas por chat |
| `app-08` | Retoma `app-06` | Agrega un globo que el chat puede filtrar y controlar |

`app-07` sí agrega la comparación sobre `app-06`, pero funciona como un desvío pedagógico: muestra
dos formas de controlar el mismo dashboard y no establece la base técnica de `app-08`.

## Extensión MCP en R

`app-09` incorpora las tools remotas de un servidor comunitario de datos del FMI mediante `mcptools`.
Reutiliza el patrón de actualización reactiva para graficar las observaciones con una tool local.
Por ahora solo tiene `app.R`; la versión Python queda pendiente de revisar este ejemplo.
Su configuración remota está en `app-09/mcp.json`. Requiere internet y `OPENAI_API_KEY` para el modelo;
el endpoint MCP usado en este ejemplo no requiere una clave propia.

```r
shiny::runApp("app-09")
```

La tabla comparativa de las slides usa `app-09/data/comparacion.json`, con respuestas reales, fecha,
modelo, prompt y resultados de las tools. No hace llamadas al modelo durante el render.
Consulta [las instrucciones de App 09](app-09/README.md) para verificar o regenerar la caché.

## Casos de aplicación

Estas apps trasladan los patrones del recorrido principal a fuentes colombianas. No continúan la
secuencia incremental `app-00`–`app-08`; muestran cómo organizar tools por responsabilidad.
Son casos particulares para motivar con aplicaciones concretas. Sus estilos y layouts son excepciones
deliberadas a la UI mínima de las apps de enseñanza; no tienen que conservar el mismo dashboard.

| App | Fuente | Patrón |
|---|---|---|
| `app-91-colombia-territorial` | ECV 2025 · MGN 2018 | Territorios, indicadores, mapa e inspección |
| `app-92-banrep-sdmx` | Banco de la República | Series SDMX, gráfico e inspección |

`app-91-colombia-territorial` incluye datos departamentales locales para funcionar durante el
taller. Su chat flotante es una excepción al sidebar del recorrido principal. Para reconstruir los
indicadores desde los anexos Excel del DANE y la geometría MGN 2018 de data_ColOpenData, ejecuta
dentro de su carpeta:

```r
source("prepare-data.R")
```

`app-92-banrep-sdmx` consulta el servicio público en tiempo de ejecución, por lo que requiere
conexión a internet además de `OPENAI_API_KEY`.

Cada carpeta entre `app-00` y `app-08` incluye un `DESCRIPTION` con su título,
resumen y paquetes de R utilizados.

En `app-02` y `app-03`, el greeting y el system prompt permanecen inline para
que todo el ejemplo se lea en un solo archivo. Desde `app-04`, cuando el prompt
empieza a crecer, se separan en `greeting.md` y `prompt.md`; ambos lenguajes
comparten esos archivos.

Las apps de países en R y Python leen `data/paises.csv`. El archivo se genera
con `R/generar-data-paises.R`, de modo que ambas implementaciones trabajan con
la misma base de 142 países.

En App 08 queda una diferencia pendiente de equivalencia: la unión con las geometrías en R conserva
140 países y excluye Reunión y Territorios Palestinos; Python conserva los 142. Esto afecta los totales
del dashboard de esa app. El recorrido App 01–07 usa los 142 países en ambos lenguajes.

La versión Python de `app-08` usa un globo ortográfico de Plotly. La tool de
cámara actualiza el widget existente mediante `map.widget.update_geos()`, el
equivalente práctico de un proxy: no reconstruye el mapa al cambiar el centro.
Los códigos de país y las coordenadas de cámara provienen del catálogo
Gapminder incluido en Plotly.

## Aplicaciones experimentales

Las carpetas con sufijo `-experimental` contienen aplicaciones en exploración. Todavía no forman una
secuencia formal ni están incorporadas al curso.

App 10, 12 y 13 usan `bcchr`, el catálogo local `data/series_catalog.rds` y `BCCH_TOKEN` para consultar
el Banco Central de Chile. App 11 solo conversa y requiere `OPENAI_API_KEY`.
App 13 conserva las tools de búsqueda y actualización de App 12;
la actualización también devuelve un resumen y una imagen al modelo.

## Alcance

El recorrido principal comprende `app-00`–`app-08`, seguido de la extensión MCP en R de `app-09`.
Las aplicaciones experimentales quedan fuera de este alcance
mientras no sean formalizadas e incorporadas al material del curso.

## Instalar

Se necesita R 4.6.1 y Python 3.12 o posterior, gestionado con [`uv`](https://docs.astral.sh/uv/).
Después de clonar el repositorio, restaura
los entornos desde la raíz:

```console
Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv')"
Rscript -e "renv::restore()"
uv sync
```

Los entornos son independientes y reproducibles:

- `renv.lock` fija las dependencias de las apps R.
- `uv.lock` fija las dependencias de las apps Python.

## Configurar la API

Las apps con chat, desde `app-02`, necesitan `OPENAI_API_KEY`. `app-00` y `app-01` funcionan sin una
clave.

Para R, crea un archivo `.Renviron` en la raíz:

```dotenv
OPENAI_API_KEY=tu_clave_de_openai
```

Luego reinicia R. Si el archivo se creó con la sesión abierta, también puedes cargarlo sin reiniciar:

```r
readRenviron(".Renviron")
```

Si ya tienes `usethis`, puedes crear o actualizar la variable de forma interactiva. La clave se
solicita de manera protegida y queda disponible inmediatamente en la sesión actual:

```r
usethis::use_env_var("OPENAI_API_KEY", scope = "project")
```

Para ejecutar las apps Python desde PowerShell:

```powershell
$env:OPENAI_API_KEY = "tu_clave_de_openai"
```

En macOS o Linux:

```bash
export OPENAI_API_KEY="tu_clave_de_openai"
```

`.Renviron` y `.env` están excluidos de Git. No guardes claves reales en el repositorio.

## Ejecutar una app

Cada aplicación es independiente. Para ejecutar la versión R desde la raíz:

```r
shiny::runApp("app-00")
```

Para ejecutar la versión Python dentro del entorno fijado por `uv.lock`:

```console
uv run shiny run --reload app-00/app.py
```

## Abrir todas las apps R

El lanzador inicia cada app estable en un proceso de fondo y abre un catálogo Quarto con su título,
descripción y una vista interactiva. Desde una sesión R en la raíz del repositorio:

```r
source("R/run_all_apps.R")
```

Por defecto incluye App 00–09 y los casos 91–92. Las experimentales se agregan con
`run_all_apps(include_experimental = TRUE)` después de cargar el script.

Esta única instrucción inicia las apps, prepara el catálogo y lo abre en el navegador. El objeto
`course` se crea automáticamente. Si vuelves a ejecutarla, primero detiene la ejecución anterior.
Al terminar el taller, detén todos los procesos con:

```r
stop_all_apps(course)
```

La función espera hasta confirmar que los procesos terminaron y sus puertos quedaron libres.

El catálogo requiere Quarto en `PATH`. Las apps usan los puertos `8000` en adelante y el catálogo
intenta usar el `7999`; si está ocupado, selecciona el siguiente disponible. Todos se pueden cambiar
mediante los argumentos de `run_all_apps()`.

Las apps se inician una por una para evitar que los ejemplos más pesados compitan por recursos. El
tiempo máximo de inicio es de 180 segundos y puede ajustarse con `startup_timeout`.
