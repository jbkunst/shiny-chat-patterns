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

**Preparar y conversar · App 00–02**

- Dashboard y reactividad como punto de partida.
- Chat sin acceso a los datos de la aplicación.

**Consultar y actualizar · App 03–05**

- Primera tool para consultar los datos visibles.
- Consultas SQL de solo lectura.
- Actualización del estado reactivo desde una tool.

**Pausa**

**Actuar sobre la interfaz · App 06–08**

- Acciones de interfaz: tablas, gráficos y modales.
- Comparación y uso complementario de filtros tradicionales y consultas por chat.
- Control del globo y su cámara, y entrega del gráfico de un modal al modelo para interpretarlo.

**Conectar herramientas externas con MCP · App 09**

- Descubrimiento y uso de herramientas remotas mediante MCP.
- Una carga con `pais`, `anio`, `x` e `y`: mapa con Y, gráfico y tabla con X e Y.
- App 09 v2 conserva la conversación con MCP sin dashboard; v3 queda como referencia adicional.

**Casos de aplicación · Colombia territorial y series de Banrep**

- Aplicaciones más completas que combinan los patrones del recorrido principal.
- Ideas que comparten las funciones de ambos casos: resolver, consultar, mostrar e inspeccionar.

Las [slides publicadas](https://jkunst.com/shiny-chat-patterns/) acompañan el recorrido.
Su fuente y las instrucciones de render están en [slides/](slides/).

## Sobre el repositorio

La numeración reserva `00–49` para el recorrido del taller, `50–89` para casos de aplicación
y `90` en adelante para apps experimentales.

El recorrido principal comprende `app-00`–`app-09`: una aplicación que crece paso a paso,
incorporando conversación, datos, acciones de interfaz y herramientas remotas. Cada carpeta conserva
una versión independiente para reconocer el cambio y ejecutarlo durante el taller.
Desde `app-00` hasta `app-08`, cada carpeta contiene `app.R` y `app.py` para comparar la misma idea
en R y Python. Las versiones de chat usan `ellmer` y `chatlas`, respectivamente.
App 09 y los casos de aplicación están disponibles por ahora en R.

## Ejemplos de consola

Los primeros cuatro ejemplos de consola tienen versiones en R (`ellmer`) y Python (`chatlas`).
El ejemplo MCP está disponible por ahora en R.
Ejecuta los scripts desde la raíz del repositorio, con el entorno y la API configurados.

| Patrón | R | Python |
|---|---|---|
| Conversación e historial | [01](R/01_ellmer.R) | [01](python/01_chatlas.py) |
| Pronóstico con una tool | [02](R/02_ellmer_tool.R) | [02](python/02_chatlas_tool.py) |
| Dos tools | [03](R/03_ellmer_dos_tools.R) | [03](python/03_chatlas_dos_tools.py) |
| Imágenes para el modelo | [04](R/04_ellmer_imagen.R) | [04](python/04_chatlas_imagen.py) |
| Herramientas remotas con MCP | [06](R/06_ellmer_mcp.R) | Pendiente |

Guía y notas de estos ejemplos: [R/README.md](R/README.md).

```r
source("R/02_ellmer_tool.R", encoding = "UTF-8")
```

```console
uv run --env-file .Renviron python python/02_chatlas_tool.py
```

## Recorrido principal

| App | Qué presenta |
|---|---|
| [app-00](app-00/) | Conectar inputs y outputs, sin chat |
| [app-01](app-01/) | Dashboard reactivo y filtros manuales |
| [app-02](app-02/) | Conversar sin acceso a los datos |
| [app-03](app-03/) | Consultar datos mediante una tool |
| [app-04](app-04/) | Consultas SQL de solo lectura |
| [app-05](app-05/) | Actualizar el dashboard desde el chat |
| [app-06](app-06/) | Mostrar tablas y gráficos en modales |
| [app-07](app-07/) | Combinar controles y conversación |
| [app-08](app-08/) | Mover el mapa e interpretar gráficos |
| [app-09](app-09/) | MCP y dashboard: mapa con Y, gráfico y tabla con X e Y |
| [app-09-v2](app-09-v2/) | Conversar con MCP en una interfaz mínima |
| [app-09-v3](app-09-v3/) | Referencia configurable; fuera de las slides y del catálogo por defecto |

Los ejemplos de uso y las notas de implementación se documentan en la carpeta de cada app.

## Casos de aplicación

Dos aplicaciones con datos de Colombia muestran los patrones del taller en contextos concretos.

| App | Caso | Datos |
|---|---|---|
| [App 50](app-50-colombia-territorial/) | Indicadores territoriales | Datos locales del DANE |
| [App 51](app-51-banrep-sdmx/) | Series económicas | API del Banco de la República |

## Aplicaciones experimentales

Las apps numeradas desde `90` son experimentales y quedan fuera del recorrido del taller.

## Instalar

Para las apps R se necesita **R 4.6.1 o posterior**. Elige una de estas dos rutas:

### Opción 1 · ZIP de GitHub e install.packages

Para quienes no usan Git: en GitHub, selecciona **Code → Download ZIP** y extrae todo el archivo.
Abre la carpeta en Positron o, si usas RStudio, abre `shiny-chat-patterns.Rproj`.
Desde la raíz del proyecto, ejecuta `source("R/instalar.R", encoding = "UTF-8")`.

Las slides «Antes de partir · Setup simple» y «Antes de partir · Setup Git + renv» presentan
las dos opciones. No hay un ZIP distinto: se usa el que entrega GitHub.
El `.Rproj` establece la carpeta de trabajo y usa UTF-8. El ZIP de GitHub no contiene `.git`,
por lo que `.Rprofile` no activa `renv` al abrirlo.

El script usa `install.packages()` e instala además la versión de `mcptools` necesaria para App 09
desde GitHub, automáticamente y sin necesitar Git instalado. Al final avisa si falta `.Renviron`;
no crea ni modifica ese archivo.
Esta ruta usa las versiones disponibles de los paquetes CRAN; no reproduce exactamente `renv.lock`.

### Opción 2 · GitHub y renv

Para restaurar las versiones fijadas del taller, clona el repositorio:

```console
git clone https://github.com/jbkunst/shiny-chat-patterns.git
cd shiny-chat-patterns
```

Desde la raíz del proyecto, en Positron o RStudio, restaura el entorno:

```r
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore()
```

`.Rprofile` activa `renv` automáticamente en los clones de Git; `renv.lock` fija las versiones.
No ejecutes `R/instalar.R` en esta ruta.

Para las versiones Python, opcionales e independientes del entorno R, se necesita Python 3.12 o posterior
y [`uv`](https://docs.astral.sh/uv/). Ejecuta `uv sync --locked` desde la raíz; `uv.lock` fija sus dependencias.

## Configurar la API

Los clientes usan el formato `proveedor/modelo`: `ellmer::chat("openai/gpt-5.6-luna")` en R
y `ChatAuto("openai/gpt-5.6-luna")` en Python, importado desde `chatlas`.
Cambiar esa cadena permite elegir otro proveedor con sus credenciales correspondientes.
Cada ejemplo conserva su modelo: GPT-5 nano o GPT-5.6 Luna.

Las apps con chat, desde `app-02`, necesitan `OPENAI_API_KEY`. `app-00` y `app-01` funcionan sin una
clave.

Para R, crea un archivo `.Renviron` en la raíz. Puedes copiar `.Renviron.example` y completar tu clave:

```dotenv
OPENAI_API_KEY="PEGA_TU_CLAVE_AQUI"
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
chat$chat("Responde solo: OK")
```

La tercera línea debe devolver `TRUE` sin mostrar la clave. La última comprueba el acceso a la API.

Python no carga `.Renviron` automáticamente. Con `uv`, puedes reutilizar el archivo de R
desde la raíz del repositorio:

```console
uv run --env-file .Renviron python python/02_chatlas_tool.py
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
descripción, una vista interactiva y los diagramas de la app debajo.
Desde una sesión R en la raíz del repositorio:

```r
source("R/run_all_apps.R")
```

Incluye el recorrido principal, la variante 09 v2 y los casos de aplicación.
Al terminar, detén todos los procesos con:

```r
stop_all_apps(course)
```

Requiere Quarto en `PATH`. Las opciones del lanzador están en [catalog/](catalog/).
