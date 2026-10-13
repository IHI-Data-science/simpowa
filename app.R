library(shiny)
library(shiny.router)
library(bslib)
library(dplyr)
library(lattice)
library(lme4)
library(ggplot2)
library(glmmTMB)

source("pages/home.R")
source("pages/load_intervention.R")
source("pages/simulate_busy.R")

short_single <- load_intervention("ShortTermSingleIntervention", "short_single")
short_combined <- load_intervention("ShortTermCombinedIntervention", "short_combined")
long_single <- load_intervention("LongTermSingleIntervention", "long_single")
long_combined <- load_intervention("LongTermCombinedIntervention", "long_combined")

ui <- fluidPage(
  tags$head(
    tags$link(rel = "icon", type = "image/png", href = "favicon.png"),
    tags$title("simpowa"),
    tags$style(HTML(paste0(
      simulate_busy_css,
      "\n.router-hidden { display: none !important; }\n"
    ))),
    tags$script(HTML(simulate_busy_js)),
    tags$script(HTML("
      function simpowaApplyHashRoute() {
        var match = location.hash.match(/^#!\\/(.*)$/);
        var path = (match && match[1]) ? match[1] : '/';
        if (typeof switchUI === 'function') switchUI(path || '/');
      }
      $(document).on('shiny:connected', function() {
        simpowaApplyHashRoute();
        setTimeout(simpowaApplyHashRoute, 0);
        setTimeout(simpowaApplyHashRoute, 250);
      });
      $(window).on('hashchange', simpowaApplyHashRoute);
    "))
  ),
  titlePanel(
    title = div(
      style = "display:flex;align-items:center;gap:14px;",
      img(src = "simpowa-logo-2.png", height = 48, alt = "simpowa"),
      span("Power Analysis Framework for Semi-Field Vector Control Experiments")
    ),
    windowTitle = "simpowa"
  ),
  div(
    style = "margin-bottom: 12px;",
    tags$a(href = "#!/", "Home")
  ),
  router_ui(
    route("/", home_page),
    route("short-single", short_single$ui),
    route("short-combined", short_combined$ui),
    route("long-single", long_single$ui),
    route("long-combined", long_combined$ui)
  )
)

server <- function(input, output, session) {
  router_server()

  observeEvent(input$final_choice, {
    path <- paste(input$final_choice$duration, input$final_choice$type, sep = "-")
    change_page(path)
  })

  short_single$server()
  short_combined$server()
  long_single$server()
  long_combined$server()
}

shinyApp(ui, server)
