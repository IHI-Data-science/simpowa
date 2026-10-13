# A short-term semi-field experiment (SFE) testing combined interventions

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

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  dat <- reactive({
    req(input$n.ch.per.trt)
    # design choices 
    n.ch.per.trt <- input$n.ch.per.trt
    intvn1.lev <- 0:1 # intvn1 levels: 0 means no intvn1 and 1 means there is intvn1. e.g., ITN
    intvn2.lev <- 0:1 # intvn2 levels: 0 means no intvn2 and 1 means there is intvn2. e.g., PPFa
    # make a template data set representing design 
    dat <-
      expand.grid(replicates = 1:n.ch.per.trt, intvn1 = intvn1.lev, intvn2 = intvn2.lev)
    dat$chamber <- factor(paste(dat$intvn1, dat$intvn2, dat$replicates, sep = "-"))
    dat$ixn <- dat$intvn1 * dat$intvn2 # interaction btn intvn1 and intvn2
    # rearranging data set in a useful order
    dat <- dat[, c("replicates", "intvn1", "intvn2", "ixn", "chamber")]
    dat
  })
  
  sim.dat.fun <- function(data,b.0,b.intvn1,b.intvn2,b.ixn,chamber.var){
    chamber.re <- rnorm(nlevels(data$chamber), sd = sqrt(chamber.var))
    names(chamber.re) <- levels(data$chamber)
    data$lin.pred.fixed <-
      b.0 + b.intvn1 * data$intvn1 + b.intvn2 * data$intvn2 + b.ixn * data$ixn
    data$lin.pred <-
      data$lin.pred.fixed + chamber.re[as.character(data$chamber)]
    data$mosquito.count <- rpois(nrow(data), exp(data$lin.pred))
    data
  }

  sim_busy <- reactiveVal(FALSE)
  sim_table <- reactiveVal(NULL)
  sim_power <- reactiveVal(NULL)

  observeEvent(input$simulate, {
    req(input$lamb, input$intvn1.eff, input$intvn2.eff, input$ixn.eff, input$chamb.var, input$nsim, dat())
    sim_busy(TRUE)
    if (exists("set_simulate_busy")) set_simulate_busy(session, TRUE)

    session$onFlushed(function() {
      tryCatch({
        isolate({
          lambda <- input$lamb
          intvn1.effect <- 1 - input$intvn1.eff
          intvn2.effect <- 1 - input$intvn2.eff
          ixn.effect <- 1 - input$ixn.eff
          chamber.var <- input$chamb.var
          nsim <- input$nsim
          design <- dat()
          b.0 <- log(lambda)
          b.intvn1 <- log(intvn1.effect)
          b.intvn2 <- log(intvn2.effect)
          b.ixn <- log(ixn.effect)

          withProgress(message = "Running simulations", value = 0, session = session, {
            incProgress(0.08, detail = "Generating example dataset")
            set.seed(123)
            dati <- design
            chamber.re <- rnorm(nlevels(dati$chamber), sd = sqrt(chamber.var))
            names(chamber.re) <- levels(dati$chamber)
            dati$lin.pred.fixed <-
              b.0 + b.intvn1 * dati$intvn1 + b.intvn2 * dati$intvn2 + b.ixn * dati$ixn
            dati$lin.pred <-
              dati$lin.pred.fixed + chamber.re[as.character(dati$chamber)]
            dati$mosquito.count <- rpois(nrow(dati), exp(dati$lin.pred))
            sim_table(dati)

            set.seed(1234)
            pvals <- numeric(nsim)
            for (i in seq_len(nsim)) {
              simdat2 <- sim.dat.fun(design, b.0, b.intvn1, b.intvn2, b.ixn, chamber.var)
              fit.ixn <- suppressMessages(suppressWarnings(
                glmer(mosquito.count ~ intvn1 + intvn2 + ixn + (1 | chamber), family = "poisson", data = simdat2)
              ))
              fit.noixn <- suppressMessages(suppressWarnings(
                glmer(mosquito.count ~ intvn1 + intvn2 + (1 | chamber), family = "poisson", data = simdat2)
              ))
              pvals[i] <- suppressMessages(suppressWarnings(
                anova(fit.ixn, fit.noixn)[2, "Pr(>Chisq)"]
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
    } else if (power.num >= 50) {
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

