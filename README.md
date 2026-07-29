# shiny-chatsidebot

Ejemplos progresivos de aplicaciones Shiny con chat y herramientas de IA.

Cada aplicación es independiente y tiene su propio `app.R`:

- `app-01`: estructura básica.
- `app-02`: chat SQL.
- `app-03`: chat con una herramienta.
- `app-04`: dashboard de pingüinos controlado por chat.
- `app-05`: mapa mundial controlado por chat.
- `app-06`: flujo mínimo con dos agentes: analyst → ejecución simulada → writer.

Para ejecutar una aplicación:

```r
shiny::runApp("app-06")
```
