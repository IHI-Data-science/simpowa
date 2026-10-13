reports_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    table_data <- eventReactive(input$load, {
      head(mtcars, 10)
    })

    output$table <- renderTable({
      table_data()
    })

  })
}