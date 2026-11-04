# App Commons · Cálculo confiable frente a análisis exploratorio

Esta aplicación es una **demo autónoma** del paquete [commons](https://posit-dev.github.io/commons/r/).
No continúa la secuencia App 00–09 ni se conecta al MCP del FMI. Usa datos **ficticios** y una
única medida aprobada para que el flujo se vea sin distraerse con una API.

## Ejecutar

Desde la raíz del repositorio, con `OPENAI_API_KEY` configurada:

```r
install.packages("commons") # Si todavía no está instalado en el proyecto.
shiny::runApp("app-commons")
```

No se modifica `renv.lock`: la dependencia se instala localmente para probar esta extensión.

## Dos preguntas para comparar

1. **«¿Cuántas unidades se vendieron en total en Norte?»** La medida
   `total_unidades_region` obtiene el valor aprobado (480). Comprueba que el agente
   la invoque y que la respuesta indique procedencia **Trusted**.
2. **«¿Qué región creció más entre enero y abril, en porcentaje?»** No existe
   una medida aprobada para esa pregunta. El agente puede escribir SQL o R sobre
   la tabla y encontrar **Sur (+100 %)**. Si sigue ese camino, la procedencia será
   **Cited** o **Untrusted**, no la de una medida confiable.

Los indicadores dependen de **las herramientas efectivamente utilizadas**. Una
respuesta correcta no es necesariamente «Trusted», y ese indicador no valida por
sí solo la calidad del código original.

## Qué hace cada componente

- `data_source(ventas = ventas)` publica el data frame como tabla consultable.
- `measure()` describe un cálculo revisado previamente, implementado en R.
- `semantic_layer()` registra esa medida; el parámetro `datos` recibe la conexión
  de la fuente y no se expone al modelo.
- `commons()` crea el agente y puede escoger una medida o una consulta ad hoc.
- `commons_app()` crea una interfaz Shiny sin escribir UI ni server manualmente.

La app **no consulta una API externa**. Para conectarla más adelante a BCCH Studio,
la opción sencilla es obtener las series con `bcchr` y registrarlas como data frames.

**Nota Windows:** según el entorno, el aislamiento de R puede requerir la opción
`options(commons.allow_unsafe_fallback = TRUE)` para desarrollo local. Es una
alternativa de menor seguridad y **no** debe activarse inadvertidamente en
despliegues ni tratarse como un sandbox. Consulta la
[documentación de commons](https://posit-dev.github.io/commons/r/reference/commons.html).

## Fuente

- [Introducción a commons](https://posit-dev.github.io/commons/r/articles/commons.html)
- [Referencia de measure](https://posit-dev.github.io/commons/r/reference/measure.html)
