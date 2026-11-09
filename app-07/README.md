# App 07 · Combinar controles y conversación

Reúne filtros manuales y consultas solicitadas por chat sobre el mismo dashboard.
Permite comparar ambos caminos y utilizarlos como complemento.

Desde la raíz del repo, con la [configuración del taller](../README.md#configurar-la-api):

```r
shiny::runApp("app-07")
```

```console
uv run --env-file .Renviron shiny run --reload app-07/app.py
```

Prueba un filtro con los controles y luego pide una selección equivalente por chat.
Observa cómo se actualizan los indicadores, el gráfico y la tabla.

Conserva las tools de interfaz de App 06: abren tablas y gráficos en modales y devuelven
una confirmación. Todavía no entregan el contenido del modal al modelo.
R y Python comparten `data/paises.csv`, `greeting.md` y `prompt.md`.
