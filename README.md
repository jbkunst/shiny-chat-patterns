# shiny-chat-patterns

Ejemplos progresivos de patrones para construir aplicaciones Shiny con chat y tools.

## Sobre el taller

**Shiny + ellmer: patrones para conectar conversación, datos e interfaz** es un taller
práctico que recorre, paso a paso, distintas formas de incorporar modelos de lenguaje en una
aplicación Shiny usando `ellmer`. Partiremos desde una aplicación simple y agregaremos
conversación, acceso controlado a datos, consultas SQL, actualización del estado y acciones sobre la
interfaz, hasta conectar herramientas remotas mediante MCP y graficar sus datos en Shiny.

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
- Comparación y uso complementario de filtros tradicionales y consultas por chat.
- Control del globo y su cámara, y entrega del gráfico de un modal al modelo para interpretarlo.

**Capítulo 4 · Conectar herramientas externas con MCP · App 09**

- Comparación real y cacheada con el mismo modelo, sin y con MCP.
- Consulta de datos del FMI mediante el servidor MCP comunitario de cyanheads.
- Crecimiento, inflación y población compartidos entre mapa y dispersión.

**Casos de aplicación · Colombia territorial y series de Banrep**

- Aplicaciones más completas que combinan los patrones del recorrido principal.
- Separación de responsabilidades entre las tools de cada caso.

La presentación vive en `slides/` y se publica en
<https://jkunst.com/shiny-chat-patterns/>. El QMD, el tema y los scripts se mantienen juntos para que
la carpeta pueda publicarse como una unidad. El render también lee los scripts de `R/` y de las apps.

## Sobre el repositorio

La numeración reserva `00–49` para el recorrido del taller, `50–89` para casos de aplicación
y `90` en adelante para apps experimentales.

El recorrido principal comprende `app-00`–`app-09`: una aplicación que crece paso a paso,
incorporando conversación, datos, acciones de interfaz y herramientas remotas. Cada carpeta conserva
una versión independiente para reconocer el cambio y ejecutarlo durante el taller.
`app-00` es una introducción básica a Shiny, con widgets y outputs. Desde `app-01` crece el
dashboard común de países.
`app-07` muestra cómo los controles manuales y el chat pueden compararse y complementarse;
`app-08` agrega un globo y completa la tool de gráficos para enviar la imagen al modelo;
`app-09` cambia la fuente por el MCP del FMI: conserva mapa y gráficos, sin SQL ni datos iniciales.

Las apps del recorrido principal usan `page_sidebar()` para mantener una estructura consistente
y concentrar cada ejemplo en el patrón que introduce. Desde `app-00` hasta
`app-08`, cada carpeta contiene `app.R` y `app.py` para comparar la misma idea
en ambos lenguajes. Las versiones de chat usan `ellmer` y `chatlas`, respectivamente.

## Ejemplos de consola

Los primeros cuatro ejemplos de consola tienen versiones en R (`ellmer`) y Python (`chatlas`).
El ejemplo MCP está disponible por ahora en R.
Ejecuta los scripts desde la raíz del repositorio y carga primero todas sus librerías o imports.

| Patrón | R | Python |
|---|---|---|
| Conversación e historial | `R/01_ellmer.R` | `python/01_chatlas.py` |
| Pronóstico con una tool | `R/02_ellmer_tool.R` | `python/02_chatlas_tool.py` |
| Fecha actual y pronóstico con dos tools | `R/03_ellmer_dos_tools.R` | `python/03_chatlas_dos_tools.py` |
| Imagen de puntos aleatorios | `R/04_ellmer_imagen.R` | `python/04_chatlas_imagen.py` |
| Consola interactiva con MCP del FMI | `R/06_ellmer_mcp.R` | Pendiente |

En los ejemplos 02–04 se pregunta primero sin tools, se registran y se vuelve a preguntar en la misma
conversación. Las llamadas directas permiten inspeccionar los resultados sin llamar al modelo.
El ejemplo de imagen muestra el gráfico en una sesión interactiva y devuelve esa misma imagen al agente.
Cada llamada genera puntos nuevos; los generadores aleatorios de R y Python producen muestras distintas.

```r
source("R/02_ellmer_tool.R", encoding = "UTF-8")
```

```console
uv run --env-file .Renviron python python/02_chatlas_tool.py
```

Las consolas auxiliares de `app-02`, `app-03` y `app-04` tienen `interactive-console.R` y
`interactive-console.py`. Las de datos comparten `data/paises.csv` con las apps; la de SQL comparte
también `app-04/prompt.md`. Desde la raíz, usa `source("app-03/interactive-console.R")` o
`uv run python app-03/interactive-console.py` para abrir la conversación.

Los scripts de preparación de datos, el lanzador del catálogo y las apps experimentales son utilidades
o exploraciones en R; todavía no tienen una pareja Python. No forman parte de estos ejemplos de consola.

## Recorrido principal

| App | Qué presenta |
|---|---|
| `app-00` | Conectar inputs y outputs con widgets de Shiny, sin chat |
| `app-01` | Dashboard reactivo de países y filtro manual |
| `app-02` | Chat que todavía no conoce los datos |
| `app-03` | Tool que entrega al modelo un resumen de los países visibles |
| `app-04` | DuckDB mediante una tool SQL de solo lectura |
| `app-05` | Consultas del chat que actualizan el dashboard |
| `app-06` | Tools que abren tablas y gráficos en modales y confirman la acción |
| `app-07` | Uso complementario de filtros manuales y consultas por chat |
| `app-08` | Mover el mapa e interpretar gráficos cuya imagen recibe el modelo |
| `app-09` | Conecta herramientas MCP con tools locales; crecimiento e inflación del FMI |
| `app-09-v2` | Agente mínimo con page_chat(), chat_server() y herramientas MCP |

En App 09, la demo colorea América Latina por inflación y combina crecimiento real del PIB,
inflación y población en una dispersión. Compara 2023 con 2020, con ejes lineales.
Los valores provienen del FMI; cyanheads mantiene el servidor comunitario.
La comparación histórica sin y con MCP sigue siendo del Banco Mundial y se identifica como tal.
Se valida offline y las slides leen su JSON local. mcp-tools.R conserva el ajuste de ese MCP.
La app comienza vacía. Un solo data() conserva filas con pais, anio, x_var, y_var,
size_var, color_var y map_var, junto con nombres y unidades. El agente arma la carga recibida del MCP y la entrega a guardar_datos().
Cada carga reemplaza la anterior; mapa, dispersión, tabla y resumen muestran esos mismos países.
Las pestañas Visualización y Datos separan el mapa y el gráfico de la tabla, debajo de los indicadores.
ver_datos() permite leer o reutilizar la carga. No hay filtros regionales ni series temporales.
El gráfico muestra ejes vacíos al inicio y permite color, tamaño y escalas logarítmicas en X o Y.
Las apps R 00–09 usan thematic y ragg para heredar la tipografía de la interfaz desde `_brand.yml`.

`app-09-v2` conserva solo el agente conectado al MCP, en una interfaz `page_chat()`.
Usa `chat_server()` para gestionar mensajes y streaming y registra todas las herramientas del MCP.
Registra las tools del FMI con `set_tools(mcp_tools("mcp-imf.json"))`, sin adaptar sus esquemas.
Conserva `mcp.json` con el Banco Mundial para comparar cambiando solo el archivo de configuración.
Ejecuta la variante con `shiny::runApp("app-09-v2")`.

`app-07` forma parte de la secuencia: permite comparar ambas formas de interacción y usarlas como
complemento sobre el mismo dashboard. Sus tools de interfaz conservan la confirmación simple de App 06.
`app-08` agrega el globo e `ir_a_pais()`, y completa `mostrar_grafico()` de App 06: además del modal,
devuelve una confirmación y la imagen al modelo. La misma función de dibujo se usa en ambos destinos.
El ejemplo de consola `R/04_ellmer_imagen.R` y su pareja Python introducen ese paso antes de App 08.

La progresión es de capacidades, sin conservar necesariamente todas las tools y controles anteriores:
App 04 reemplaza el resumen fijo por SQL; App 05 pasa del filtro manual a la actualización por chat;
App 07 reúne ambos caminos; App 08 centra la vista en el mapa y el gráfico, sin los filtros manuales
ni la tool de tabla de App 07.
La interpretación de imágenes usa `gpt-5.6-luna`, igual que el ejemplo de consola.

## Casos de aplicación

Estas apps trasladan los patrones del recorrido principal a fuentes colombianas. No continúan la
secuencia incremental `app-00`–`app-09`; muestran cómo organizar tools por responsabilidad.
Son casos particulares para motivar con aplicaciones concretas. Sus estilos y layouts son excepciones
deliberadas a la UI mínima de las apps de enseñanza; no tienen que conservar el mismo dashboard.

| App | Fuente | Patrón |
|---|---|---|
| `app-50-colombia-territorial` | ECV 2025 · MGN 2018 | Mapa de indicadores con chat flotante |
| `app-51-banrep-sdmx` | Banco de la República | Chat, gráfico de una serie y últimas observaciones |

Después de MCP, una tabla compara cómo estos casos separan responsabilidades entre sus tools:
resolver el catálogo, consultar datos, mostrar el resultado e inspeccionar la vista para responder.
La 50 consulta datos locales; la 51 descarga observaciones desde el servicio de Banrep.

`app-50-colombia-territorial` incluye datos departamentales locales para funcionar durante el
taller. Su chat flotante es una excepción al sidebar del recorrido principal. Para reconstruir los
indicadores desde los anexos Excel del DANE y la geometría MGN 2018 de data_ColOpenData, ejecuta
dentro de su carpeta:

```r
source("prepare-data.R")
```

`app-51-banrep-sdmx` consulta el servicio público en tiempo de ejecución, por lo que requiere
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

Las apps 01–08 conservan los 142 países en R y Python. En App 08, los países sin geometría en Natural Earth
siguen presentes en los indicadores, las consultas y los gráficos, aunque no tengan un polígono en el globo.

La versión Python de `app-08` usa un globo ortográfico de Plotly. La tool de
cámara actualiza el widget existente mediante `map.widget.update_geos()`, el
equivalente práctico de un proxy: no reconstruye el mapa al cambiar el centro.
Los códigos de país y las coordenadas de cámara provienen del catálogo
Gapminder incluido en Plotly.

## Aplicaciones experimentales

Las apps `90+` son exploraciones fuera del recorrido del taller. Actualmente:

| App | Qué explora |
|---|---|
| `app-90-orquestacion-simulada-experimental` | Dos agentes; el analista propone una consulta y la ejecución devuelve datos simulados. |
| `app-91-orquestacion-duckdb-experimental` | Dos agentes persistentes y consultas reales a una base DuckDB de solo lectura. |

Se pueden incluir al ejecutar `run_all_apps(include_experimental = TRUE)`.
## Alcance

El recorrido principal comprende `app-00`–`app-09`. App 09 está disponible por ahora solo en R.
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

Los clientes usan el formato `proveedor/modelo`: `ellmer::chat("openai/gpt-5.6-luna")` en R
y `ChatAuto("openai/gpt-5.6-luna")` en Python, importado desde `chatlas`.
Cambiar esa cadena permite elegir otro proveedor con sus credenciales correspondientes.
Cada ejemplo conserva su modelo: GPT-5 nano o GPT-5.6 Luna.

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

Para cargar la clave y comprobar que ellmer puede consultar el modelo, ejecuta desde la raíz:

```r
library(ellmer)
readRenviron(".Renviron")
nzchar(Sys.getenv("OPENAI_API_KEY"))
chat <- ellmer::chat("openai/gpt-5-nano")
chat$chat("Responde solamente: conexión correcta.")
```

La tercera línea debe devolver `TRUE` sin mostrar la clave. La última comprueba el acceso a la API.

Si ya tienes `usethis`, puedes crear o actualizar la variable de forma interactiva. La clave se
solicita de manera protegida y queda disponible inmediatamente en la sesión actual:

```r
usethis::use_env_var("OPENAI_API_KEY", scope = "project")
```

Python no carga `.Renviron` automáticamente. Con `uv`, puedes reutilizar el archivo de R
desde la raíz del repositorio:

```console
uv run --env-file .Renviron python python/02_chatlas_tool.py
```

También puedes definir la variable en la terminal antes de ejecutar Python. En PowerShell:

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

Por defecto incluye App 00–09, la variante 09 v2 y los casos 91–92. Las experimentales se agregan con
`run_all_apps(include_experimental = TRUE)` después de cargar el script.

Esta instrucción primero valida el código R y los títulos y descripciones de las apps, asigna sus
puertos y guarda el plan en `catalog/apps.yml`. Después inicia exactamente las apps de ese YAML y
vuelve a renderizar el catálogo con la misma lista. Antes de abrirlo, verifica que incluya todas las
apps y sus URLs. El objeto
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
