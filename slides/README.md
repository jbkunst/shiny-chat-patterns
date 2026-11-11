# Slides del taller

La fuente visual de la presentación vive en esta carpeta y se publica en
<https://jkunst.com/shiny-chat-patterns/>.
El render lee también los ejemplos de `R/` y los `app.R` del recorrido principal.

## Estructura

- `index.qmd`: fuente Quarto y contenido del taller.
- `index.html`: presentación renderizada por Quarto.
- `assets/theme.scss`: fuentes, colores y todos los estilos propios de la presentación.
- `assets/slides-contrast.css`: ajustes opcionales para proyector y salas con luz ambiental.
- `assets/cover.html`: estructura de la visualización animada de portada.
- `assets/cover.js`: animación de portada inspirada en el landing de jkunst.com.
- `assets/code-highlights.js`: resaltado y scroll de los archivos completos con una sola copia del código.
- `assets/code-tooltips.js`: posición de las anotaciones durante el resaltado y el scroll.
- `_extensions/mcanouil/codefrag/`: navegación progresiva por anotaciones de código.
- La demo de `app-00` se ejecuta en el navegador mediante Shinylive.

## Contraste para proyector

El YAML de `index.qmd` carga el diseño habitual y deja comentada la capa de contraste:

```yaml
    theme: [default, assets/theme.scss]
    # css: assets/slides-contrast.css
```

Para activarla, quita únicamente el `#` de la última línea y vuelve a renderizar:

```yaml
    theme: [default, assets/theme.scss]
    css: assets/slides-contrast.css
```

Para desactivarla, comenta de nuevo la línea `css:` y renderiza. El tema conserva el diseño habitual;
el CSS adicional se carga después y contiene solo los cambios de contraste.

`theme.scss` reúne las importaciones de fuentes (`scss:uses`), las variables que configuran el tema
base (`scss:defaults`) y las reglas propias (`scss:rules`). No hay un CSS base adicional.

La variante oscurece los textos grises, usa peso 400 en párrafos y listas, aumenta el código
a 22 px (21 px en archivos completos y resultados), refuerza los números de línea y los colores
del código, y mantiene legibles las líneas fuera del paso resaltado. Los diagramas conservan
el contexto gris y las novedades azules, con textos más oscuros y flechas más gruesas.
Conserva las portadas, el espaciado y el límite de altura del código; los bloques largos usan scroll.
Los SVG originales no se modifican: los ajustes se aplican al render de las slides.

Estos ajustes no sustituyen una prueba desde el fondo de la sala con el proyector real.

## Arquitectura visual

Una sola slide de motivación presenta CensoLab y BCCh Studio antes del recorrido del taller.
Incluye una explicación breve de la conexión entre preguntas, datos y acciones, seguida de dos columnas.
El contenido usa la utilidad general `.content-centered` para centrarse verticalmente bajo el título.
Cada columna muestra el nombre y la captura enlazados a la aplicación. Las imágenes originales provienen
de `kpstudio.io`, se guardan en `assets/apps/` y la fuente queda en notas.

Después de «El recorrido del taller», las slides «Antes de partir» presentan dos rutas de preparación:
ZIP de GitHub con `R/instalar.R` e `install.packages()`, o Git con `renv::restore()`.
La primera evita que renv se active automáticamente en esa copia; la segunda restaura las versiones fijadas.
En Positron se abre la carpeta; en RStudio se puede abrir `shiny-chat-patterns.Rproj` (opcional).
Python queda como alternativa secundaria en las notas. Después se configura `.Renviron`. La primera prueba
carga ellmer y `.Renviron` y consulta el modelo para comprobar la conexión.
Los comandos se ejecutan desde la raíz. `.Rprofile` activa `renv` cuando encuentra `.git`;
Python carga la clave con `--env-file`.
Entre los entornos y la prueba de API se presenta OpenAI como proveedor del taller, con GPT-5 nano
y GPT-5.6 Luna. Los mismos patrones pueden aplicarse
con Anthropic u otros proveedores que admitan las capacidades de cada ejemplo.

La sección «Antes de empezar», agrupa la motivación, el recorrido y la preparación del entorno.
Los capítulos no llevan número; la numeración se reserva para las apps.
Los capítulos y el cierre usan encabezados `#` con `.section-slide`; las slides internas usan `##`.
`slide-level: 2` y `navigation-mode: vertical` agrupan cada capítulo en una columna en la vista general
(`O` o `Esc`). Las flechas izquierda/derecha cambian de capítulo, arriba/abajo recorren sus slides y
Espacio avanza por todo el recorrido. Los paquetes conservan `##` y `.package-slide` dentro del capítulo.
Los estilos se aplican a las slides internas, sin dar formato de slide al contenedor de cada columna.
En la vista general, la slide actual usa un contorno amarillo con halo oscuro y brillo suave para
distinguirla sobre las portadas azules y las slides claras. El efecto solo se aplica mientras `O` está activo.
El fondo exterior y el resaltado siguen únicamente la slide del capítulo activo; las slides recordadas
en otros capítulos no deben cambiar el fondo al usar ventanas con proporciones distintas de 16:9.

El recorrido se divide en tres capítulos: preparar y conversar (App 00–02), consultar y actualizar
(App 03–05) y actuar sobre la interfaz (App 06–08). App 01–08 terminan con «Ejecutar»:
comando de R,
acción o pregunta sugerida y comportamiento a observar. Ejecuta los comandos desde la raíz del repositorio.
App 00 muestra solo la demo Shinylive, con un visor de 650 px y la app al 80 % de escala.
No incluye comando de ejecución porque ya está funcionando en el navegador. El zoom se aplica
al HTML de esa app embebida, sin cambiar la escala de las slides ni la app local.
Las demos usan los mismos márgenes generales para títulos, párrafos y código que el resto del contenido.

Después de App 08, el cuarto capítulo continúa el recorrido principal con MCP y App 09, por ahora solo en R.
Incluye una definición breve, una comparación real cacheada sin y con MCP, el código de la app y
«Ejecutar». cyanheads mantiene el servidor comunitario; la demo usa datos del FMI.
La tabla lee `app-09/data/comparacion.json`: pregunta neutral sobre esperanza de vida en Colombia en 2023.
La comparación se identifica como histórica del Banco Mundial, sin presentarla como una ejecución del FMI.
La demo colorea América Latina por inflación y agrega crecimiento en X en 2023 y 2020.
App 09 usa un solo data() con pais, anio, x e y, más nombres, indicadores y unidades.
Y es la variable de interés: se comparte entre el color del mapa y el eje vertical del gráfico.
El agente arma esa carga desde el MCP y llama a guardar_datos(); ver_datos() lee lo mostrado.
La slide «App 09 · Conectar con MCP · Diagrama» muestra agente/MCP, la tool local, data() y los outputs.
Cada carga reemplaza la anterior. Mapa y dispersión solo dibujan los países y puntos de esa carga.
Debajo de los indicadores, Visualización reúne dos cards, Mapa y Gráfico; Datos contiene la tabla.
La preparación usa dplyr/stringr y la dispersión usa ggplot2 con theme_minimal.
El canvas inicial muestra ejes vacíos. Los puntos tienen tamaño y color fijos; los ejes son lineales.
Para un mapa se puede omitir X; filas_vacias conserva las cuatro columnas. No se configuran escalas.
Las apps R 00–09 usan thematic y ragg para heredar la tipografía de la UI.
Solo se muestran App 09 y App 09 v2. App 09 v3 conserva la versión configurable como referencia
fuera de las slides y del catálogo por defecto.
Después se muestra App 09 v2: el archivo completo con page_chat(), MCP y chat_server(),
seguido de cómo ejecutarla y una pregunta de ejemplo. Registra todas las tools directamente,
sin adaptar sus esquemas. El lanzador también incluye esta variante.
No usa SQL, filtros regionales ni series temporales.
El prompt común no menciona MCP, herramientas ni el taller. Las cifras de las respuestas con MCP se
contrastan con las llamadas guardadas; `app-09/verify-comparison.R` permite repetir esa comprobación
sin usar el modelo ni conectarse al servidor. La caché no representa una consulta en tiempo real.

Después de MCP se presentan los casos 50 y 51 como aplicaciones más completas. Una separadora azul
introduce sus diagramas y demos. La 50 usa datos locales y la 51 un servicio remoto.
Cada demo incluye cómo ejecutarla, qué pedir y qué observar.
Después de ambas apps, una slide breve describe sus cuatro tareas y muestra los nombres de las funciones.
No usa tabla y aclara que son ideas útiles para organizar tools, no un framework.
Los casos conservan su interfaz y no agregan pasos intermedios al recorrido incremental App 00–09.

- La portada, los capítulos y el cierre comparten el fondo azul oscuro.
- Los capítulos se declaran explícitamente con `.section-slide`.
- Las introducciones de paquetes agregan `.package-slide` para conservar el fondo claro.
- El azul de los capítulos se pinta en `.reveal`, fuera del lienzo escalado de 1600 × 900,
  para cubrir también las franjas de ventanas con otra proporción. La separadora es transparente.
- Cualquier otra slide usa automáticamente el estilo claro de contenido.

Las columnas, los bloques de código, los diffs y los espacios de demo son componentes internos. No
definen variantes adicionales de slide.

Las slides explicativas usan texto arriba y código debajo, a todo el ancho. El espaciado se define
de forma general con `--content-gap: 40px` y `--code-gap: 48px`, también dentro de columnas y fragmentos.
Los subtítulos después de un párrafo, lista o tabla usan `--section-gap: 56px`, por ejemplo «Observa».
Las columnas dejan `--column-gap: 40px` a cada lado de su línea divisoria, con separación simétrica.
No hay excepciones de márgenes por app. Todo el código comparte `--code-max-height: 500px` y scroll.
Los chunks ejecutados usan contenedores `.cell`: deben conservar esos mismos espacios entre texto,
código y resultados. La salida de consola usa fuente de 20 px y separación de líneas de 1.44.
La slide «Los datos que usaremos» muestra las dos líneas de carga, `dplyr::glimpse(paises, width = 100)`
y el vector `continentes`. `glimpse()` presenta las dimensiones, tipos de columnas y valores de ejemplo,
sin imprimir todas las filas. Los resultados se calculan desde el CSV al renderizar.
App 04 incluye debajo una llamada directa y su resultado real:
30 países de Europa en `data/paises.csv`.
En App 02, la utilidad reutilizable `.fragment-swap` muestra UI y server uno por vez en el mismo espacio.
Los archivos completos presentados con `code_block()` conservan sus estilos propios.

Los títulos siguen `App NN · Nombre · Tipo`, con el mismo nombre en todo el bloque de cada app.
`Código` se reserva para la app Shiny completa, una vez por app. Los fragmentos usan un nombre que describe
su contenido, como `Reactividad`, `Cámara`, `Imagen` o `Datos`; los scripts auxiliares usan `Consola`.
Los demás tipos incluyen `Patrón`, `Diagrama` y `Ejecutar`; la demo Shinylive de App 00 usa `Explorar`.
Usa siempre `·` como separador y un solo tipo por slide, sin agregar subtipos.
App 00–09, App 09 v2 y los casos 50–51 incluyen diagramas
SVG en `assets/`, insertados como HTML dentro de `.architecture-diagram` y centrados con `.content-centered`.
Comparten la paleta, las flechas y los nodos del diagrama aprobado de App 03.
El flujo que ya existía queda en gris; los nodos y conexiones nuevos se destacan en azul.
Conserva el contexto reactivo necesario para ver cómo inputs, datos y outputs siguen conectados.
Los flujos omitidos de una app anterior no se deben dibujar como si todavía existieran.
App 00 establece el patrón base; App 09 v2 conserva el agente y el MCP, pero elimina el dashboard.
En los casos 50–51, el patrón de consultar y mostrar es conocido; se destacan las fuentes de datos.
Cada diagrama muestra el patrón principal y las notas explican sus límites. Ajusta posiciones y fuentes
antes de reducir la legibilidad; los nombres largos de tools pueden usar una fuente menor.
App 02 separa chat y dashboard; App 03 y 04 distinguen llamadas de resultados; App 06 separa el modal
de la confirmación. App 07 presenta los dos modos que alimentan `data()`.
App 08 tiene dos diagramas: cámara por proxy y gráfico devuelto al modelo.
App 09 indica las columnas de cada output: mapa (y), gráfico (x, y) y tabla (x, y).
guardar_datos recibe datos y variables; el diagrama separa esos argumentos de las columnas de las filas.
App 09 v2 muestra la conversación con MCP sin dashboard.
Conserva IDs únicos y textos accesibles en cada SVG, y verifica las flechas contra el código de la app.
App 05 muestra primero su diagrama de propagación y luego el código anotado en otra slide.
Repite la función completa de la slide anterior y recorre la llamada del agente, la validación,
el estado reactivo, los datos y un output.
En las slides centradas, el código se ajusta al alto disponible y conserva el scroll y las anotaciones.
App 07 reúne en una sola slide el comando de ejecución, la comparación del mismo filtro mediante
controles y chat, y el resultado a observar. El recorrido inicial enumera las capacidades sin repetir las apps.
App 08 explica por separado el proxy del globo y la devolución de la imagen del modal al modelo.
App 09 muestra la configuración `mcp.json` y anota las líneas nuevas del cliente y registro de tools.

## Ejemplos de consola en R y Python

Antes de App 03, `R/02_ellmer_tool.R` consulta el pronóstico de una ciudad para una fecha explícita.
App 06 se concentra en abrir tablas y gráficos en modales: sus tools devuelven una confirmación.
App 07 conserva ese comportamiento y compara filtros manuales con consultas por chat.
Después de App 07, «Enviar un gráfico al modelo» presenta `R/04_ellmer_imagen.R` antes de App 08.
App 08 conserva el globo y su proxy, y completa `mostrar_grafico()` de App 06 para devolver el PNG
al modelo. La misma función dibuja el modal y la imagen; el cliente usa `gpt-5.6-luna`, igual que la consola.
Las cuatro slides de consola muestran la ruta del script antes del código para abrirlo en el editor.
La primera tool usa `code_block()` con pasos para definir la función, ejecutarla directamente,
preguntar sin tools, registrarla y volver a preguntar en la misma conversación.
La slide de dos tools también anota la función de fecha, el orden de consulta y el registro de ambas.
La slide de imagen anota la generación del gráfico, su devolución como imagen, la prueba directa
y la comparación de la conversación antes y después de registrar la tool.
Separa la ruta y la explicación en dos párrafos, con el espaciado general del contenido.
La primera versión prioriza mostrar la función, sus argumentos y el registro de la tool.
Los ejemplos de tools preguntan primero sin ellas, las registran y vuelven a preguntar
en la misma conversación.
El prompt pide reconocer la falta de acceso a los datos cuando las tools todavía no están disponibles.
Antes de App 05, `R/03_ellmer_dos_tools.R` conserva ese ejemplo y agrega la fecha actual para resolver
preguntas como «dentro de tres días». Ambos scripts son independientes y se pueden copiar completos en R.
Las versiones R del clima requieren `ellmer` y `httr2`; las Python usan `chatlas` y la biblioteca estándar.
Ambas requieren conexión a internet y `OPENAI_API_KEY` para la conversación. La llamada
directa a la función permite comprobar Open-Meteo sin usar el modelo. Las fechas usan UTC.
El buscador toma la primera coincidencia global; el resultado incluye región y país.
La versión de dos tools agrega validaciones y tiempos de espera para las consultas HTTP.
El horizonte válido incluye hoy y los próximos 15 días. Los datos conservan las unidades de la API.

Los ejemplos `R/01_ellmer.R` a `R/04_ellmer_imagen.R` tienen sus parejas en `python/`:
`01_chatlas.py`, `02_chatlas_tool.py`, `03_chatlas_dos_tools.py` y `04_chatlas_imagen.py`.
El cuarto muestra un gráfico aleatorio y permite inspeccionar el objeto de imagen que recibe el modelo.
El script 04 usa `gpt-5.6-luna` en R y Python para probar su comportamiento con imágenes devueltas por tools.
La tool devuelve texto de confirmación y la imagen juntos, para indicar que la generación ya terminó.
El prompt distingue cada petición de una imagen nueva y pide responder al recibirla, sin volver a llamar
la tool para esa petición. Es una instrucción al modelo, no un límite de ejecución impuesto por código.
`<tool result preview not available>` indica que la consola no puede previsualizar ese resultado;
no basta para concluir que la imagen no se devolvió. Si el modelo repite llamadas, interrumpe la ejecución
y vuelve a crear la conversación al probar un prompt corregido.
Las dos versiones eligen al azar entre grupos, una tendencia ascendente o descendente, una curva
y un punto aislado. Cada gráfico tiene 24 puntos con letras; no generan las mismas coordenadas.
El título y la respuesta textual de la tool no revelan el patrón elegido: el modelo debe observar la imagen.
Todos los imports y librerías se cargan al inicio. Los ejemplos 02–04 comparan antes y después del registro.
Las slides de consola usan la misma separación entre párrafos y código y el mismo límite de altura general.
El código admite ajuste de línea para evitar scroll horizontal; el script completo sigue disponible.
El botón de copiar permanece visible en estas slides, incluso sin pasar el cursor sobre el código.
Las slides principales se concentran en consultar, actualizar y mostrar resultados. App 04 permite
listar todos los países y los modales no imponen un máximo de 100 filas. Las tools de gráficos describen
las columnas permitidas en sus esquemas. El ejemplo de dos tools del clima conserva sus validaciones.
Desde la raíz, ejecútalo con `uv run --env-file .Renviron python python/02_chatlas_tool.py`.
`--env-file` carga la clave desde el mismo archivo usado por R.

## Render local

La última slide de Q&A responde preguntas del público; no propone una actividad interactiva.
Incluye una lista breve de modelos con soporte oficial de function calling de OpenAI, Anthropic y Google.
Cada proveedor enlaza la documentación consultada en noviembre de 2026.
La respuesta distingue soporte, registro de tools, acceso de la cuenta y fiabilidad observada.

```console
quarto render slides/index.qmd
```

Para revisar cambios mientras editas:

```console
quarto preview slides/index.qmd
```

Quarto escribe `slides/index.html` y sus dependencias junto al QMD. Las rutas son relativas para que la
presentación funcione bajo `/shiny-chat-patterns/`.

Para imprimir, abre la presentación con `?print-pdf`. El CSS de `html.reveal-print` devuelve `.slides`
al flujo normal de la página: conservar la posición absoluta del modo de pantalla colapsa su contenedor
y puede producir un PDF vacío. Esta regla se aplica únicamente a la vista de impresión.

## Código R anotado

`index.qmd` define `code_block()`, que lee un script R y conecta rangos de líneas con explicaciones de
Quarto. La llamada debe usar `results: asis`:

````markdown
```{r}
#| results: asis
code_block("../app-03/app.R", c(
  "1-4" = "Carga las librerías de la aplicación y del chat.",
  "57-66" = "La tool consulta y resume los datos visibles."
))
```
````

Los rangos se muestran progresivamente gracias a la extensión local `codefrag`.

### Parámetros y estilo de `code_block()`

La firma actual es `code_block(path, descriptions = NULL, single_copy = TRUE)`:

| Parámetro | Uso |
|---|---|
| `path` | Ruta al script R, relativa a `index.qmd`. Se incluye el archivo completo en UTF-8. |
| `descriptions` | Vector de explicaciones nombradas por línea o rango, como `"19"` o `"60-63"`. |
| `single_copy` | Usa un solo bloque HTML; con `FALSE` recupera el resaltado estándar de Quarto. |

Con `descriptions = NULL`, muestra el archivo sin anotaciones ni pasos de resaltado. Los rangos usan
los números de línea del archivo original; al editar una app, revisa las llamadas correspondientes.

Ambos modos emiten la clase `.workshop-code`. En `assets/theme.scss`, esta clase establece fuente de
19 px. Los ejemplos escritos directamente en las slides usan fuente de 20 px. Todos comparten
el mismo límite `--code-max-height: 500px`: un archivo corto ocupa menos espacio y uno largo tiene scroll.

Estos valores se mantienen en CSS para conservar una presentación consistente. Si aparece una
necesidad concreta, tendría sentido agregar:

- `language`: para mostrar también archivos Python con el resaltado correspondiente.
- `font_size` y `max_height`: para una excepción por bloque, conservando los valores comunes por defecto.

Estos parámetros todavía no están implementados. Recortar líneas exigiría además conservar la
numeración original y ajustar la relación entre rangos, anotaciones y pasos de `codefrag`.

### Rendimiento de archivos largos

Por defecto, el helper emite `data-workshop-highlights` en lugar de `code-line-numbers`. Así Quarto
conserva una sola copia del archivo. `codefrag` sigue creando los avances de las anotaciones y
`assets/code-highlights.js` aplica las clases de resaltado al bloque existente al avanzar o retroceder.
Los avances siguen el número de anotación (1, 2, 3...), aunque los marcadores aparezcan en otro orden
en el archivo. El ajuste conserva los índices reservados al bloque y respeta los índices explícitos.
Los rangos y las líneas originales se conservan; el archivo completo sigue disponible para el scroll.

El desplazamiento usa el scroll suave del navegador y respeta la preferencia de movimiento reducido.
Al entrar a una slide, redimensionar la ventana o preparar las páginas de impresión, centra la selección
sin animación. Los marcadores numerados también permiten seleccionar el paso correspondiente.

El tooltip conserva la referencia a su marcador y usa el seguimiento nativo de Popper durante el scroll.
Con el motor anterior, conserva los marcadores de las copias y agrupa sus eventos de scroll en una
actualización por bloque y frame, evitando buscar los mismos elementos en cada evento.
Con una sola copia, el resaltado pertenece a `code-highlights.js`; se evita el borde adicional de Quarto
porque su gutter puede desbordar el ancho del código y crear una barra horizontal.

Para volver al motor anterior en un bloque, usa `code_block(..., single_copy = FALSE)`. Cambiar el valor
por defecto de la función recupera ese comportamiento para todas las llamadas que no lo especifican.
Ese motor crea una copia completa del archivo por paso, por lo que su coste crece con las líneas y
la cantidad de anotaciones. La extensión instalada se conserva sin modificaciones.

### Por qué existe el ajuste de tooltips

El tooltip debe seguir el marcador mientras se desplaza el código. Con el motor estándar de Quarto,
Reveal crea además una copia del código por cada paso y el marcador original puede quedar fuera
de vista. El ajuste admite tanto ese motor como el resaltado de una sola copia.

`assets/code-tooltips.js`, cargado desde `assets/cover.html`, coordina cinco aspectos:

1. Usa el marcador como referencia; con el motor anterior, sigue el de la copia activa.
2. Monta el tooltip en la slide para evitar el recorte de los contenedores con scroll u overflow.
3. Mantiene el tooltip encima de la línea, con el cambio automático de lado (`flip`) desactivado.
4. Convierte las coordenadas a la escala de la slide, incluido el uso de CSS `zoom` o `transform`.
5. Recalcula la posición durante el scroll y coordina la selección con `code-highlights.js`.

El `z-index` y la apariencia se definen en `assets/theme.scss`. Subir solo el `z-index` no resuelve
el recorte por overflow ni una referencia vinculada a la copia equivocada. El ajuste vive fuera de
`_extensions/` para facilitar las actualizaciones de la extensión.

Al modificar el helper, los estilos o las versiones de Quarto/codefrag, comprobar:

- Los pasos 1 a 4 de App 02, especialmente las líneas 52 y 60, avanzando y retrocediendo.
- El regreso a una slide ya recorrida y el scroll dentro del código.
- Ventanas de 1600 × 900 y 1100 × 720: tooltip visible, encima de la línea y dentro de la slide.
- Las líneas largas de `value_box()`: deben caber sin scroll horizontal.
- App 01, cuyo texto introductorio comparte el espacio vertical con el bloque de código.
- Los ejemplos que no usan `code_block()`: deben conservar su tamaño original.
- Los clics en los marcadores numerados y la exportación mediante `?print-pdf`.
- `single_copy = FALSE`, para conservar una alternativa al actualizar Quarto o `codefrag`.
- Las tildes y eñes: si aparecen secuencias como `<U+00F3>`, revisar la configuración UTF-8 de R.

El chunk inicial usa `LC_CTYPE = ".UTF-8"` en Windows para conservar las tildes al emitir el código.
Esto evita que una sesión iniciada con locale `C` convierta esos caracteres en secuencias `<U+...>`.

El ajuste depende de los selectores de los fragmentos y de la instancia `_tippy` que crea Quarto.
Al actualizar esas dependencias, revisa estas suposiciones además de comprobar el render.

## Demo de app-00

La primera slide de `app-00` muestra el archivo mediante `code_block()`. La siguiente ejecuta la misma
interfaz con Shinylive, usando `AirPassengers` para incluir los datos dentro del navegador.

No se exportarán con Shinylive las apps que necesitan `OPENAI_API_KEY`: cualquier secreto incluido en una
app que corre en el navegador queda expuesto.

## Publicación

El workflow `.github/workflows/slides-pages.yml` renderiza `slides/index.qmd` y publica esta carpeta con
GitHub Pages. Se activa al cambiar las slides, las apps o los scripts de `R/` en `main`, y también
permite ejecución manual. En la configuración del repositorio, usa **GitHub Actions** como fuente de Pages.

El job de publicación usa `R_PROFILE_USER=/dev/null` e instala `rmarkdown`, `shinylive`, los paquetes
de la demo embebida (`shiny`, `bslib`, `forecast`), `dplyr` para `glimpse()` y `jsonlite` para leer
las respuestas cacheadas del MCP en la librería del runner, con CRAN explícito.
Así el perfil `renv` de las apps no cambia la librería que usan Quarto y el filtro Shinylive.
