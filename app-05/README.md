# App 05 · Actualizar el dashboard desde el chat

Extiende el patrón SQL de App 04: `actualizar_dashboard()` cambia la consulta reactiva que alimenta la vista.
La consulta se ejecuta antes de cambiar el estado; si falla, el dashboard conserva la vista anterior.
El resultado también permite devolver al modelo la cantidad de registros.

Desde la raíz, con la [configuración del taller](../README.md#configurar-la-api):

```r
shiny::runApp("app-05")
```

```console
uv run --env-file .Renviron shiny run --reload app-05/app.py
```

Pide «Muestra solo los países de Europa en el dashboard».
El agente genera SQL, llama a la tool y cambia la consulta actual. Los datos se recalculan y los outputs
muestran ese nuevo resultado. Las restricciones SQL de solo lectura se conservan.
