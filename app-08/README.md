# App 08 · Mover el mapa e interpretar gráficos

Primero agrega movimiento de cámara con `ir_a_pais()`. Después completa `mostrar_grafico()`:
abre el modal y devuelve la misma imagen al modelo para que pueda interpretarla.

Desde la raíz del repo, con la [configuración del taller](../README.md#configurar-la-api):

```r
shiny::runApp("app-08")
```

```console
uv run --env-file .Renviron shiny run --reload app-08/app.py
```

Prueba «Vuela a Colombia» y luego «Grafica PIB per cápita versus esperanza de vida por continente».
Mover la cámara conserva el filtro y el indicador. La otra tool abre el modal y entrega su imagen al modelo.
La interpretación de imágenes usa `openai/gpt-5.6-luna`.
El paso previo en consola está en `R/04_ellmer_imagen.R` y `python/04_chatlas_imagen.py`.

## Mapa y datos

R usa un globo de MapLibre y un proxy para mover la cámara.
Python usa un globo ortográfico de Plotly y `map.widget.update_geos()` para actualizar el widget existente.
Los códigos y centros de los países de la versión Python vienen del catálogo Gapminder de Plotly.

Las dos versiones conservan los 142 países de `data/paises.csv`. En R, un país sin geometría en
Natural Earth sigue presente en las consultas, indicadores y gráficos, aunque no tenga polígono en el mapa.

## Progresión

La app centra la interfaz en el mapa y el gráfico: no conserva los filtros manuales ni la tool de tabla
de App 07. La progresión agrega capacidades, sin exigir que cada app conserve todos los controles anteriores.
La misma función de dibujo genera el gráfico del modal y la imagen entregada al modelo.
