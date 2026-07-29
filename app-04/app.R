library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(duckdb)
library(datos)

# database ----------------------------------------------------------------

con <- DBI::dbConnect(duckdb(), dbdir = ":memory:")
DBI::dbWriteTable(con, "pinguinos", pinguinos)
onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))

# prompt ------------------------------------------------------------------

system_prompt <- paste(
  "Eres el asistente breve de un dashboard de pingüinos.",
  "La tabla DuckDB se llama pinguinos y contiene:",
  "especie, isla, largo_pico_mm, alto_pico_mm, largo_aleta_mm, masa_corporal_g, sexo, anio.",
  "Usa update_dashboard() cuando el usuario quiera filtrar, ordenar o reiniciar el dashboard.",
  "La consulta debe ser SELECT * FROM pinguinos y puede agregar WHERE u ORDER BY.",
  "Para reiniciar usa SELECT * FROM pinguinos.",
  "Mantén las respuestas cortas y en español."
)

# user interface ----------------------------------------------------------

ui <- page_navbar(
  sidebar = sidebar(
    width = 400,
    shinychat::chat_mod_ui("chat", placeholder = "Ej: muestra solo Adelie...")
  ),
  nav_panel(
    "Dashboard",
    h3(textOutput("title", inline = TRUE)),
    verbatimTextOutput("query"),
    layout_columns(
      value_box("Registros", textOutput("n_rows")),
      value_box("Especies", textOutput("n_species")),
      value_box("Masa promedio", textOutput("avg_mass")),
      col_widths = 4
    ),
    layout_columns(
      card(plotOutput("plot")),
      card(tableOutput("table")),
      col_widths = c(6, 6)
    )
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {

  current_title <- reactiveVal("Todos los pingüinos")
  current_query <- reactiveVal("SELECT * FROM pinguinos")

  data <- reactive({
    DBI::dbGetQuery(con, current_query())
  })

  output$title <- renderText(current_title())
  output$query <- renderText(current_query())

  output$n_rows <- renderText(nrow(data()))
  output$n_species <- renderText(length(unique(data()$especie)))
  output$avg_mass <- renderText(paste0(round(mean(data()$masa_corporal_g, na.rm = TRUE)), " g"))

  output$plot <- renderPlot({
    df <- data()

    plot(
      df$largo_aleta_mm,
      df$masa_corporal_g,
      pch = 19,
      xlab = "Largo de aleta (mm)",
      ylab = "Masa corporal (g)"
    )
  })

  output$table <- renderTable(head(data(), 20), striped = TRUE, hover = TRUE)

  # tool ------------------------------------------------------------------

  update_dashboard <- function(query, title) {
    DBI::dbGetQuery(con, query)
    current_query(query)
    current_title(title)
    "Dashboard actualizado."
  }

  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = system_prompt
  )

  chat$register_tool(tool(
    update_dashboard,
    "Filtra, ordena o reinicia los datos mostrados en el dashboard.",
    arguments = list(
      query = type_string("Consulta DuckDB SELECT * FROM pinguinos con WHERE u ORDER BY opcionales."),
      title = type_string("Título breve que describe los datos mostrados.")
    )
  ))

  shinychat::chat_mod_server(
    "chat",
    client = chat,
    greeting = paste(
      "Explora el dashboard con el chat.",
      "Por ejemplo: muestra solo Adelie, ordena por masa corporal o reinicia."
    )
  )
}

shinyApp(ui, server)
