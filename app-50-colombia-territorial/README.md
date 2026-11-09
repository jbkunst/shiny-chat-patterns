# App 50 · Colombia territorial

Caso en R con indicadores departamentales y chat flotante. Organiza las tools en cuatro responsabilidades:
resolver el catálogo, consultar un indicador, mostrarlo e inspeccionar la vista para responder.
Su identidad visual es propia; no continúa el dashboard incremental de App 00–09.

Desde la raíz, con el entorno y la [clave del modelo](../README.md#configurar-la-api) preparados:

```r
shiny::runApp("app-50-colombia-territorial")
```

## Datos locales

La app lee `data/colombia_departamentos.rds`, incluido en esta carpeta.
Combina indicadores de la **ECV 2025 del DANE** con geometría del **MGN 2018** procesada por data_ColOpenData.
Las tools consultan esa copia local; no descargan datos durante la conversación y no usan MCP.

Para reconstruir el archivo desde sus fuentes, ejecuta desde la raíz:

```r
source("app-50-colombia-territorial/prepare-data.R", chdir = TRUE, encoding = "UTF-8")
```

La preparación requiere internet. Para usar la app durante el taller basta con los datos incluidos
y el acceso al proveedor del modelo.
