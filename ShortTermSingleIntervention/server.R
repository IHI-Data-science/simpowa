# A short-term semi-field experiment (SFE) testing single intervention

# This is the server logic of a Shiny web application. You can run the application by running its ui.

library(shiny)
library(dplyr) # case_when function
library(lattice) # for graphics
library(lme4) # for glmer
library(ggplot2) # for ggplot
library(glmmTMB) # for glmm with TMB

if (file.exists("pages/simulate_busy.R")) {
  source("pages/simulate_busy.R", local = TRUE)
} else if (file.exists("../pages/simulate_busy.R")) {
  source("../pages/simulate_busy.R", local = TRUE)
}

# Define server logic required to define design scenarios, simulate mosquito data, estimate p-values and power.
function(input, output, session) {
  
  dat <- reactive({
    req(input$n.ch.per.trt)
    # design choices 
    n.ch.per.trt <- input$n.ch.per.trt
    intervention.lev <- 0:1 # intervention levels: 0 means no intervention and 1 means there is intervention
    # make template data set representing design 
    dat <-expand.grid(replicates = 1:input$n.ch.per.trt, intervention = intervention.lev)
    # create chambers/replicates id
    dat$chamber <- factor(paste(dat$intervention, dat$replicates, sep="-"))
    # rearranging data set in a useful order
    dat <- dat[, c("replicates", "intervention", "chamber")]
    dat
    })
    
  sim.dat.fun <- function(data,b.0,b.i,chamber.var){
    chamber.re <- rnorm(nlevels(data$chamber), sd = sqrt(chamber.var))
    names(chamber.re) <- levels(data$chamber)
    data$lin.pred.fixed <- round(b.0 +  b.i * data$intervention, 2)
    data$lin.pred <-
      round(data$lin.pred.fixed + chamber.re[as.character(data$chamber)], 2)
    data$mosquito.count <-
      rpois(nrow(data),exp(data$lin.pred))
    data
  }

  sim_busy <- reactiveVal(FALSE)
  sim_table <- reactiveVal(NULL)
  sim_power <- reactiveVal(NULL)

  observeEvent(input$simulate, {
    req(input$lamb, input$intervention.eff, input$chamb.var, input$nsim, dat())
    sim_busy(TRUE)
    if (exists("set_simulate_busy")) set_simulate_busy(session, TRUE)

    session$onFlushed(function() {
      tryCatch({
        isolate({
          lambda <- input$lamb
          intervention.effect <- 1 - input$intervention.eff
          chamber.var <- input$chamb.var
          nsim <- input$nsim
          design <- dat()
          b.0 <- log(lambda)
          b.i <- log(intervention.effect)

          withProgress(message = "Running simulations", value = 0, session = session, {
            incProgress(0.08, detail = "Generating example dataset")
            set.seed(123)
            dati <- design
            chamber.re <- rnorm(nlevels(dati$chamber), sd = sqrt(chamber.var))
            names(chamber.re) <- levels(dati$chamber)
            dati$lin.pred.fixed <- round(b.0 + b.i * dati$intervention, 2)
            dati$lin.pred <-
              round(dati$lin.pred.fixed + chamber.re[as.character(dati$chamber)], 2)
            dati$mosquito.count <- rpois(nrow(dati), exp(dati$lin.pred))
            sim_table(dati)

            set.seed(123)
            pvals <- numeric(nsim)
            for (i in seq_len(nsim)) {
              simdat2 <- sim.dat.fun(design, b.0, b.i, chamber.var)
              model.intervention <- suppressMessages(suppressWarnings(
                glmer(mosquito.count ~ intervention + (1 | chamber), family = "poisson", data = simdat2)
              ))
              pvals[i] <- suppressMessages(suppressWarnings(
                coef(summary(model.intervention))[2, "Pr(>|z|)"]
              ))
              incProgress(0.9 / nsim, detail = paste("Simulation", i, "of", nsim))
            }
            n.sig <- sum(pvals < 0.05, na.rm = TRUE)
            sim_power(list(paste0(round(100 * n.sig / nsim, 2), "%"), n.sig, nsim))
          })
        })
      }, finally = {
        sim_busy(FALSE)
        if (exists("set_simulate_busy")) set_simulate_busy(session, FALSE)
      })
    }, once = TRUE)
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
    power.string <- sim_power()[[1]]
    n.sig <- sim_power()[[2]]
    nsim <- sim_power()[[3]]
    power.num <- as.numeric(gsub("%", "", power.string))
    color <- if (power.num >= 80) {
      "green"
    } else if (power.num >= 70) {
      "orange"
    } else {
      "red"
    }
    HTML(paste0(
      "<p>Given ", nsim, " simulations, and ", n.sig, " significant p-values, the power estimate is
      <span style='color:", color, "; font-weight:bold;'>", power.string, "</span>.</p>"
    ))
  })
  
  
  
}
