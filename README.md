# shiny-chat-patterns

Ejemplos progresivos de patrones para construir aplicaciones Shiny con chat y tools.

La idea es que cada aplicación agregue **una sola pieza nueva** y conserve el
mismo dominio de datos durante el recorrido principal. La secuencia también
puede usarse como base para demostraciones o talleres.

Todas las apps usan `page_sidebar()` para mantener una estructura consistente
y concentrar cada ejemplo en el patrón que introduce.

## Recorrido principal

| App | Nueva idea | Ejemplo |
|---|---|---|
| `app-00` | Shiny desde cero | Widgets básicos conectados a dos outputs mínimos |
| `app-01` | Shiny básico | Dashboard de pingüinos con un filtro manual |
| `app-02` | Chat dentro de Shiny | El dashboard incorpora un chat, todavía sin acceso a los datos |
| `app-03` | Primera tool | El modelo consulta un resumen real de los pingüinos |
| `app-04` | Tool SQL | El modelo consulta una tabla DuckDB sin modificar la interfaz |
| `app-05` | Tool + reactividad | El chat actualiza la consulta que alimenta el dashboard |
| `app-06` | Tools de interfaz | El chat abre tablas y gráficos dentro de modales |

En `app-02` y `app-03`, el greeting y el system prompt permanecen inline para
que todo el ejemplo se lea en un solo archivo. Desde `app-04`, cuando el prompt
empieza a crecer, se separan en `greeting.md` y `prompt.md`.

## Extensiones

| App | Tema |
|---|---|
| `app-10` | Mapa mundial controlado por chat |
| `app-11` | Flujo lineal con dos agentes |

## Ejecutar

Cada aplicación es independiente y tiene su propio `app.R`.

```r
shiny::runApp("app-00")
```

Para usar las apps con chat se necesita `OPENAI_API_KEY` en `.Renviron`.

```r
install.packages(c(
  "bslib", "datos", "DBI", "duckdb", "ellmer", "shiny", "shinychat"
))
```

Las extensiones también requieren `leaflet`, `sf`, `gapminder`, `countrycode`
y `rnaturalearthdata`.
