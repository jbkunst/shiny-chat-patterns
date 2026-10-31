# Slides del taller

La fuente visual de la presentación vive en esta carpeta y se publica en
<https://jkunst.com/shiny-chat-patterns/>.
El render lee también los ejemplos de `R/` y los `app.R` del recorrido principal.

## Estructura

- `index.qmd`: fuente Quarto y contenido del taller.
- `index.html`: presentación renderizada por Quarto.
- `assets/theme.scss`: variables tipográficas y cromáticas de RevealJS.
- `assets/slides.css`: estilos de portada, capítulos, paquetes, contenido y demostraciones.
- `assets/cover.html`: estructura de la visualización animada de portada.
- `assets/cover.js`: animación de portada inspirada en el landing de jkunst.com.
- `assets/code-highlights.js`: resaltado y scroll de los archivos completos con una sola copia del código.
- `assets/code-tooltips.js`: posición de las anotaciones durante el resaltado y el scroll.
- `_extensions/mcanouil/codefrag/`: navegación progresiva por anotaciones de código.
- La demo de `app-00` se ejecuta en el navegador mediante Shinylive.

## Arquitectura visual

El recorrido se divide en tres capítulos: preparar y conversar (App 00–02), consultar y actualizar
(App 03–05) y actuar sobre la interfaz (App 06–08). App 01–08 terminan con «Ejecutar y explorar»:
comando de R,
acción o pregunta sugerida y comportamiento a observar. Ejecuta los comandos desde la raíz del repositorio.
App 00 muestra solo la demo Shinylive, con un visor de 650 px y la app al 80 % de escala.
No incluye comando de ejecución porque ya está funcionando en el navegador. El zoom se aplica
al HTML de esa app embebida, sin cambiar la escala de las slides ni la app local.
En las demos, los subtítulos tienen 48 px de margen superior y 16 px inferior. Su selector debe superar
la especificidad del estilo general de `h3`, para conservar la separación entre acción y observación.

- La portada, los capítulos y el cierre comparten el fondo azul oscuro.
- Los capítulos se declaran explícitamente con `.section-slide`.
- Las introducciones de paquetes agregan `.package-slide` para conservar el fondo claro.
- El azul de los capítulos se pinta en `.reveal`, fuera del lienzo escalado de 1600 × 900,
  para cubrir también las franjas de ventanas con otra proporción. La separadora es transparente.
- Cualquier otra slide usa automáticamente el estilo claro de contenido.

Las columnas, los bloques de código, los diffs y los espacios de demo son componentes internos. No
definen variantes adicionales de slide.

Las slides explicativas de las apps usan texto arriba y código debajo, a todo el ancho. La clase
`.pattern-overview` deja 28 px antes del código y limita su altura a 540 px para que quepa con el texto.
En App 02, los fragmentos de UI y server ocupan el mismo espacio y se muestran uno por vez.
Los archivos completos presentados con `code_block()` conservan sus estilos propios.

Los títulos de las apps nombran la capacidad que se incorpora. App 05 incluye un diagrama HTML/CSS de
la cadena tool → estado reactivo → datos → outputs, con el estado destacado. App 07 compara el mismo filtro
mediante controles y chat. Los nombres de la slide de familias de tools son ejemplos ilustrativos
de otros contextos.

## Ejemplos de consola en R y Python

Antes de App 03, `R/02_ellmer_tool.R` consulta el pronóstico de una ciudad para una fecha explícita.
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
Las dos versiones usan doce puntos, uno alejado, y letras aleatorias; no generan las mismas coordenadas.
Todos los imports y librerías se cargan al inicio. Los ejemplos 02–04 comparan antes y después del registro.
Las slides de una tool, dos tools e imagen usan `.tool-console-slide`: una frase introductoria y código
de hasta 590 px de alto.
El código admite ajuste de línea para evitar scroll horizontal; el script completo sigue disponible.
El botón de copiar permanece visible en estas slides, incluso sin pasar el cursor sobre el código.
Las slides principales se concentran en consultar, actualizar y mostrar resultados. App 04 permite
listar todos los países y los modales no imponen un máximo de 100 filas. Las tools de gráficos describen
las columnas permitidas en sus esquemas. El ejemplo de dos tools del clima conserva sus validaciones.
Desde la raíz del repositorio, ejecútalo con `uv run python python/02_chatlas_tool.py`.
Configura `OPENAI_API_KEY` en el entorno de Python; Python no carga `.Renviron` automáticamente.

## Render local

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

Ambos modos emiten la clase `.workshop-code`. En `assets/slides.css`, esta clase establece fuente de
19 px y altura máxima de 683 px, aproximadamente un 5 % más que los 650 px originales. Es una altura
máxima: un archivo corto ocupa menos espacio. `.tool-console-slide` reduce ese máximo a 590 px.
Los ejemplos escritos directamente en las slides usan fuente de 20 px; `.pattern-overview` limita
su altura a 540 px y el resto conserva un máximo de 650 px.

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

El `z-index` y la apariencia se definen en `assets/slides.css`. Subir solo el `z-index` no resuelve
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
