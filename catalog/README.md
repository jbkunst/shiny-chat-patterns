# Catálogo de apps R

Desde la raíz del repositorio, inicia las apps estables y el catálogo con:

```r
source("R/run_all_apps.R")
```

El script valida el código R y los metadatos de las apps, asigna puertos y guarda el plan en `apps.yml`.
Inicia las apps en procesos separados, renderiza el catálogo y comprueba que las URLs respondan.
El objeto `course` conserva los procesos para poder detenerlos:

```r
stop_all_apps(course)
```

## Opciones

Quarto debe estar disponible en `PATH`. Por defecto, las apps usan puertos desde `8000` y el catálogo
intenta usar `7999`; si está ocupado, busca otro puerto.
Las apps se inician de una en una y el tiempo máximo de inicio es de 180 segundos.

Después de detener la ejecución anterior, puedes incluir los experimentos o cambiar esas opciones:

```r
course <- run_all_apps(
  include_experimental = TRUE,
  first_app_port = 8000L,
  catalog_port = 7999L,
  startup_timeout = 180
)
```

Volver a cargar `R/run_all_apps.R` detiene la ejecución anterior antes de iniciar otra.
Los títulos y descripciones del catálogo proceden del `DESCRIPTION` de cada app.
