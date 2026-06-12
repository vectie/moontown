///|
fn civic_quests(model : Model) -> Array[CivicQuestSim] {
  let policy_context = policy_hall_runtime_context(model)
  let policy_execution = policy_context.execution
  let policy_task = policy_context.task
  let ai_garden_context = ai_garden_runtime_context(model)
  let ai_garden_task = ai_garden_context.task
  let ai_garden_execution = ai_garden_context.execution
  [
    {
      title: "Rental subsidy walkthrough",
      area: "Policy Hall",
      stage: policy_hall_quest_stage(model, policy_execution),
      reward: "80 Valley XP + application packet",
      status: policy_hall_signal(model, policy_execution),
      status_class: policy_hall_signal_class(model, policy_execution),
      detail: "Confidence \{policy_hall_confidence(model, policy_execution)}% · \{policy_hall_checklist_label(model, policy_execution)} · \{policy_hall_evidence_label(model, policy_execution)}",
      next_action: policy_hall_next_action(model, policy_task, policy_execution),
    },
    {
      title: "OPC roadshow preparation",
      area: "Contest Express",
      stage: if model.tick % 5 < 3 {
        "Mock judge scoring"
      } else {
        "Deck gap review"
      },
      reward: "Priority roadshow slot",
      status_class: "module-signal-book",
      status: "Nurturing",
      detail: "Checklist shaping in contest workspace with reviewable deck gaps.",
      next_action: "Keep the next mock judge round and reminder schedule visible.",
    },
    {
      title: "Cafe collaboration intro",
      area: "Social Square",
      stage: "Agent-mediated weak-tie match",
      reward: "Trial collaboration room",
      status_class: "module-signal-live",
      status: "Matching",
      detail: "Reasoned introduction stays lightweight until both sides accept.",
      next_action: "Project the latest follow-up into the resident-safe summary.",
    },
    {
      title: "Resident AI adoption sprint",
      area: "AI Garden",
      stage: ai_garden_stage(model, ai_garden_execution),
      reward: "Scenario template + before/after proof",
      status: ai_garden_signal(model, ai_garden_execution),
      status_class: ai_garden_signal_class(model, ai_garden_execution),
      detail: "Scenario lanes \{ai_garden_scenario_count(model)} · \{ai_garden_tool_trial_label(model, ai_garden_execution)} · \{ai_garden_comparison_label(model, ai_garden_execution)}",
      next_action: ai_garden_next_action(
        model, ai_garden_task, ai_garden_execution,
      ),
    },
    {
      title: "Physical bridge sync",
      area: "Physical Bridge",
      stage: if model.tick % 3 == 0 {
        "Robot confirmation"
      } else {
        "Room and telemetry sync"
      },
      reward: "Room hold + district signal",
      status_class: "module-signal-live",
      status: "Bridge live",
      detail: "Venue, robot, and telemetry handoffs stay visible in town view.",
      next_action: "Confirm the next offline sync before the district route changes.",
    },
  ]
}

///|
fn render_quest_card(quest : CivicQuestSim) -> @rabbita.Html {
  article(class="quest-card", [
    p(class="scene-node-key", quest.area),
    h3(quest.title),
    p("Stage: \{quest.stage}"),
    p("Reward: \{quest.reward}"),
    p(class="quest-detail", quest.detail),
    p(class="quest-next", "Next: \{quest.next_action}"),
    span(class="module-signal \{quest.status_class}", quest.status),
  ])
}

///|
fn render_civic_quests(model : Model) -> @rabbita.Html {
  section(class="quest-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Civic Quests"),
      h2("Policy, contest, social, and offline workflows as playable services"),
      p(
        class="summary",
        "This replaces static service text with quest-shaped state that agents can advance and the mayor can supervise.",
      ),
    ]),
    div(
      class="quest-grid",
      civic_quests(model).map(quest => render_quest_card(quest)),
    ),
  ])
}
