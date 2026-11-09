# App 00 · Conectar inputs y outputs

Introducción a Shiny con controles, un gráfico y una opción de pronóstico.
R y Python leen la misma serie desde `data/air-passengers.csv`; no hay chat ni se necesita una clave de API.
Las slides incluyen una versión que se ejecuta en el navegador mediante Shinylive.

Desde la raíz, con los [entornos del taller](../README.md#instalar) preparados:

```r
shiny::runApp("app-00")
```

```console
uv run shiny run --reload app-00/app.py
```

Prueba cambiar el título, la cantidad de puntos y la opción de pronóstico.
