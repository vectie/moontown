///|
fn render_resident_card(resident : ResidentSim) -> @rabbita.Html {
  article(class="resident-card", [
    div(class="resident-head", [
      span(class="resident-avatar", resident_initials(resident.name)),
      div(class="resident-title", [h3(resident.name), p(resident.zone)]),
    ]),
    p(resident.venture),
    div(class="resident-chip-row", [
      span(class="resident-chip resident-chip-privacy", resident.privacy_scope),
      span(class="resident-chip resident-chip-action", "Recent action"),
    ]),
    p("Need: \{resident.need}"),
    p("Mood: \{resident.mood}"),
    p("Agent goal: \{resident.agent_goal}"),
    render_memory_strip("Memory", resident.memory),
    render_memory_strip("Reflection", resident.reflection),
    render_memory_strip("Plan", resident.plan),
    render_memory_strip("Latest handoff", resident.recent_action),
  ])
}

///|
fn resident_initials(name : String) -> String {
  match name {
    "Li / Edge AI OPC" => "LI"
    "Chen / Design Automation OPC" => "CH"
    "Ma / Policy Ops Visitor" => "MA"
    _ => "AI"
  }
}

///|
fn render_resident_agents(model : Model) -> @rabbita.Html {
  section(class="resident-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Resident Agents"),
      h2("Digital twins with memory, reflection, and plans"),
      p(
        class="summary",
        "Each resident now has visible need state, remembered context, reflection, privacy scope, and a next plan. This is the UI contract for real Memory Stream + Reflection + Planning integration.",
      ),
    ]),
    div(class="resident-summary-grid", [
      runtime_stat_chip(
        "Visible twins",
        resident_count(model),
        "runtime-running",
      ),
      runtime_stat_chip(
        "Private scopes",
        resident_private_scope_count(model),
        "runtime-review",
      ),
      runtime_stat_chip(
        "Review queued",
        resident_review_queue_count(model),
        "runtime-persisting",
      ),
      runtime_stat_chip(
        "Projection mode",
        if model.state_source == StateSourceKind::SnapshotFile {
          1
        } else {
          0
        },
        "runtime-imported",
      ),
    ]),
    div(class="contract-list resident-contract-list", [
      p(
        "Resident memory stays durable in MoonBook; Moontown renders only projection-safe summaries and counters.",
      ),
      p(
        "Projection scope in this slice: public-safe, shared town, and operator summary.",
      ),
      p(
        "Recent actions show MoonClaw handoff results, not direct durable memory writes.",
      ),
    ]),
    div(
      class="resident-grid",
      resident_sims(model).map(resident => render_resident_card(resident)),
    ),
  ])
}
