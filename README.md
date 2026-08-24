# shiny-chat-patterns

Ejemplos progresivos de patrones para construir aplicaciones Shiny con chat y tools.

La idea es que cada aplicación agregue **una sola pieza nueva** y conserve el
mismo dominio de datos durante el recorrido principal. La secuencia también
puede usarse como base para demostraciones o talleres.

Todas las apps usan `page_sidebar()` para mantener una estructura consistente
y concentrar cada ejemplo en el patrón que introduce. Desde `app-00` hasta
`app-06`, cada carpeta contiene `app.R` y `app.py` para comparar la misma idea
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

## Agentes y orquestación

| App | Tema |
|---|---|
| `app-20` | Flujo lineal con dos agentes |
| `app-21` | Una función orquestadora coordina dos agentes persistentes y SQLite |

## Ejecutar en R

Cada aplicación es independiente y tiene su propio `app.R`.

```r
shiny::runApp("app-00")
```

Para usar las apps con chat se necesita `OPENAI_API_KEY` en `.Renviron`.
Las apps 10 a 13 usan el catálogo versionado `data/series_catalog.rds` y necesitan
`BCCH_TOKEN` sólo para descargar las observaciones seleccionadas.

```r
install.packages(c(
  "brand.yml", "bslib", "countrycode", "datos", "DBI", "dplyr", "duckdb", "ellmer",
  "forecast", "gapminder", "mapgl", "rnaturalearthdata", "sf", "shiny", "shinychat",
  "tinyplot"
))
```

`bcchr` se instala desde GitHub:

```r
remotes::install_github("jbkunst/bcchr")
```

## Ejecutar en Python

Desde la raíz del repositorio:

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
shiny run --reload app-00/app.py
```

En Windows, la activación equivalente es `.venv\Scripts\activate`.
Desde `app-02`, define `OPENAI_API_KEY` en el entorno antes de iniciar la app.
