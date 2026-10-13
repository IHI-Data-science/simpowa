# Load a standalone intervention folder (ui.R + server.R) as a namespaced module
# so the four apps can share one Shiny session without colliding input IDs.

namespace_ui <- function(x, ns) {
  if (inherits(x, "shiny.tag")) {
    attribs <- x$attribs
    if (!is.null(attribs)) {
      for (key in c("id", "for", "data-for")) {
        val <- attribs[[key]]
        if (is.character(val) && length(val) == 1 && nzchar(val)) {
          attribs[[key]] <- ns(val)
        }
      }
      x$attribs <- attribs
    }
    if (length(x$children)) {
      x$children <- lapply(x$children, namespace_ui, ns = ns)
    }
    x
  } else if (is.null(x) || is.atomic(x) || inherits(x, "html")) {
    x
  } else if (is.list(x)) {
    out <- lapply(x, namespace_ui, ns = ns)
    attributes(out) <- attributes(x)
    class(out) <- class(x)
    out
  } else {
    x
  }
}

load_intervention <- function(dir, id) {
  env <- new.env(parent = globalenv())
  ui_file <- file.path(dir, "ui.R")
  server_file <- file.path(dir, "server.R")

  ui_source <- source(ui_file, local = env, keep.source = FALSE)
  ui_obj <- if (exists("ui", envir = env, inherits = FALSE)) {
    env$ui
  } else {
    ui_source$value
  }

  server_source <- source(server_file, local = env, keep.source = FALSE)
  server_fn <- if (exists("server", envir = env, inherits = FALSE)) {
    env$server
  } else {
    server_source$value
  }

  if (!is.function(server_fn)) {
    stop("No server function found in ", server_file)
  }

  ns <- NS(id)
  # Wrap in a div so shiny.router can attach data-path / router-hidden.
  # page_sidebar() is a bslib_page tag list; a plain list would be ignored.
  list(
    ui = shiny::div(namespace_ui(ui_obj, ns)),
    server = function() {
      moduleServer(id, server_fn)
    }
  )
}
