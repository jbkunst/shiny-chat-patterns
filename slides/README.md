# Slides del taller

La presentación vive completa en esta carpeta y se publica en
<https://jkunst.com/shiny-chat-patterns/>.

## Estructura

- `index.qmd`: fuente Quarto y contenido del taller.
- `index.html`: presentación renderizada por Quarto.
- `assets/theme.scss`: variables del tema RevealJS.
- `assets/slides.css`: portada, layouts, componentes y estilos de código.
- `assets/cover.html`: estructura de la visualización animada de portada.
- `assets/cover.js`: animación inspirada en el landing de jkunst.com.
- `_extensions/mcanouil/codefrag/`: navegación progresiva por anotaciones de código.
- `shinylive/`: salida local reservada para las demos interactivas; está ignorada por Git.

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

## Demo de app-00 pendiente

La slide de `app-00` deja preparado el espacio para una demo que no requiere API key. La integración con
Shinylive se hará al final, una vez estabilizados el diseño y la historia del taller.

No se exportarán con Shinylive las apps que necesitan `OPENAI_API_KEY`: cualquier secreto incluido en una
app que corre en el navegador queda expuesto.

## Publicación

El workflow `.github/workflows/slides-pages.yml` renderiza `slides/index.qmd` y publica esta carpeta con
GitHub Pages. En la configuración del repositorio, selecciona **GitHub Actions** como fuente de Pages.
