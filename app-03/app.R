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
  title = "App 03 · Primera tool",
  sidebar = sidebar(
    selectInput("species", "Especie", choices = species),
    shinychat::chat_ui(
      "chat",
      messages = paste(
        "Ahora sí puedo consultar los datos reales.",
        "Prueba: **resume los pingüinos Adelia**."
      ),
      placeholder = "Resume una especie..."
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

  output$table <- renderTable(head(data(), 10), striped = TRUE, hover = TRUE)

  # tool ------------------------------------------------------------------

  summarize_penguins <- function(species) {
    if (tolower(species) == "todas") {
      df <- penguins
      selected_species <- "Todas"
    } else {
      index <- match(tolower(species), tolower(unique(penguins$especie)))

      if (is.na(index)) {
        stop("Especie no disponible. Usa Adelia, Barbijo, Papúa o Todas.")
      }

      selected_species <- unique(penguins$especie)[index]
      df <- penguins[penguins$especie == selected_species, ]
    }

    list(
      especie = selected_species,
      registros = nrow(df),
      masa_promedio_g = round(mean(df$masa_corporal_g, na.rm = TRUE)),
      largo_aleta_promedio_mm = round(mean(df$largo_aleta_mm, na.rm = TRUE), 1),
      islas = sort(unique(df$isla))
    )
  }

  chat <- ellmer::chat_openai(
    model = "gpt-5-nano",
    system_prompt = paste(
      "Responde brevemente en español.",
      "Usa summarize_penguins para toda pregunta sobre los datos y no inventes resultados."
    )
  )

  chat$register_tool(tool(
    summarize_penguins,
    "Calcula un resumen real de una especie usando el dataset de pingüinos.",
    arguments = list(
      species = type_enum(c("Adelia", "Barbijo", "Papúa", "Todas"), "Especie que se quiere resumir.")
    )
  ))

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
