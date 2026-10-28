///|
priv struct CivicModuleCardSpec {
  title : String
  copy : String
  next_action : String
  signal : String
  details : Array[@rabbita.Html]
  diagnostics : Array[@rabbita.Html]
  card_class : String
}

///|
fn civic_module_card_class(extra~ : String = "") -> String {
  let base = "civic-module-card civic-module-card-featured"
  if extra == "" {
    base
  } else {
    "\{base} \{extra}"
  }
}

///|
fn render_civic_module_card_shell(spec : CivicModuleCardSpec) -> @rabbita.Html {
  let content : Array[@rabbita.Html] = [
    h3(spec.title),
    render_module_signal("module-signal-neutral", spec.signal),
    p(spec.copy),
  ]
  if !spec.details.is_empty() {
    content.push(render_module_detail_grid(spec.details))
  }
  content.push(p(class="module-next-action", spec.next_action))
  if !spec.diagnostics.is_empty() {
    content.push(render_advanced_details("业务记录", spec.diagnostics))
  }
  article(class=spec.card_class, [
    render_civic_module_card_visual(spec.title),
    div(class="civic-module-card-content", content),
  ])
}

///|
fn render_civic_module_card_visual(title : String) -> @rabbita.Html {
  img(
    class="civic-module-card-visual",
    src="tilemap/districts/\{civic_module_card_visual_slug(title)}.png",
    alt="\{title} district building",
    loading="lazy",
  )
}

///|
fn civic_module_card_visual_slug(title : String) -> String {
  match title {
    "Town Shell" => "town_shell"
    "Vitality Dashboard" => "vitality_dashboard"
    "Resident Twins" => "resident_twins"
    "Policy Hall" => "policy_hall"
    "Contest Express" => "contest_express"
    "Social Square" => "social_square"
    "Talent Avenue" => "talent_avenue"
    "AI Garden" => "ai_garden"
    "Physical Bridge" => "physical_bridge"
    _ => "town_shell"
  }
}
