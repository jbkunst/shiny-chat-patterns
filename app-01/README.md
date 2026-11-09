# App 01 · Explorar y filtrar datos

Agrega un dashboard de países con indicadores, gráfico y tabla.
El filtro manual cambia los datos reactivos que comparten esos outputs. Todavía no hay chat.

Desde la raíz, con los [entornos del taller](../README.md#instalar) preparados:

```r
shiny::runApp("app-01")
```

```console
uv run shiny run --reload app-01/app.py
```

Selecciona un continente y observa cómo cambian los tres outputs.
R y Python comparten `data/paises.csv`, que sirve de base para el recorrido de App 01–08.
