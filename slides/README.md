# Slides del taller

La presentación vive completa en esta carpeta y se publica en
<https://jkunst.com/shiny-chat-patterns/>.

## Estructura

- `index.qmd`: fuente Quarto y contenido del taller.
- `index.html`: presentación renderizada por Quarto.
- `assets/theme.scss`: variables tipográficas y cromáticas de RevealJS.
- `assets/slides.css`: tres estilos de slide y componentes de contenido.
- `assets/cover.html`: estructura de la visualización animada de portada.
- `assets/cover.js`: animación de portada inspirada en el landing de jkunst.com.
- `assets/code-tooltips.js`: posición de las anotaciones durante el resaltado y el scroll.
- `_extensions/mcanouil/codefrag/`: navegación progresiva por anotaciones de código.
- La demo de `app-00` se ejecuta en el navegador mediante Shinylive.

## Arquitectura visual

- La portada es la slide de título generada por Quarto y contiene la única superficie oscura.
- Los capítulos se declaran explícitamente con `.section-slide`.
- Cualquier otra slide usa automáticamente el estilo claro de contenido.

Las columnas, los bloques de código, los diffs y los espacios de demo son componentes internos. No
definen variantes adicionales de slide.

Las slides explicativas de las apps usan texto arriba y código debajo, a todo el ancho. La clase
`.pattern-overview` deja 28 px antes del código y limita su altura a 540 px para que quepa con el texto.
En App 02, los fragmentos de UI y server ocupan el mismo espacio y se muestran uno por vez.
Los archivos completos presentados con `code_block()` conservan sus estilos propios.

Los títulos de las apps nombran la capacidad que se incorpora. App 05 incluye un diagrama de la
cadena tool → estado reactivo → datos → outputs. App 07 compara el mismo filtro mediante controles
y chat. Los nombres de la slide de familias de tools son ejemplos ilustrativos de otros contextos.

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

## Código R anotado

`index.qmd` define `code_block()`, que lee un script R y conecta rangos de líneas con explicaciones de
Quarto. La llamada debe usar `results: asis`:

````markdown
```{r}
#| results: asis
code_block("../app-03/app.R", c(
  "1-4" = "Carga los datos compartidos por la aplicación.",
  "20-28" = "La tool consulta el estado reactivo."
))
```
````

Los rangos se muestran progresivamente gracias a la extensión local `codefrag`.

### Parámetros y estilo de `code_block()`

La firma actual es `code_block(path, descriptions = NULL)`:

| Parámetro | Uso |
|---|---|
| `path` | Ruta al script R, relativa a `index.qmd`. Se incluye el archivo completo en UTF-8. |
| `descriptions` | Vector de explicaciones nombradas por línea o rango, como `"19"` o `"60-63"`. |

Con `descriptions = NULL`, muestra el archivo sin anotaciones ni pasos de resaltado. Los rangos usan
los números de línea del archivo original; al editar una app, revisa las llamadas correspondientes.

Ambos modos emiten la clase `.workshop-code`. En `assets/slides.css`, esta clase establece fuente de
19 px y altura máxima de 683 px, aproximadamente un 5 % más que los 650 px originales. Es una altura
máxima: un archivo corto ocupa menos espacio. Los ejemplos escritos directamente en las slides
conservan su fuente de 20 px y su altura máxima de 650 px.

Estos valores se mantienen en CSS para conservar una presentación consistente. Si aparece una
necesidad concreta, tendría sentido agregar:

- `language`: para mostrar también archivos Python con el resaltado correspondiente.
- `font_size` y `max_height`: para una excepción por bloque, conservando los valores comunes por defecto.

Estos parámetros todavía no están implementados. Recortar líneas exigiría además conservar la
numeración original y ajustar la relación entre rangos, anotaciones y pasos de `codefrag`.

### Por qué existe el ajuste de tooltips

Reveal crea una copia del código por cada paso de resaltado y desplaza esa copia al avanzar. El
tooltip de Quarto puede seguir vinculado al marcador del bloque original, que no necesariamente
está visible. Esto afecta especialmente a anotaciones que aparecen lejos del inicio del archivo.

`assets/code-tooltips.js`, cargado desde `assets/cover.html`, coordina cinco aspectos:

1. Usa el marcador de la copia activa como referencia de posición.
2. Monta el tooltip en la slide para evitar el recorte de los contenedores con scroll u overflow.
3. Mantiene el tooltip encima de la línea, con el cambio automático de lado (`flip`) desactivado.
4. Convierte las coordenadas a la escala de la slide, incluido el uso de CSS `zoom` o `transform`.
5. Recalcula la posición durante el scroll y recupera el marcador al volver a una slide.

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
GitHub Pages. En la configuración del repositorio, selecciona **GitHub Actions** como fuente de Pages.
