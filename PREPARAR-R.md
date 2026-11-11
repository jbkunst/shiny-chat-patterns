# Preparar el taller en R · Descargar ZIP

Esta opción no requiere Git, Python ni conocimientos de `renv`.
Necesitas internet, R 4.6.1 o posterior y RStudio. Instala los paquetes antes del taller.

## 1. Descargar los ejemplos

Abre [el repositorio en GitHub](https://github.com/jbkunst/shiny-chat-patterns), pulsa el botón
**Code → Download ZIP** y extrae todo el archivo en una carpeta de Documentos.
También puedes usar el
[enlace directo al ZIP de GitHub](https://github.com/jbkunst/shiny-chat-patterns/archive/refs/heads/main.zip).
Trabaja en la carpeta extraída, no dentro del ZIP. No hace falta descargar cada app por separado.

## 2. Instalar los paquetes

1. Abre RStudio. Si tienes otro proyecto abierto, usa **File → Close Project**.
2. Abre `instalar.R` desde la carpeta extraída, con **File → Open File**.
3. Con ese archivo abierto, selecciona **Session → Set Working Directory → To Source File Location**.
4. Pulsa **Source** y espera a que termine.

El script instala los paquetes con `install.packages()` en la biblioteca habitual de R.
Para el ejemplo MCP instala además una versión concreta de `mcptools` desde GitHub;
esa descarga es automática y no requiere instalar Git.

Si aparece el mensaje de que `renv` ya estaba activo, usa **Session → Restart R** y vuelve a pulsar
**Source** sobre `instalar.R`. El script deja desactivada la carga automática de `renv` para esta copia.
No cambia la configuración de tus otros proyectos.

En Windows, acepta crear una biblioteca personal si R lo pregunta. Si un paquete necesita compilarse,
puede requerir Rtools; en macOS o Linux pueden hacer falta herramientas o bibliotecas del sistema.
Si falla la instalación, conserva el mensaje de error para revisarlo antes del taller.

## 3. Configurar la clave

El instalador crea `.Renviron` si todavía no existe. En la consola de RStudio, ejecuta:

```r
file.edit(".Renviron")
```

Reemplaza `PEGA_TU_CLAVE_AQUI` por tu clave y guarda. Conserva la segunda línea:

```dotenv
OPENAI_API_KEY="PEGA_TU_CLAVE_AQUI"
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE
```

El archivo se llama exactamente `.Renviron`, con punto inicial y sin `.txt` al final.
La clave es privada: no la pegues en el chat de la app ni compartas tu archivo con otras personas.
El ZIP público contiene solo una plantilla sin credenciales.

## 4. Comprobar que funciona

Desde la carpeta extraída, ejecuta en RStudio:

```r
readRenviron(".Renviron")
library(ellmer)
chat <- ellmer::chat("openai/gpt-5-nano")
chat$chat("Responde solamente: conexión correcta.")
```

Esta prueba usa la API y consume saldo. Si recibes la respuesta, abre una app:

```r
shiny::runApp("app-02")
```

Para detenerla, pulsa **Stop** en RStudio. App 00 y App 01 funcionan sin clave.
El resto de las apps se abre de la misma forma, cambiando el nombre de la carpeta.
No hace falta reconstruir los datos: ya están incluidos.

## Si prefieres Git y renv

Usa la [ruta reproducible del README](README.md#opción-2--github-y-renv).
Son los mismos ejemplos; cambia la forma de instalarlos.
