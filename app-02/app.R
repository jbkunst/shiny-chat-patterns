library(shiny)
library(bslib)
library(datos)
library(ellmer)
library(shinychat)

# data --------------------------------------------------------------------

penguins <- datos::pinguinos
species <- c("Todas", sort(unique(stats::na.omit(penguins$especie))))

# user interface ----------------------------------------------------------

ui <- page_sidebar(
  title = "App 02 · Shiny con chat",
  sidebar = sidebar(
    selectInput("species", "Especie", choices = species),
    shinychat::chat_ui(
      "chat",
      messages = paste(
        "Hola. Puedo conversar sobre el dataset de pingüinos,",
        "pero todavía no puedo consultar sus datos ni controlar el dashboard."
      ),
      placeholder = "Pregunta algo sobre los pingüinos..."
    )
  ),
  layout_columns(
    value_box("Registros", textOutput("n_rows")),
    value_box("Masa promedio", textOutput("avg_mass")),
    col_widths = c(6, 6)
  ),
  layout_columns(
    card(plotOutput("plot")),
    card(tableOutput("table")),
    col_widths = c(6, 6)
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {
  data <- reactive({
    if (input$species == "Todas") {
      penguins
    } else {
      penguins[penguins$especie == input$species, ]
    }
  })

  output$n_rows <- renderText(nrow(data()))

  output$avg_mass <- renderText({
    paste0(round(mean(data()$masa_corporal_g, na.rm = TRUE)), " g")
  })

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

  output$table <- renderTable(head(data(), 10), striped = TRUE, hover = TRUE)

  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = "Responde brevemente en español sobre el dataset Palmer Penguins. No inventes resultados numéricos."
  )

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
