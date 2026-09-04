# shiny-chat-patterns

Ejemplos progresivos de patrones para construir aplicaciones Shiny con chat y tools.

## Sobre el taller

**Shiny + ellmer: patrones para conectar conversación, datos e interfaz** es un taller
práctico que recorre, paso a paso, distintas formas de incorporar modelos de lenguaje en una
aplicación Shiny para R usando `ellmer`. Partiremos desde una aplicación simple y agregaremos
conversación, acceso controlado a datos, consultas SQL, actualización del estado y acciones sobre la
interfaz, para finalizar con un dashboard conversacional que controla gráficos, tablas y mapas.

Cada capacidad se presenta como una aplicación independiente que cambia una sola idea respecto de la
anterior. Esto permite identificar con claridad qué código habilita cada patrón, cuándo resulta útil y
qué validaciones necesita. El objetivo no es reemplazar la interfaz tradicional con un chat, sino
entender cómo ambas formas de interacción pueden complementarse.

| | |
|---|---|
| **Duración** | 3 horas, con una pausa intermedia |
| **Nivel** | Intermedio; no se requiere experiencia avanzada en Shiny |
| **Audiencia** | Personas que hayan construido al menos una aplicación con R y Shiny |
| **Conocimientos previos** | R, reactividad básica y estructura de interfaz/servidor |
| **Experiencia con IA** | No se requiere experiencia previa con LLMs, chat o tools |
| **Materiales** | Aplicaciones progresivas en Shiny para R con `ellmer` |

### Objetivos

Al finalizar el taller, quienes participen podrán:

- integrar un chat en una aplicación Shiny y reconocer qué contexto puede utilizar el modelo;
- definir tools pequeñas, explícitas y validadas para consultar datos reales;
- permitir que una tool actualice valores reactivos y ejecute acciones de interfaz;
- combinar controles tradicionales con consultas expresadas en lenguaje natural; y
- reconocer los límites de seguridad entre el navegador, la aplicación y servicios externos.

### Contenidos

**Bloque 1 · De una app reactiva a una conversación con contexto**

- Dashboard y reactividad como punto de partida.
- Chat sin acceso a los datos de la aplicación.
- Primera tool para consultar los datos visibles.
- Consultas SQL de solo lectura y validación de argumentos.

**Pausa**

**Bloque 2 · Cuando el chat puede actuar sobre la aplicación**

- Actualización del estado reactivo desde una tool.
- Acciones de interfaz: tablas, gráficos y modales.
- Comparación entre filtros tradicionales y consultas por chat.
- Control de una visualización geográfica y su cámara.

La presentación vive en `slides/` y se publicará en
<https://jkunst.com/shiny-chat-patterns/>. El QMD, el tema y los scripts se mantienen juntos para que
la carpeta pueda renderizarse y publicarse como una unidad.

## Sobre el repositorio

La idea es que cada aplicación agregue **una sola pieza nueva** y conserve el
mismo dominio de datos durante el recorrido principal. La secuencia también
puede usarse como base para demostraciones o talleres.

Todas las apps usan `page_sidebar()` para mantener una estructura consistente
y concentrar cada ejemplo en el patrón que introduce. Desde `app-00` hasta
`app-08`, cada carpeta contiene `app.R` y `app.py` para comparar la misma idea
en ambos lenguajes. Las versiones de chat usan `ellmer` en Shiny para R y
`chatlas` en Shiny para Python.

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

## Alcance

El taller y este README documentan por ahora el recorrido estable entre `app-00` y `app-08`. El
repositorio podrá seguir creciendo con nuevos dashboards, fuentes de datos y patrones de agentes u
orquestación. Esas extensiones se incorporarán a la documentación cuando formen una nueva secuencia
progresiva y autocontenida.

## Instalar

Se necesita R 4.6.1 y [`uv`](https://docs.astral.sh/uv/). Después de clonar el repositorio, restaura
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
