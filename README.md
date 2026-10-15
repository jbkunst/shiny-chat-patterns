# shiny-chat-patterns

Ejemplos progresivos de patrones para construir aplicaciones Shiny con chat y tools.

## Sobre el taller

**Shiny + ellmer: patrones para conectar conversación, datos e interfaz** es un taller
práctico que recorre, paso a paso, distintas formas de incorporar modelos de lenguaje en una
aplicación Shiny usando `ellmer`. Partiremos desde una aplicación simple y agregaremos
conversación, acceso controlado a datos, consultas SQL, actualización del estado y acciones sobre la
interfaz, para finalizar con un dashboard conversacional que controla gráficos, tablas y mapas.

Cada patrón se presenta como una aplicación independiente que cambia una sola idea respecto de la
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

### Objetivos

Al finalizar el taller, quienes participen podrán:

- Integrar un chat en una aplicación Shiny y reconocer qué contexto puede utilizar el modelo.
- Definir tools pequeñas, explícitas y validadas para consultar datos reales.
- Permitir que una tool actualice valores reactivos y ejecute acciones de interfaz.
- Combinar controles tradicionales con consultas expresadas en lenguaje natural.
- Reconocer los límites de seguridad entre el navegador, la aplicación y servicios externos.

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

`app-00` establece el punto de partida y `app-01` presenta el dashboard común de países. Desde
`app-02` hasta `app-06`, cada aplicación incorpora **una sola idea nueva** y conserva tanto como sea
posible del paso anterior. `app-07` es una pausa comparativa; `app-08` retoma la línea principal desde
`app-06` y agrega el mapa. Así, cada cambio se reconoce en el código y puede mostrarse en un taller.

Todas las apps usan `page_sidebar()` para mantener una estructura consistente
y concentrar cada ejemplo en el patrón que introduce. Desde `app-00` hasta
`app-08`, cada carpeta contiene `app.R` y `app.py` para comparar la misma idea
en ambos lenguajes. Las versiones de chat usan `ellmer` y `chatlas`, respectivamente.

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

## Casos de aplicación

Estas apps trasladan los patrones del recorrido principal a fuentes colombianas. No continúan la
secuencia incremental `app-00`–`app-08`; muestran cómo organizar tools por responsabilidad.

| App | Fuente | Patrón |
|---|---|---|
| `app-91-colombia-territorial` | DANE, CNPV 2018 | Resuelve territorios, consulta indicadores, actualiza el mapa e inspecciona la vista |
| `app-92-banrep-sdmx` | Banco de la República | Resuelve un `flow_id`, consulta SDMX REST/XML, grafica la serie e inspecciona sus datos |

`app-91-colombia-territorial` incluye datos departamentales locales para funcionar durante el
taller. Para reconstruirlos desde el servicio ArcGIS ejecuta, dentro de su carpeta:

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
las mismas filas, columnas y valores.

La versión Python de `app-08` usa un globo ortográfico de Plotly. La tool de
cámara actualiza el widget existente mediante `map.widget.update_geos()`, el
equivalente práctico de un proxy: no reconstruye el mapa al cambiar el centro.
Los códigos de país y las coordenadas de cámara provienen del catálogo
Gapminder incluido en Plotly.

## Aplicaciones experimentales

Las carpetas con sufijo `-experimental` contienen aplicaciones en exploración. Todavía no forman una
secuencia formal ni están incorporadas al curso.

## Alcance

El curso comprende `app-00`–`app-08`. Las aplicaciones experimentales quedan fuera de este alcance
mientras no sean formalizadas e incorporadas al material del curso.

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
