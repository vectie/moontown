///|
fn render_resident_card(resident : ResidentSim) -> @rabbita.Html {
  article(class="resident-card", [
    div(class="resident-head", [
      render_resident_avatar(resident),
      div(class="resident-title", [h3(resident.name), p(resident.zone)]),
    ]),
    p(resident.venture),
    div(class="resident-chip-row", [
      span(class="resident-chip resident-chip-privacy", resident.privacy_scope),
      span(class="resident-chip resident-chip-action", "Recent action"),
    ]),
    div(class="resident-state-grid", [
      render_resident_state("Need", resident.need),
      render_resident_state("Mood", resident.mood),
      render_resident_state("Goal", resident.agent_goal),
    ]),
    render_memory_strip("Current signal", resident.recent_action),
  ])
}

///|
fn render_resident_avatar(resident : ResidentSim) -> @rabbita.Html {
  img(
    class="resident-avatar",
    src="tilemap/actors/roster/\{resident_avatar_slug(resident.name)}.png",
    alt="\{resident.name} resident avatar",
    loading="lazy",
  )
}

///|
fn resident_avatar_slug(name : String) -> String {
  match name {
    "Li / Edge AI OPC" => "resident_0"
    "Chen / Design Automation OPC" => "resident_1"
    "Ma / Policy Ops Visitor" => "resident_2"
    _ => "resident_0"
  }
}

///|
fn render_resident_state(label : String, value : String) -> @rabbita.Html {
  div(class="resident-state", [
    span(class="resident-state-label", label),
    p(value),
  ])
}

///|
fn render_resident_agents(model : Model) -> @rabbita.Html {
  section(class="resident-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Resident Agents"),
      h2("Resident Agents"),
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
    div(
      class="resident-grid",
      resident_sims(model).map(resident => render_resident_card(resident)),
    ),
  ])
}
