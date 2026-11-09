# App 06 · Mostrar tablas y gráficos

Agrega `mostrar_tabla()` y `mostrar_grafico()`, tools que abren modales desde el chat.
Devuelven una confirmación al modelo; todavía no le entregan el contenido de la tabla ni la imagen.

Desde la raíz, con la [configuración del taller](../README.md#configurar-la-api):

```r
shiny::runApp("app-06")
```

```console
uv run --env-file .Renviron shiny run --reload app-06/app.py
```

Prueba «Abre una tabla con 10 países» o pide un gráfico de PIB per cápita y esperanza de vida.
Observa el modal y la confirmación del chat.
Interpretar la imagen es el paso posterior de [App 08](../app-08/).
