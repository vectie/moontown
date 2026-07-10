///|
priv struct CivicModuleCardSpec {
  zone : String
  title : String
  copy : String
  worker_label : String
  queue_pressure : Int
  health : Int
  next_action : String
  signal_class : String
  signal : String
  details : Array[@rabbita.Html]
  card_class : String
}

///|
fn civic_module_card_class(extra? : String = "") -> String {
  let base = "civic-module-card civic-module-card-featured"
  if extra == "" {
    base
  } else {
    "\{base} \{extra}"
  }
}

///|
fn civic_module_card_spec(
  zone : String,
  title : String,
  copy : String,
  worker_label : String,
  queue_pressure : Int,
  health : Int,
  next_action : String,
  signal_class : String,
  signal : String,
  details? : Array[@rabbita.Html] = [],
  card_class? : String = civic_module_card_class(),
) -> CivicModuleCardSpec {
  {
    zone,
    title,
    copy,
    worker_label,
    queue_pressure,
    health,
    next_action,
    signal_class,
    signal,
    details,
    card_class,
  }
}

///|
fn render_civic_module_card_shell(spec : CivicModuleCardSpec) -> @rabbita.Html {
  let content : Array[@rabbita.Html] = [
    p(class="scene-node-key", spec.zone),
    h3(spec.title),
    p(spec.copy),
    render_module_metric_grid(
      spec.worker_label,
      spec.queue_pressure,
      spec.health,
    ),
  ]
  if spec.details.length() > 0 {
    content.push(render_module_detail_grid(spec.details))
  }
  content.push(render_module_next_action(spec.next_action))
  content.push(render_module_signal(spec.signal_class, spec.signal))
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
