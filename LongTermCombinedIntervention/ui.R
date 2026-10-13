# A long-term semi-field experiment (SFE) testing combined interventions

# This is the user-interface definition of a Shiny web application.
# You can run the application by clicking 'Run App' above.

library(shiny)
library(bslib)

if (file.exists("pages/simulate_busy.R")) {
  source("pages/simulate_busy.R", local = TRUE)
} else if (file.exists("../pages/simulate_busy.R")) {
  source("../pages/simulate_busy.R", local = TRUE)
}

numbers_of_chambers_per_treatment <- numericInput(
  "n_chambers_per_treatment",
  "Number of chambers or compartments per treatment:",
  min = 1,
  max = 16,
  value = 4,
  step = 1
)

experiment_length <- numericInput(
  "exp_length",
  "Experiment length in days:",
  min = 90,
  max = 1000,
  value = 90,
  step = 1
)

sampling_frequency <- selectInput(
  inputId = "samp_freq",
  label = "Sampling frequency:",
  choices = c(
    "Daily" = "daily",
    "Weekly" = "weekly",
    "Biweekly" = "biweekly",
    "Monthly" = "monthly"
  ),
  selected = "weekly"
)

mean_mosquitoes_sampled <- numericInput(
  "mean_mosquitoes",
  "Mean sampled mosquito count in a control chamber:",
  min = 0,
  max = 200,
  value = 10,
  step = 1
)

intervention_1_effect <- numericInput(
  "intervention_1_effect",
  "*Effect of intervention 1 by the end of the experiment relative to a control chamber, e.g., 0.8 for 80% effect:",
  min = 0,
  max = 1,
  value = 0.8,
  step = 0.01
)

intervention_2_effect <- numericInput(
  "intervention_2_effect",
  "*Effect of intervention 2 by the end of the experiment relative to a control chamber, e.g., 0.7 for 70% effect:",
  min = 0,
  max = 1,
  value = 0.7,
  step = 0.01
)

interaction_effect <- numericInput(
  "interaction_effect",
  "*Extra interaction effect of interventions 1 and 2 by the end of the experiment, e.g., 0.8 for 80% effect:",
  min = 0,
  max = 1,
  value = 0.8,
  step = 0.01
)

chamber_variance <- numericInput(
  "chamber_var",
  "*Assign inter-chamber variance:",
  min = 0,
  max = 1,
  value = 0.1807,
  step = 0.01
)

time_variance <- numericInput(
  "time_var",
  "*Assign between-sampling-time variance:",
  min = 0,
  max = 2,
  value = 0.2266,
  step = 0.01
)

dispersion <- numericInput(
  "theta",
  "Negative binomial dispersion parameter (theta):",
  min = 0.1,
  max = 100,
  value = 10,
  step = 0.1
)

n_simulations <- numericInput(
  "n_sim",
  "Total number of simulations:",
  min = 1,
  max = 1000000,
  value = 100
)

ui <- layout_sidebar(
  tags$style(HTML(if (exists("simulate_busy_css")) simulate_busy_css else "")),

  sidebar = sidebar(
    title = p(strong("Design Choices for a long-term SFE testing combined interventions")),
    helpText("After setting experimental design scenarios and parameter choices,
    a single data set can now be simulated and generated.
               The default values are taken from Kipingu et. al (2025)"),
    accordion(
      open = TRUE,
      accordion_panel(
        "Chambers",
        numbers_of_chambers_per_treatment,
        helpText("*Four treatment arms: control, intervention 1, intervention 2, and both. Four chambers per arm means 16 chambers in total.")
      ),
      accordion_panel(
        "Duration",
        experiment_length,
        sampling_frequency,
        helpText("*For a 90-day experiment: daily = 90 sampling points, weekly = 12, biweekly = 6, monthly = 3.")
      ),
      accordion_panel(
        "Mosquitoes",
        mean_mosquitoes_sampled,
        helpText("*For long-term SFEs, this is the expected number sampled from a self-propagating population in a control chamber.")
      ),
      accordion_panel(
        "Intervention 1",
        intervention_1_effect,
        helpText("*% reduction in mosquitoes due to intervention 1 by the end of the experiment (e.g., ITN).")
      ),
      accordion_panel(
        "Intervention 2",
        intervention_2_effect,
        helpText("*% reduction in mosquitoes due to intervention 2 by the end of the experiment (e.g., PPFa).")
      ),
      accordion_panel(
        "Interaction",
        interaction_effect,
        helpText("*% extra reduction from using both interventions together, beyond multiplying their separate effects.")
      ),
      accordion_panel(
        "Variance",
        chamber_variance,
        helpText("The estimated chamber variance of 0.1807 used was based on published SFE data. Observe how power decreases with an increase of variance."),
        time_variance,
        helpText("The estimated time variance of 0.2266 accounts for random differences between sampling occasions."),
        dispersion,
        helpText("*With multiple time points, a negative binomial model separates chamber variation from extra variation within a chamber at one time (theta = 10 in the paper).")
      ),
      accordion_panel(
        "Simulate",
        n_simulations,
        helpText("Notes: number of simulations is set to 100 for illustration purpose."),
        helpText("However, we recommend setting it to a much higher value, e.g., 1000."),
        helpText("Daily sampling with many chambers is slower because each simulation fits a negative binomial mixed model.")
      )
    ),
    if (exists("simulate_action_button")) simulate_action_button() else actionButton("simulate", "Simulate", class = "btn-primary")
  ),

  h4("simpower: An interactive power analysis tool to inform semi-field vector control trials"),
  card(
    uiOutput("helptext")
  ),
  card(
    card_header("Mosquito counts over time"),
    height = "520px",
    plotOutput("count_plot", height = "460px"),
    helpText("One simulated dataset, in the style of Kipingu et al. (2025) Figure 2. Each line is a chamber. Black = control, blue = intervention 1, purple = intervention 2, red = both (interaction).")
  ),
  card(
    card_header("Simulated data (first 32 rows)"),
    height = "420px",
    tableOutput("table")
  ),
  card(
    tags$div(
      tags$p(
        "A function already described in",
        tags$a("Kipingu et. al (2025)", href = "https://doi.org/10.1186/s12936-025-05454-y", target = "_blank"),
        " automates the simulation. The graph shows one simulated dataset; the table is the same data in numeric form."
      )
    ),
    helpText("Time is scaled from 0 to 1 over the experiment. Effects accumulate through intervention × time terms. The extra combined effect is the three-way interaction (intervention 1 × intervention 2 × time).
                 Expected mosquito counts are generated from a negative binomial distribution, with random effects for chamber and sampling time.
                 Power is the percentage of simulated data sets whose likelihood-ratio p-value for that three-way interaction is less than 0.05.")
  )
)
