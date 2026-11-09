# App 02 · Conversar sin acceso a los datos

Agrega un chat al dashboard. El modelo puede conversar, pero todavía no tiene tools para consultar
los datos visibles ni cambiar la interfaz. El saludo y el system prompt permanecen dentro del código.

Desde la raíz del repo, con la [configuración del taller](../README.md#configurar-la-api):

```r
shiny::runApp("app-02")
```

```console
uv run --env-file .Renviron shiny run --reload app-02/app.py
```

También puedes aislar la conversación en la consola, sin la interfaz de Shiny:

```r
source("app-02/interactive-console.R", encoding = "UTF-8")
```

La versión Python está en `interactive-console.py` y se ejecuta también desde la raíz.
