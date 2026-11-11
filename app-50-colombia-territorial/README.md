# App 50 · Colombia territorial

Caso en R con indicadores departamentales y chat flotante. Organiza las tools en cuatro responsabilidades:
resolver el catálogo, consultar un indicador, mostrarlo e inspeccionar la vista para responder.
Su identidad visual es propia; no continúa el dashboard incremental de App 00–09.

El CSS vive en `www/styles.css`. El panel flotante contiene el chat y el botón para volver a Colombia.
La leyenda del mapa muestra indicador, unidad, año y territorio seleccionado; se actualiza al cambiar
el indicador o el territorio. No hay un bloque de contexto separado debajo del título del chat.

## Herramientas

1. `resolver_catalogo(texto)`: busca indicadores y departamentos; devuelve nombres, unidades, años y códigos.
2. `consultar_indicador(indicador, codigo)`: devuelve los datos y guarda la selección
   en `consulta_preparada()`. Consultar por sí solo no cambia el mapa.
3. `visualizar_indicador()`: usa la selección preparada para actualizar indicador, filtro, cámara y leyenda.
4. `inspeccionar_vista()`: devuelve los datos, metadatos y extremos de la selección que se está mostrando.

El agente decide qué herramientas llamar; no se ejecutan automáticamente unas a continuación de otras.
El prompt pide inspeccionar la vista después de visualizar para fundamentar la respuesta.

## Ejecutar

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
