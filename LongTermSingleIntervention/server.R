# A long-term semi-field experiment (SFE) testing single intervention

# This is the server logic of a Shiny web application. You can run the application by running its ui.

library(shiny)
library(lme4)
library(ggplot2)

if (file.exists("pages/simulate_busy.R")) {
  source("pages/simulate_busy.R", local = TRUE)
} else if (file.exists("../pages/simulate_busy.R")) {
  source("../pages/simulate_busy.R", local = TRUE)
}

# Design table, simulation, and power follow Kipingu et al. (2025) eq. 3
# and the long-term single-intervention functions in the simpowa package.

sampling_interval_days <- function(samp_freq) {
  switch(
    tolower(samp_freq),
    daily = 1,
    weekly = 7,
    biweekly = 14,
    monthly = 30,
    stop("Invalid sampling frequency. Choose daily, weekly, biweekly, or monthly.")
  )
}

build_design <- function(n_chambers_per_treatment, exp_length, samp_freq) {
  n_time_points <- floor(exp_length / sampling_interval_days(samp_freq))
  time_seq <- (0:n_time_points) / n_time_points

  dat <- expand.grid(
    replicates = 1:n_chambers_per_treatment,
    intervention = 0:1,
    time = time_seq
  )
  dat$intervention_time <- dat$intervention * dat$time
  dat$chamber <- factor(paste(dat$intervention, dat$replicates, sep = "-"))
  dat$time_factor <- factor(dat$time)
  dat[, c("replicates", "intervention", "chamber", "time", "time_factor", "intervention_time")]
}

simulate_long_term_single <- function(data, intercept, intervention_time_coef,
                                      chamber_var, time_var, theta) {
  chamber_re <- rnorm(nlevels(data$chamber), sd = sqrt(chamber_var))
  names(chamber_re) <- levels(data$chamber)

  time_re <- rnorm(nlevels(data$time_factor), sd = sqrt(time_var))
  names(time_re) <- levels(data$time_factor)

  # Paper: βT and βI are 0 in the simulated data; the effect is βT,I × time × intervention.
  # The constant intervention term is kept at log(1) = 0 so the fitted model can still include it.
  data$lin.pred.fixed <- round(
    intercept + intervention_time_coef * data$intervention_time,
    2
  )
  data$lin.pred <- round(
    data$lin.pred.fixed +
      chamber_re[as.character(data$chamber)] +
      time_re[as.character(data$time_factor)],
    2
  )
  data$mosquito.count <- rnbinom(
    nrow(data),
    mu = exp(data$lin.pred),
    size = theta
  )
  data
}

server <- function(input, output, session) {

  dat <- reactive({
    req(input$n_chambers_per_treatment, input$exp_length, input$samp_freq)
    build_design(
      n_chambers_per_treatment = input$n_chambers_per_treatment,
      exp_length = input$exp_length,
      samp_freq = input$samp_freq
    )
  })

  sim_busy <- reactiveVal(FALSE)
  sim_table <- reactiveVal(NULL)
  sim_power <- reactiveVal(NULL)
  sim_meta <- reactiveVal(NULL)

  observeEvent(input$simulate, {
    req(
      input$n_chambers_per_treatment,
      input$exp_length,
      input$samp_freq,
      input$mean_mosquitoes,
      input$intervention_effect,
      input$chamber_var,
      input$time_var,
      input$theta,
      input$n_sim,
      dat()
    )
    sim_busy(TRUE)
    if (exists("set_simulate_busy")) set_simulate_busy(session, TRUE)

    session$onFlushed(function() {
      tryCatch({
        isolate({
          remaining <- max(1 - input$intervention_effect, 1e-8)
          intercept <- log(input$mean_mosquitoes)
          intervention_time_coef <- log(remaining)
          chamber_var <- input$chamber_var
          time_var <- input$time_var
          theta <- input$theta
          n_sim <- input$n_sim
          samp_freq <- input$samp_freq
          exp_length <- input$exp_length
          design <- dat()

          withProgress(message = "Running simulations", value = 0, session = session, {
            incProgress(0.08, detail = "Generating example dataset")
            set.seed(123)
            sim_table(simulate_long_term_single(
              data = design,
              intercept = intercept,
              intervention_time_coef = intervention_time_coef,
              chamber_var = chamber_var,
              time_var = time_var,
              theta = theta
            ))
            sim_meta(list(samp_freq = samp_freq, exp_length = exp_length))

            set.seed(123)
            pvals <- numeric(n_sim)
            for (i in seq_len(n_sim)) {
              simdat <- simulate_long_term_single(
                data = design,
                intercept = intercept,
                intervention_time_coef = intervention_time_coef,
                chamber_var = chamber_var,
                time_var = time_var,
                theta = theta
              )
              pvals[i] <- tryCatch({
                model_with_interaction <- suppressMessages(suppressWarnings(
                  glmer.nb(
                    mosquito.count ~ intervention * time + (1 | chamber) + (1 | time_factor),
                    data = simdat
                  )
                ))
                model_without_interaction <- suppressMessages(suppressWarnings(
                  update(model_with_interaction, ~ . - intervention:time)
                ))
                suppressMessages(suppressWarnings(
                  anova(model_with_interaction, model_without_interaction)[2, "Pr(>Chisq)"]
                ))
              }, error = function(e) NA_real_)
              incProgress(0.9 / n_sim, detail = paste("Simulation", i, "of", n_sim))
            }
            n_sig <- sum(pvals < 0.05, na.rm = TRUE)
            sim_power(list(paste0(round(100 * n_sig / n_sim, 2), "%"), n_sig, n_sim))
          })
        })
      }, finally = {
        sim_busy(FALSE)
        if (exists("set_simulate_busy")) set_simulate_busy(session, FALSE)
      })
    }, once = TRUE)
  })

  output$count_plot <- renderPlot({
    req(sim_table(), sim_meta())
    simdat <- sim_table()
    meta <- sim_meta()
    interval <- sampling_interval_days(meta$samp_freq)
    time_unit <- switch(
      tolower(meta$samp_freq),
      daily = "Days",
      weekly = "Weeks",
      biweekly = "Biweeks",
      monthly = "Months",
      "Time"
    )
    simdat$time_axis <- simdat$time * (meta$exp_length / interval)
    simdat$treatment <- ifelse(simdat$intervention == 0, "Control", "Intervention")

    ggplot(simdat, aes(
      x = time_axis,
      y = mosquito.count,
      group = chamber,
      colour = treatment
    )) +
      geom_line() +
      geom_point() +
      scale_colour_manual(values = c(Control = "black", Intervention = "red")) +
      labs(
        x = paste0("Time (", time_unit, ")"),
        y = "Mosquito counts",
        colour = "Treatments"
      ) +
      theme_bw()
  })

  output$table <- renderTable({
    req(sim_table())
    head(sim_table(), 32)
  })

  output$helptext <- renderUI({
    if (isTRUE(sim_busy())) {
      if (exists("simulate_loading_ui")) {
        return(simulate_loading_ui("Running simulations. This can take a minute..."))
      }
      return(p("Simulating..."))
    }
    if (is.null(sim_power())) {
      return(p("Change the default values if needed, then press Simulate."))
    }
    power_string <- sim_power()[[1]]
    n_sig <- sim_power()[[2]]
    n_sim <- sim_power()[[3]]
    power_num <- as.numeric(gsub("%", "", power_string))

    color <- if (power_num >= 80) {
      "green"
    } else if (power_num >= 70) {
      "orange"
    } else {
      "red"
    }

    HTML(paste0(
      "<p>Given ", n_sim, " simulations, and ", n_sig,
      " significant p-values, the power estimate is
      <span style='color:", color, "; font-weight:bold;'>", power_string, "</span>.</p>"
    ))
  })
}
