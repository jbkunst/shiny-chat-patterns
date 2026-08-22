# Convenciones del repositorio

## Propósito

Este repositorio reúne ejemplos pequeños y progresivos de patrones de chat en
Shiny. Puede servir como base para un taller, pero cada ejemplo debe ser útil por
sí mismo.

Cada app debe introducir una idea principal y conservar la mayor cantidad de
código posible de la app anterior. El cambio relevante debe ser fácil de
identificar en una slide o en un diff.

## Secuencia de apps

- `app-00`: widgets y outputs de Shiny, sin chat.
- `app-01`: un dashboard reactivo pequeño.
- `app-02`: agrega chat, sin tools ni acceso a los datos de la app.
- `app-03`: agrega una tool simple que consulta datos reales.
- `app-04`: agrega una tool SQL de solo lectura. Desde esta app, mueve el
  greeting y el system prompt a archivos Markdown.
- `app-05`: permite que una tool actualice los datos reactivos mostrados por
  Shiny.
- `app-06`: agrega tools de interfaz como `show_table()` y `show_chart()` que
  abren modales.
- `app-10` a `app-19`: extensiones visuales y de interacción, como mapas.
- `app-20` en adelante: orquestación, agentes y bots especializados.

Agrega una app intermedia en vez de introducir varios conceptos nuevos en el
mismo paso.

## Interfaz

- Usa `bslib::page_sidebar()` como estructura por defecto.
- Ubica el chat y los controles manuales en el sidebar y el resultado en el área
  principal.
- Mantén la UI intencionalmente mínima y consistente entre apps consecutivas.
- Evita navbars, tabs, accordions, paneles flotantes, cards decorativos y layouts
  personalizados, salvo que ese comportamiento sea el patrón demostrado.
- Conserva un output visible solo cuando ayude a explicar el comportamiento del
  chat: valores reactivos, un modal abierto por una tool, un mapa o el resultado
  de un agente.
- Prefiere el mismo dataset y la misma estructura de dashboard durante el
  recorrido principal.

## Chat, prompts y tools

- Mantén el greeting y el system prompt inline mientras quepan cómodamente en
  una expresión corta. Usa `greeting.md` y `prompt.md` cuando crezcan.
- Enfoca cada app en una capacidad nueva: conversación, acceso a datos, SQL,
  actualización reactiva, acciones de interfaz u orquestación.
- Define tools con nombres explícitos, descripciones breves y argumentos
  acotados.
- Valida los argumentos antes de consultar datos o modificar estado reactivo.
- Los ejemplos SQL deben ser de solo lectura y estar restringidos a la tabla
  correspondiente.
- No inventes resultados numéricos cuando una tool pueda obtenerlos desde los
  datos.

## Estilo de código

- Optimiza los ejemplos para proyectarlos en slides y compararlos entre apps.
- Mantén las llamadas simples en una línea cuando sigan siendo legibles. Por
  ejemplo: `renderTable(head(data(), 10), striped = TRUE, hover = TRUE)`.
- Usa varias líneas para lógica o argumentos semánticamente distintos.
- Mantén las líneas en 110 caracteres o menos, incluidos los prompts Markdown.
- Prefiere R base y el pipe nativo `|>` cuando permitan reducir el ejemplo.
- Evita módulos, clases, helpers, dependencias y abstracciones que no sean
  necesarias para enseñar el patrón.
- Conserva secciones consistentes: data, prompt, user interface, server y tools
  cuando correspondan.

## Antes de publicar

- Confirma que cada app pueda ejecutarse de forma independiente desde su carpeta.
- Revisa que dos apps consecutivas difieran principalmente en el concepto nuevo.
- Busca complejidad accidental en la UI y líneas de más de 110 caracteres.
- Parsea o ejecuta las apps modificadas cuando estén disponibles R y sus paquetes.
- Actualiza la secuencia del README al agregar, eliminar o renumerar una app.
