///|
fn render_resident_card(resident : ResidentSim) -> @rabbita.Html {
  article(class="resident-card", [
    div(class="resident-head", [
      render_resident_avatar(resident),
      div(class="resident-title", [h3(resident.name), p(resident.zone)]),
    ]),
    p(resident.venture),
    div(class="resident-chip-row", [
      span(
        class="resident-chip resident-chip-privacy",
        "示例人物 · 非真实账户",
      ),
    ]),
    div(class="resident-state-grid", [
      render_resident_state("Need", resident.need),
      render_resident_state("Mood", resident.mood),
      render_resident_state("Goal", resident.agent_goal),
    ]),
    render_advanced_details("示例人物设定", [
      p(resident.recent_action),
      p(resident.plan),
    ]),
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
      h2("居民示例"),
      p(
        "展示三种典型需求，不代表真实账户、私人记忆或已经发生的行动。",
      ),
    ]),
    div(class="resident-summary-grid", [
      runtime_stat_chip(
        "示例人物",
        resident_sims(model).length(),
        "runtime-review",
      ),
    ]),
    div(
      class="resident-grid",
      resident_sims(model).map(resident => render_resident_card(resident)),
    ),
  ])
}
