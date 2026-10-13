# Shared busy-state helpers for the Simulate button.

simulate_busy_css <- '
.simpowa-spinner {
  display: none;
  width: 16px;
  height: 16px;
  border: 2px solid #c5d4e8;
  border-top-color: #1a73e8;
  border-radius: 50%;
  animation: simpowa-spin 0.7s linear infinite;
  vertical-align: middle;
  margin-right: 8px;
}
button.simpowa-busy .simpowa-spinner,
.simpowa-loading .simpowa-spinner {
  display: inline-block;
}
@keyframes simpowa-spin { to { transform: rotate(360deg); } }
.simpowa-loading {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #444;
  padding: 8px 0;
}
button.btn-primary.simpowa-busy {
  opacity: 0.8;
  cursor: wait;
}
'

simulate_busy_js <- '
function applySimpowaBusy(btn, busy) {
  if (!btn) return;
  btn.disabled = !!busy;
  btn.classList.toggle("simpowa-busy", !!busy);
  var label = btn.querySelector(".simpowa-btn-label");
  if (label) label.textContent = busy ? "Simulating..." : "Simulate";
  var root = btn.closest("[data-path]") || document;
  var help = root.querySelector("[id$=\\"-helptext\\"], #helptext");
  if (help && busy) {
    help.innerHTML = "<div class=\\"simpowa-loading\\"><span class=\\"simpowa-spinner\\"></span><span>Running simulations. This can take a minute...</span></div>";
  }
}
function registerSimpowaBusy() {
  if (window.simpowaBusyHandler || typeof Shiny === "undefined") return;
  window.simpowaBusyHandler = true;
  Shiny.addCustomMessageHandler("simpowa-busy", function(msg) {
    applySimpowaBusy(document.getElementById(msg.id), msg.busy);
  });
  $(document).on("click", "button.btn-primary", function() {
    if (!this.querySelector(".simpowa-btn-label")) return;
    applySimpowaBusy(this, true);
  });
}
registerSimpowaBusy();
if (window.jQuery) {
  $(document).on("shiny:connected", registerSimpowaBusy);
}
'

simulate_action_button <- function(id = "simulate") {
  actionButton(
    id,
    label = tagList(
      span(class = "simpowa-spinner"),
      span(class = "simpowa-btn-label", "Simulate")
    ),
    class = "btn-primary"
  )
}

set_simulate_busy <- function(session, busy) {
  session$sendCustomMessage("simpowa-busy", list(
    id = session$ns("simulate"),
    busy = isTRUE(busy)
  ))
}

simulate_loading_ui <- function(detail = "Running simulations. This can take a minute...") {
  div(
    class = "simpowa-loading",
    span(class = "simpowa-spinner"),
    span(detail)
  )
}
