# App 09 v2 · Conversar con herramientas MCP

Variante de App 09 con `page_chat()` y `chat_server()`, sin dashboard ni tools locales.
El chat usa Luna y registra todas las herramientas del MCP del FMI, sin seleccionar ni quitar argumentos.
La interfaz muestra las llamadas y respuestas del MCP. El cliente se crea dentro de cada sesión Shiny.

`R/06_ellmer_mcp.R` ofrece el mismo ejemplo básico en consola, con `live_console(chat)` para seguir conversando.
Desde la raíz, ejecútalo con `source("R/06_ellmer_mcp.R", encoding = "UTF-8")`.

Desde la raíz, con el entorno restaurado:

```r
readRenviron(".Renviron")
shiny::runApp("app-09-v2")
```

Prueba «Según WEO del FMI, ¿cuál fue la tasa de desempleo de España en 2023?» y luego
«Compara ese dato con Chile para el mismo año».
Esta variante puede consultar series temporales y responder en el chat.
El cliente usa los parámetros por defecto del modelo y pide respuestas concisas.

`chat_server()` se encarga de recibir mensajes, ejecutar herramientas y transmitir las respuestas.
`mcp-imf.json` configura el servidor comunitario de
[cyanheads para el FMI](https://github.com/cyanheads/imf-mcp-server).
La fuente de datos es el FMI. El MCP no requiere un token propio; el modelo usa `OPENAI_API_KEY`.
Las peticiones al MCP tienen un timeout configurado de 60 segundos.

## Registro directo

```r
chat$set_tools(mcp_tools("mcp-imf.json"))
```

Se usa directamente la lista que devuelve `mcp_tools()`, sin seleccionar tools ni modificar sus esquemas.
App 09 mantiene un dashboard con X e Y y sus tools locales para guardar y leer la carga.
App 09 v3 conserva el dashboard configurable anterior como referencia fuera de las slides.

## Comparar con el Banco Mundial

Se conserva `mcp.json` con el endpoint del Banco Mundial. Para probarlo, cambia solo el archivo:

```r
chat$set_tools(mcp_tools("mcp.json"))
```

La prueba real con el FMI registró cinco tools y respondió 12,185 % para España en 2023,
sin el warning de tokens. El modelo corrigió una llamada con argumentos inválidos antes de consultar el dato.
Con el Banco Mundial, el registro completo produjo una respuesta vacía y el warning de tokens
en el entorno probado. Estos resultados corresponden a Luna con ellmer 0.4.2 y pueden cambiar con el servidor.

