# App 51 · Banrep + SDMX

Caso en R que consulta series del Banco de la República y muestra un gráfico y sus últimas observaciones.
Separa resolver la serie, consultar los datos, mostrar el resultado e inspeccionar la vista.

Desde la raíz, con el entorno y la [clave del modelo](../README.md#configurar-la-api) preparados:

```r
shiny::runApp("app-51-banrep-sdmx")
```

## Consulta en vivo

`consultar_sdmx()` llama al servicio público del Banco de la República mediante HTTP y procesa su XML.
La app necesita internet para descargar las observaciones. Usa tools locales de R, no un servidor MCP.

El catálogo incluido en `app.R` contiene TRM, tasa de política monetaria, DTF y UVR, con frecuencia diaria.
Prueba «Consulta la TRM entre enero y marzo de 2024 y muéstrala».
El modelo resuelve la serie, consulta el período y pide visualizar el resultado.

Los datos consultados se conservan en la sesión. `visualizar_serie()` utiliza una serie ya descargada;
`inspeccionar_vista()` permite responder sobre lo que muestra el gráfico.
El saludo y el system prompt están en `greeting.md` y `prompt.md`.
