# App 03 · Consultar los datos visibles

Agrega `resumir_datos_visibles()`: una tool que entrega al modelo un resumen de los países
mostrados en el dashboard. El saludo y el system prompt siguen dentro del código.

Desde la raíz del repo, con la [configuración del taller](../README.md#configurar-la-api):

```r
shiny::runApp("app-03")
```

```console
uv run --env-file .Renviron shiny run --reload app-03/app.py
```

R y Python comparten `data/paises.csv`, con 142 países de Gapminder.
Para regenerar ese archivo, usa `R/generar-data-paises.R` desde la raíz.

Las consolas auxiliares consultan esa misma base por continente:

```r
source("app-03/interactive-console.R", encoding = "UTF-8")
```

```console
uv run --env-file .Renviron python app-03/interactive-console.py
```
