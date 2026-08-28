# shiny-chat-patterns

Ejemplos progresivos de patrones para construir aplicaciones Shiny con chat y tools.

La idea es que cada aplicación agregue **una sola pieza nueva** y conserve el
mismo dominio de datos durante el recorrido principal. La secuencia también
puede usarse como base para demostraciones o talleres.

Todas las apps usan `page_sidebar()` para mantener una estructura consistente
y concentrar cada ejemplo en el patrón que introduce. Desde `app-00` hasta
`app-08`, cada carpeta contiene `app.R` y `app.py` para comparar la misma idea
en Shiny para R y Shiny para Python.

## Recorrido principal

| App | Título | Resumen |
|---|---|---|
| `app-00` | Widgets y outputs | Widgets básicos conectados a dos outputs mínimos |
| `app-01` | Dashboard reactivo | Dashboard de países con un filtro manual |
| `app-02` | Chat sin tools | El chat todavía no tiene acceso a los datos |
| `app-03` | Tool con contexto | El modelo consulta un resumen de los países visibles |
| `app-04` | Tool SQL | El modelo consulta DuckDB sin modificar la interfaz |
| `app-05` | Tool + reactividad | El chat actualiza la consulta que alimenta el dashboard |
| `app-06` | Tools de interfaz | El chat abre contenido en modales y recibe su resultado |
| `app-07` | Inputs vs query | Compara filtros tradicionales con una consulta solicitada por chat |
| `app-08` | Tool + mapa | El chat filtra un globo y controla su variable y cámara |
| `app-10` | Explorador manual | Busca localmente y consulta una serie del Banco Central de Chile |
| `app-11` | Chat sin tools | Integra el chat, todavía sin acceso al catálogo ni al dashboard |
| `app-12` | Chat orientador | El chat encuentra una serie y actualiza el gráfico y la tabla |
| `app-13` | Comprender la vista | El chat describe, resume e inspecciona la serie visible |

Cada carpeta entre `app-00` y `app-08` incluye un `DESCRIPTION` con su título,
resumen y paquetes de R utilizados.

En `app-02` y `app-03`, el greeting y el system prompt permanecen inline para
que todo el ejemplo se lea en un solo archivo. Desde `app-04`, cuando el prompt
empieza a crecer, se separan en `greeting.md` y `prompt.md`; ambos lenguajes
comparten esos archivos.

Las apps de países en R y Python leen `data/paises.csv`. El archivo se genera
con `R/generar-data-paises.R`, de modo que ambas implementaciones trabajan con
las mismas filas, columnas y valores.

La versión Python de `app-08` usa un globo ortográfico de Plotly. La tool de
cámara actualiza el widget existente mediante `map.widget.update_geos()`, el
equivalente práctico de un proxy: no reconstruye el mapa al cambiar el centro.
Los códigos de país y las coordenadas de cámara provienen del catálogo
Gapminder incluido en Plotly.

## Agentes y orquestación

| App | Tema |
|---|---|
| `app-20` | Flujo lineal con dos agentes |
| `app-21` | Una función orquestadora coordina dos agentes persistentes y DuckDB |

## Instalar

Se necesita R 4.6.1 y `uv`. `uv` instala automáticamente una versión de Python
compatible con `pyproject.toml`.

Instala `uv` en Windows:

```powershell
winget install --id astral-sh.uv -e
```

En macOS o Linux:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Después de clonar el repositorio, restaura ambos entornos desde la raíz:

```console
Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv')"
Rscript -e "renv::restore()"
uv sync
```

R y Python usan entornos separados y reproducibles:

- `renv.lock` fija las dependencias de las apps R.
- `uv.lock` fija las dependencias de las apps Python.

Como alternativa a `renv::restore()`, instala manualmente los paquetes R directos:

```r
install.packages(c(
  "bslib", "callr", "countrycode", "datos", "DBI", "dbplyr", "dplyr",
  "duckdb", "ellmer", "forecast", "gapminder", "ggplot2", "mapgl",
  "nycflights13", "remotes", "rnaturalearthdata", "sf", "shiny",
  "shinychat", "stringr", "tinyplot"
))

remotes::install_github("jbkunst/bcchr")
```

Esta alternativa instala versiones actuales. Para reproducir exactamente el entorno
probado del repositorio, prefiere `renv::restore()`.

## Variables de entorno

Las apps con chat necesitan `OPENAI_API_KEY`. Las apps 10 a 13 necesitan
`BCCH_TOKEN` para descargar observaciones del Banco Central de Chile.

Para R, crea un archivo `.Renviron` en la raíz:

```dotenv
OPENAI_API_KEY=tu_clave_de_openai
BCCH_TOKEN=tu_token_del_banco_central
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

## Ejecutar en R

Cada aplicación es independiente y tiene su propio `app.R`. Desde la raíz:

```r
shiny::runApp("app-00")
```

## Ejecutar en Python

Usa `uv run` para ejecutar la app dentro del entorno fijado por `uv.lock`:

```console
uv run shiny run --reload app-00/app.py
```

`renv::restore()` instala también `bcchr` desde GitHub. `uv sync` instala Shiny,
Chatlas, DuckDB, Plotly y las demás dependencias Python declaradas por el proyecto.
