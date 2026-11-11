# Convenciones del repositorio

## Propósito

Este repositorio reúne ejemplos pequeños y progresivos de patrones de chat en
Shiny. Puede servir como base para un taller, pero cada ejemplo debe ser útil por
sí mismo.

Cada app debe introducir una idea principal y conservar la mayor cantidad de
código posible de la app anterior. El cambio relevante debe ser fácil de
identificar en una slide o en un diff.

Desde `app-00` hasta `app-08`, conserva `app.R` y `app.py` en la misma carpeta.
Ambas versiones deben enseñar el mismo patrón, compartir los datos y prompts, y
usar una implementación idiomática en cada lenguaje en vez de una traducción
literal línea por línea.

## Secuencia de apps

Reserva `00–49` para el recorrido del taller, `50–89` para casos de aplicación y `90+` para experimentos.

- `app-00`: widgets y outputs de Shiny, sin chat.
- `app-01`: un dashboard reactivo pequeño.
- `app-02`: agrega chat, sin tools ni acceso a los datos de la app.
- `app-03`: agrega una tool simple que consulta datos reales.
- `app-04`: agrega una tool SQL de solo lectura. Desde esta app, mueve el
  greeting y el system prompt a archivos Markdown.
- `app-05`: permite que una tool actualice los datos reactivos mostrados por
  Shiny.
- `app-06`: agrega tools de interfaz como `mostrar_tabla()` y `mostrar_grafico()` que
  abren modales y devuelven una confirmación, sin enviar su contenido al modelo.
- `app-07`: compara filtros tradicionales con una consulta solicitada por chat.
- `app-08`: conserva el globo y las actualizaciones de cámara tipo proxy; completa
  `mostrar_grafico()` para abrir el modal y devolver la imagen al modelo.
- `app-09`: dashboard sencillo en R con el MCP comunitario de cyanheads para el FMI.
  Registra todas sus tools directamente con set_tools(mcp_tools("mcp.json")), sin adaptar sus esquemas.
  Sin SQL ni datos numéricos iniciales. Solo data() guarda la carga que alimenta todos los outputs.
  Las filas tienen pais, anio, x e y; los metadatos conservan columna, indicador, nombre y unidad.
  Y es la variable de interés: se usa en el mapa y en el eje vertical; X es el eje horizontal.
  La tabla muestra pais, anio, x e y. El gráfico usa tamaño fijo, color uniforme y ejes lineales.
  Para un mapa se puede omitir X. filas_vacias conserva las columnas opcionales al guardar.
  guardar_datos(datos, variables) reemplaza la carga; ver_datos() la devuelve sin modificarla.
  Solo se dibujan países y puntos recibidos. Sin filtros regionales, series ni configuración de escalas.
  Usa theme_minimal(), ejes vacíos sin datos y la misma separación Visualización/Datos de la variante anterior.
  La demo usa crecimiento en X e inflación en Y y en el mapa; compara América Latina en 2023 y 2020.
  La comparación cacheada sigue siendo del Banco Mundial: esperanza de vida en Colombia en 2023.
  Las slides muestran solo app-09 y app-09-v2. La versión Python sigue pendiente.
- `app-09-v2`: variante mínima en R con page_chat(), chat_server() y un cliente ellmer por sesión.
  Conversa con herramientas MCP sin dashboard ni tools locales de visualización.
  Registra todas las tools del FMI con set_tools(mcp_tools("mcp-imf.json")), sin adaptar sus esquemas.
  Conserva mcp.json con el Banco Mundial como alternativa para comparar.
- `app-09-v3`: variante configurable conservada como referencia fuera de las slides y del catálogo.
  Mantiene la extensión en R con el MCP comunitario de cyanheads para datos del FMI.
  Registra todas sus tools directamente con mcp_tools("mcp.json"), sin ajustes ni source auxiliar.
  mcp-tools.R y mcp-worldbank.json se conservan como ajuste específico del MCP del Banco Mundial.
  Sin SQL ni datos numéricos iniciales. Solo data() guarda filas y metadatos para todos los outputs.
  Las filas tienen pais, anio, x_var, y_var, size_var, color_var y map_var.
  Los metadatos conservan indicador, nombre y unidad.
  configurar_grafico(log, tamano) cambia ejes y tamaño, fuera de data() y de guardar_datos().
  El tamaño usa área proporcional por defecto; log10 permite comprimir su rango visual.
  El agente consulta el MCP y pasa la carga completa a guardar_datos(), que reemplaza la anterior.
  ver_datos() devuelve esa carga sin modificarla. No hay region(), data_view() ni estado de series.
  Mapa y dispersión dibujan solo los países y puntos recibidos. No hay filtros regionales en R.
  El mapa usa map_var; la dispersión usa x_var, y_var, size_var y color_var de un año común.
  No muestra series.
  Usa theme_minimal() y un canvas con ejes cuando no hay datos para la dispersión.
  Debajo de los indicadores, navset_card_tab() separa Visualización de Datos.
  Visualización contiene dos cards con título: Mapa y Gráfico; Datos contiene la tabla.
  La comparación sin y con MCP usa respuestas reales cacheadas; no se consulta al modelo al renderizar slides.
  La comparación histórica sigue siendo del Banco Mundial: esperanza de vida en Colombia en 2023.
  La demo del FMI usa inflación en el mapa, crecimiento en X, inflación en Y y población como tamaño.
  Compara América Latina en 2023 y 2020, con ejes lineales para conservar crecimientos negativos.
  La versión Python queda pendiente hasta revisar el ejemplo R.
- `app-50-colombia-territorial`: caso territorial con datos departamentales de
  Colombia y chat flotante.
- `app-51-banrep-sdmx`: caso económico que consulta series de Banrep mediante
  SDMX REST/XML.
- `app-90-orquestacion-simulada-experimental`: flujo de dos agentes con ejecución simulada.
- `app-91-orquestacion-duckdb-experimental`: dos agentes persistentes y consultas reales en DuckDB.
- `app-99`: solución en R del ejercicio con pingüinos, fuera del recorrido principal.
  Excluida de run_all_apps, incluso con experimentales. Conserva solo app.R, sin DESCRIPTION ni README.
  Todo en app.R: dplyr filtra por especie, una tool ajusta lm con X e Y y devuelve
  summary como texto con capture.output. Usa page_fillable con chat_ui y argumentos type_string.
  Conserva observeEvent, stream_async y chat_append; sin page_chat, chat_server ni gráfico.
  El ejercicio va después de App 05; actualizar un gráfico queda como desafío adicional.
  R/ejercicio_pinguinos.R es el punto de partida: muestra los datos sin asignación y entrega
  función, prueba directa, UI y servidor, dejando pendiente registrar la herramienta.

Agrega una app intermedia en vez de introducir varios conceptos nuevos en el
mismo paso.

## Interfaz

Estas convenciones de UI mínima y continuidad aplican al recorrido de enseñanza `app-00`–`app-08`.
Los casos `app-50-colombia-territorial` y `app-51-banrep-sdmx` son excepciones deliberadas: pueden
usar estilos y layouts propios para motivar y mostrar aplicaciones concretas de los patrones.
Conserva su identidad visual; no los simplifiques para hacerlos iguales a las apps de enseñanza.

- Usa `bslib::page_sidebar()` en R y `ui.page_sidebar()` en Python como
  estructura por defecto.
- Ubica el chat y los controles manuales en el sidebar y el resultado en el área
  principal.
- Mantén la UI intencionalmente mínima y consistente entre apps consecutivas.
- Evita navbars, tabs, accordions, paneles flotantes, cards decorativos y layouts
  personalizados, salvo que ese comportamiento sea el patrón demostrado.
- Conserva un output visible solo cuando ayude a explicar el comportamiento del
  chat: valores reactivos, un modal abierto por una tool, un mapa o el resultado
  de un agente.
- Prefiere el mismo dataset y la misma estructura de dashboard durante el
  recorrido principal.
- En R, App 00–09 usan thematic::thematic_shiny(font = "auto") y ragg para heredar la fuente de la UI.

## Chat, prompts y tools

- Crea clientes con `ellmer::chat("proveedor/modelo")` en R y `ChatAuto("proveedor/modelo")` en Python.
  Conserva el modelo de cada ejemplo; el taller usa OpenAI, pero el constructor permite cambiar de proveedor.
- Mantén el greeting y el system prompt inline mientras quepan cómodamente en
  una expresión corta. Usa `greeting.md` y `prompt.md` cuando crezcan.
- Enfoca cada app en una capacidad nueva: conversación, acceso a datos, SQL,
  actualización reactiva, acciones de interfaz u orquestación.
- Define tools con nombres explícitos, descripciones breves y argumentos
  acotados.
- Prioriza que cada ejemplo enseñe su capacidad principal. Usa esquemas para describir los argumentos
  y evita comprobaciones duplicadas o límites de filas que no aporten al patrón.
- Conserva las restricciones SQL y los controles necesarios para ejecutar la app. El ejemplo avanzado
  de dos tools del clima conserva las validaciones de ciudad y fecha.
- Los ejemplos SQL deben ser de solo lectura y estar restringidos a la tabla
  correspondiente.
- App 04–08 llaman `consultar_tabla(consulta)` a la tool SQL de lectura sobre la tabla `paises`.
  Conserva ese nombre en R, Python, prompts, consolas, documentación y slides.
- No inventes resultados numéricos cuando una tool pueda obtenerlos desde los
  datos.

## Ejemplos de consola y slides

- Después de modificar una slide o su diagrama, informa su línea de inicio actual en `slides/index.qmd`
  con un enlace al archivo y la línea, para abrirla y renderizarla directamente en el Viewer.
- El README raíz es la guía del taller: conserva el recorrido, las tablas y la configuración común.
  Documenta la implementación, preparación de datos y particularidades en el README de cada app.
- Conserva parejas equivalentes entre `R/01_ellmer.R`–`R/04_ellmer_imagen.R` y los scripts de `python/`.
- Carga todas las librerías e imports al inicio. Cada script debe poder ejecutarse de forma independiente.
- En los ejemplos 02–04, pregunta sin tools, regístralas y vuelve a preguntar en la misma conversación.
- Mantén equivalentes las consolas auxiliares R/Python de App 02–04 y usa los datos compartidos.
- Divide las slides en los tres capítulos principales y una extensión MCP después de App 08.
  Los capítulos son azules; los paquetes, claros.
- App 01–08 terminan con cómo ejecutar la app, qué hacer y qué observar. App 00 usa solo Shinylive.
- Los títulos de slides de una app siguen `App NN · Nombre · Tipo`, conservando el mismo nombre
  en todo su bloque. Reserva `Código` solo para la app Shiny completa, una vez por app.
  Los fragmentos nombran su contenido, por ejemplo `Reactividad`, `Cámara`, `Imagen` o `Datos`;
  los scripts auxiliares usan `Consola`. Usa también `Patrón`, `Diagrama` y `Ejecutar` según corresponda.
  App 00 termina con `Explorar`.
  Usa siempre `·` como separador y solo esas tres partes, sin subtipos como `Código · Datos`.
- En los diagramas, conserva el contexto necesario de la app anterior en gris y destaca la capacidad
  nueva en azul. Incluye las conexiones entre inputs, datos y outputs cuando sigan presentes.
  No arrastres componentes eliminados ni sugieras actualizaciones reactivas donde se usa `isolate()`.
  Ajusta la distribución y reduce la fuente si hace falta, verificando que siga siendo legible al proyectar.
- En las tools de visualización del diagrama, muestra los argumentos en gris tenue para distinguir
  los parámetros que elige el agente de los datos reactivos que usa la tool.
- Conserva el espaciado general de `slides/assets/theme.scss`: `--content-gap: 40px`,
  `--code-gap: 48px` entre texto y código o resultados, y `--section-gap: 56px` antes de subtítulos.
  Incluye los contenedores `.cell` de Quarto en esas reglas; no agregues márgenes específicos por slide.
- Al mostrar `head(datos, n)`, aclara que son las primeras `n` filas, no el dataset completo.
- Al agregar, eliminar o mover líneas en un archivo mostrado con `code_block()`, revisa y actualiza
  sus rangos en `slides/index.qmd`. Comprueba contra el archivo fuente que cada rango resalte
  exactamente el código descrito por su comentario, no solo que los números de línea existan.

## Estilo de código

- Optimiza los ejemplos para proyectarlos en slides y compararlos entre apps.
- Mantén las llamadas simples en una línea cuando sigan siendo legibles. Por
  ejemplo: `renderTable(head(data(), 10), striped = TRUE, hover = TRUE)`.
- Usa varias líneas para lógica o argumentos semánticamente distintos.
- Mantén las líneas en 110 caracteres o menos, incluidos los prompts Markdown.
- Prefiere R base y el pipe nativo `|>` cuando permitan reducir el ejemplo.
- En Python, usa type hints y docstrings en las tools para generar sus esquemas.
- Evita módulos, clases, helpers, dependencias y abstracciones que no sean
  necesarias para enseñar el patrón.
- Conserva secciones consistentes: data, prompt, user interface, server y tools
  cuando correspondan.
- Coloca el código inmediatamente después del encabezado de cada sección, sin
  una línea en blanco intermedia.

## Antes de publicar

- Confirma que cada app pueda ejecutarse de forma independiente desde su carpeta.
- Revisa que las versiones R y Python produzcan el mismo comportamiento visible.
- Revisa que dos apps consecutivas difieran principalmente en el concepto nuevo.
- Busca complejidad accidental en la UI y líneas de más de 110 caracteres.
- Parsea o ejecuta las apps modificadas cuando estén disponibles sus paquetes.
- Para Python, ejecuta
  `python -m compileall app-00 app-01 app-02 app-03 app-04 app-05 app-06 app-07 app-08`.
- Actualiza la secuencia del README al agregar, eliminar o renumerar una app.
