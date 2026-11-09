# App 09 v2 · Conversar con herramientas MCP

Variante de App 09 con `page_chat()` y `chat_server()`, sin dashboard ni tools locales.
El chat usa Luna y registra las nueve herramientas que ofrece el MCP, sin seleccionar ni quitar argumentos.
La interfaz muestra las llamadas y respuestas del MCP. El cliente se crea dentro de cada sesión Shiny.

Desde la raíz, con el entorno restaurado:

```r
readRenviron(".Renviron")
shiny::runApp("app-09-v2")
```

Prueba «¿Cuál fue la esperanza de vida al nacer en Colombia en 2023?» y luego
«Compara ese dato con Chile y Perú para el mismo año».
Esta variante puede consultar series temporales y responder en el chat.
El cliente usa los parámetros por defecto del modelo y pide respuestas concisas.

`chat_server()` se encarga de recibir mensajes, ejecutar herramientas y transmitir las respuestas.
`mcp.json` configura el servidor comunitario de
[cyanheads](https://github.com/cyanheads/worldbank-mcp-server).
La fuente de datos es el Banco Mundial. El MCP no requiere un token propio; el modelo usa `OPENAI_API_KEY`.
Las peticiones al MCP tienen un timeout configurado de 60 segundos.

## Registro directo

```r
chat$set_tools(mcp_tools("mcp.json"))
```

Se usa directamente la lista que devuelve `mcp_tools()`, sin seleccionar tools ni modificar sus esquemas.
La App 09 original mantiene el dashboard y sus tools locales para guardar y leer la carga.

