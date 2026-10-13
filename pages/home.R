# Home picker: short/long × single/combined → shiny.router pages.

home_page <- div(
  class = "simpowa-home",
  p("This tool simulates mosquito count data under short-term and long-term semi-field experimental design scenarios, evaluating single or combined interventions. It incorporates fixed treatment effects, random chamber-level or sampling time-level variability to support robust power analysis for short-term or long-term semi-field experimental planning."),
  p(HTML('This tool is an extension of a simulation based power analysis framework developed by <a href="https://doi.org/10.1186/s12936-025-05454-y" target="_blank">Kipingu et. al 2025.</a> Therefore, all parameter values for the examples below are taken directly from the same study. Visit <a href="https://doi.org/10.1186/s12936-025-05454-y" target="_blank">Kipingu et al. 2025 </a> or <a href="https://doi.org/10.1111/2041-210X.12306" target="_blank"> Johnson et al. 2014</a> for more information and description regarding simulation-based power analysis.')),
  p("Select the type of experiment design to continue:"),
  HTML('
<style>
  .simpowa-home .container {
    max-width: 750px;
    margin: 40px auto;
    background: white;
    padding: 35px;
    border-radius: 12px;
    box-shadow: 0 6px 18px rgba(0,0,0,0.1);
  }

  .simpowa-home .subtitle {
    color: #555;
    margin-bottom: 20px;
  }

  .simpowa-home .cards {
    display: flex;
    gap: 20px;
    margin-top: 20px;
  }

  .simpowa-home .choice-card {
    flex: 1;
    padding: 20px;
    border: 2px solid #e2e2e2;
    border-radius: 12px;
    cursor: pointer;
    transition: 0.25s;
    position: relative;
  }

  .simpowa-home .choice-card.selected {
    border-color: #1a73e8;
    box-shadow: 0 4px 14px rgba(26,115,232,0.25);
  }

  .simpowa-home .choice-card.selected::after {
    content: "✔";
    position: absolute;
    bottom: 15px;
    right: 20px;
    font-size: 22px;
    color: #1a73e8;
  }

  .simpowa-home .choice-card h3 {
    margin-top: 0;
  }

  .simpowa-home .step-title {
    margin-top: 30px;
    font-size: 18px;
    font-weight: bold;
  }

  .simpowa-home .hidden {
    display: none;
  }
</style>

<div class="container">

  <h2>Select Simulation Duration</h2>
  <div class="subtitle">Choose whether you are planning a short-term or long-term intervention</div>

  <div class="cards" id="durationCards">
    <div class="choice-card" data-value="long">
      <h3>Long Term</h3>
      <p>Suitable for measuring long-term effect <b>(Over 3 Months)</b> of the intervention(s)</p>
    </div>

    <div class="choice-card" data-value="short">
      <h3>Short Term</h3>
      <p>For short-term effect <b>(24 - 48 Hours)</b> of the intervention(s)</p>
    </div>
  </div>

  <div id="step2" class="hidden">
    <div class="step-title">Select <span id="selectedDurationText"></span> Type</div>
    <div class="subtitle">
      Whether you are conducting a single or combined <strong id="contextLabel"></strong> intervention
    </div>

    <div class="cards" id="typeCards">
      <div class="choice-card" data-value="single">
        <h3>Single Intervention</h3>
        <p>Measuring the effect of only one intervention</p>
      </div>
      <div class="choice-card" data-value="combined">
        <h3>Combined Interventions</h3>
        <p>Measuring the combined effect of two interventions</p>
      </div>
    </div>
  </div>

  <div id="finalStep" class="hidden" style="margin-top: 40px; text-align: center; border-top: 1px solid #eee; padding-top: 30px;">
    <p style="color: #666; margin-bottom: 15px;">Selection complete!</p>
    <button id="continueBtn" style="
    background: #1a73e8;
    color: white;
    border: none;
    padding: 15px 40px;
    border-radius: 8px;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
    transition: background 0.2s;">
      Continue with Plan
    </button>
  </div>

</div>

<script>
  let selectedDuration = null;
  let selectedType = null;

  function makeSelectable(groupId, onSelect) {
    const group = document.getElementById(groupId);
    if (!group) return;
    group.querySelectorAll(".choice-card").forEach(card => {
      card.onclick = () => {
        group.querySelectorAll(".choice-card").forEach(c => c.classList.remove("selected"));
        card.classList.add("selected");
        if (onSelect) onSelect(card.dataset.value, card.querySelector("h3").innerText);
      };
    });
  }

  makeSelectable("durationCards", (value, label) => {
    selectedDuration = value;
    document.getElementById("selectedDurationText").innerText = label;
    document.getElementById("contextLabel").innerText = label.toLowerCase();
    document.getElementById("step2").classList.remove("hidden");
    checkFinalSelection();
  });

  makeSelectable("typeCards", (value) => {
    selectedType = value;
    checkFinalSelection();
  });

  function checkFinalSelection() {
    if (selectedDuration && selectedType) {
      const finalStep = document.getElementById("finalStep");
      const btn = document.getElementById("continueBtn");
      finalStep.classList.remove("hidden");

      if (selectedDuration === "long" && selectedType === "single") {
        btn.innerText = "Continue with Long Term Single";
      } else if (selectedDuration === "long" && selectedType === "combined") {
        btn.innerText = "Continue with Long Term Combined";
      } else if (selectedDuration === "short" && selectedType === "single") {
        btn.innerText = "Continue with Short Term Single";
      } else if (selectedDuration === "short" && selectedType === "combined") {
        btn.innerText = "Continue with Short Term Combined";
      }
    }
  }

  document.getElementById("continueBtn").onclick = () => {
    const path = selectedDuration + "-" + selectedType;
    Shiny.setInputValue("final_choice", {duration: selectedDuration, type: selectedType}, {priority: "event"});
    window.location.hash = "#!/" + path;
  };
</script>
  ')
)
