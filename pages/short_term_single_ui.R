short_single_page <- div(
  # h2("Short-Term Effect — Single Intervention"),
  page_sidebar(

    # Application title
    title = h4("Short-Term Effect for Single Intervention"),

    # Sidebar with a number input for numeric options
    sidebar = sidebar(
      title = p(strong("Design Choices for a short-term SFE testing single intervention")),
      helpText("After setting experimental design scenarios and parameter choices,
    the inter-chamber variance, a single data set can now be simulated and generated.
               The default values are taken from Kipingu et. al (2025)"),
      accordion(
        open = F,
        accordion_panel(
          "Chambers",
          numericInput(
            "n.ch.per.trt", # inputID (for server)
            "Number of chambers or compartments per treatment:", # label
            min = 1,
            max = 96,
            value = 4,
            step = 1
          )
        ),
        accordion_panel(
          "Mosquitoes",
          numericInput(
            "lamb",
            "Mean recaptured mosquito count in a control chamber:", # label
            min = 0,
            max = 100000,
            value = 50,
            step = 1
          ),
          helpText("*For short-term SFEs, recaptured mosquitoes can be used as a proxy of how many mosquitoes should be released")
        ),
        accordion_panel(
          "Intervention",
          numericInput(
            "intervention.eff",
            "*Intervention effect in a treatment chamber relative to a control chamber, e.g., 0.8 for 80% effect:", # label
            min = 0,
            max = 1,
            value = .8,
            step = .01
          ),
          helpText("*% reduction in mosquitoes due to intervention")
        ),
        accordion_panel(
          "Variance", # label
          numericInput(
            "chamb.var",
            "*Assign inter-chamber variance:", # label
            min = 0,
            max = 1,
            value = 0.18,
            step = 0.01
          ),
          helpText("The estimated variance of 0.1807 used was based on published SFE data. Observe how power decreases with an increase of variance."),
          helpText("*With only a single time point, it's hard to separate consistent variation between chambers from variation between observations within chambers.")
        ),
        accordion_panel(
          "Simulate", # label
          numericInput(
            "nsim",
            "Total number of simulations:", # label
            min = 1,
            max = 1000000,
            value = 100),
          helpText("Notes: number of simulations is set to 100 for illustration purpose."),
          helpText("However, we recommend setting it to a much higher value, e.g., 1000."),
        ),
          actionButton("simmulate_short_single", "Simmulate"),
      )
    ),

    # Main panel for displaying outputs ----
    # Output: A tabset that combines three panels ----
    card(
      card_header("Table"),
      height = "600px",
      # Panel with table ----
      tableOutput("short_single_table")
    ),
    card(
      uiOutput("short_single_helptext")
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
  # sidebarLayout(
  #   sidebarPanel(
  #     sliderInput("bins", "Number of bins:", min = 1, max = 50, value = 30),
  #     actionButton("back_home_1", "⬅ Back to Home")
  #   ),
  #
  #   mainPanel(
  #     p("This page demonstrates a short-term single intervention analysis."),
  #     br(),
  #     plotOutput("distPlot")
  #   )
  # )
)