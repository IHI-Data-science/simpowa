# A short-term semi-field experiment (SFE) testing single intervention

# This is the user-interface definition of a Shiny web application. 
# You can run the application by clicking 'Run App' above.

library(shiny)
library(bslib)

if (file.exists("pages/simulate_busy.R")) {
  source("pages/simulate_busy.R", local = TRUE)
} else if (file.exists("../pages/simulate_busy.R")) {
  source("../pages/simulate_busy.R", local = TRUE)
}

nchambers <- numericInput(
  "n.ch.per.trt", # inputID (for server)
  "Number of chambers or compartments per treatment:", # label
  min = 1,
  max = 96,
  value = 4,
  step = 1
  ) 
lambda <- numericInput(
  "lamb", 
  "Mean recaptured mosquito count in a control chamber:", # label
  min = 0,
  max = 100000,
  value = 50,  
  step = 1
  )
intervention_effect <- numericInput(
  "intervention.eff", 
  "*Intervention effect in a treatment chamber relative to a control chamber, e.g., 0.8 for 80% effect:", # label
  min = 0,
  max = 1,
  value = .8,
  step = .01
  )
chamb_var <-numericInput(
  "chamb.var", 
  "*Assign inter-chamber variance:", # label
  min = 0,
  max = 1,
  value = 0.18,
  step = 0.01
  )
n_sim <- numericInput(
  "nsim", 
  "Total number of simulations:", # label
  min = 1,
  max = 1000000,
  value = 100)

# Define UI for application that draws a histogram
layout_sidebar(
    tags$style(HTML(if (exists("simulate_busy_css")) simulate_busy_css else "")),

    # Sidebar with a number input for numeric options
    sidebar = sidebar(
      title = p(strong("Design Choices for a short-term SFE testing single intervention")),
      helpText("After setting experimental design scenarios and parameter choices, 
    the inter-chamber variance, a single data set can now be simulated and generated. 
               The default values are taken from Kipingu et. al (2025)"),
      accordion(
        open = TRUE,
        accordion_panel(
          "Chambers",
          nchambers
        ),
        accordion_panel(
          "Mosquitoes", 
          lambda,
          helpText("*For short-term SFEs, recaptured mosquitoes can be used as a proxy of how many mosquitoes should be released")
        ),
        accordion_panel(
          "Intervention", 
          intervention_effect,
          helpText("*% reduction in mosquitoes due to intervention")
        ),
        accordion_panel(
          "Variance", # label
          chamb_var,
          helpText("The estimated variance of 0.1807 used was based on published SFE data. Observe how power decreases with an increase of variance."),
          helpText("*With only a single time point, it's hard to separate consistent variation between chambers from variation between observations within chambers.")
        ),
        accordion_panel(
          "Simulate", # label
          n_sim,
          helpText("Notes: number of simulations is set to 100 for illustration purpose."),
          helpText("However, we recommend setting it to a much higher value, e.g., 1000.")
        )
      ),
      if (exists("simulate_action_button")) simulate_action_button() else actionButton("simulate", "Simulate", class = "btn-primary")
    ),
      
    h4("simpower: An interactive power analysis tool to inform semi-field vector control trials"),
    # Main panel for displaying outputs ----
    card(
      card_header("Table"),
      height = "600px",
      # Panel with table ----
      tableOutput("table")
      ),
    card(
      uiOutput("helptext")
    ),
      # Add card for Explanations on the table and the power
    card(
        tags$div(
          tags$p("A function already described in",
                 tags$a("Kipingu et. al (2025)", href = "https://doi.org/10.1186/s12936-025-05454-y", target = "_blank"),
                 " automates the simulation process that then produces a table containing simulated linear predictors and mosquito counts as an output (as shown above).")
          ),
        helpText("Using the simulated linear predictors (sum of terms which include coefficients e.g., as an intercept and as a slope with their associated explanatory variables), 
                 expected mosquito counts will then be generated using a Poisson or a negative binomial distribution.
                 Since power cannot be estimated from a single simulation, there is a need to simulate multiple data sets.
                 Again, another function was created to output a list of p-values by automating the previous function to simulate multiple data sets based on the number of simulations assigned.
                 Therefore, the percentage of the data sets whose p-values are less than 0.05 is the power estimate.")
    )
    
    
)
