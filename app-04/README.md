# App 04 · Explorar los datos con SQL

Reemplaza el resumen fijo por `consultar_paises()`, que ejecuta consultas SQL sobre los datos.
Consultar devuelve resultados al chat; todavía no cambia el dashboard.

Desde la raíz del repo, con la [configuración del taller](../README.md#configurar-la-api):

```r
shiny::runApp("app-04")
```

```console
uv run --env-file .Renviron shiny run --reload app-04/app.py
```

La tabla `paises` se carga en DuckDB desde `data/paises.csv`.
Las consultas se restringen a `SELECT` sobre esa tabla y se deshabilita el acceso externo de DuckDB.
`validar_select()` es una comprobación básica para el ejemplo.

Desde esta app, R y Python comparten `greeting.md` y `prompt.md`.
Las consolas auxiliares reutilizan la base y el prompt; se ejecutan desde la raíz:

```r
source("app-04/interactive-console.R", encoding = "UTF-8")
```

```console
uv run --env-file .Renviron python app-04/interactive-console.py
```
