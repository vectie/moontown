///|
fn render_metric_card(metric : VitalityMetric) -> @rabbita.Html {
  let fill_style = ["width: \{metric.fill}%"]
  article(class="metric-card", [
    div(class="metric-head", [
      p(class="metric-label", metric.label),
      p(class="metric-value", metric.value),
    ]),
    div(class="metric-track", [
      div(class="metric-fill \{metric.tone}", style=fill_style, no_children()),
    ]),
    p(class="metric-detail", metric.detail),
  ])
}

///|
fn vitality_metrics(model : Model) -> Array[VitalityMetric] {
  let joins = resident_joins_today(model)
  let quests = active_quest_count(model)
  let events = events_today(model)
  let retention = retention_signal(model)
  [
    {
      label: "Resident joins",
      value: joins.to_string(),
      fill: clamp_metric(joins * 12),
      tone: "tone-budget",
      detail: "New founder or resident arrivals recorded in the current tick window.",
    },
    {
      label: "Active quests",
      value: quests.to_string(),
      fill: clamp_metric(quests * 11),
      tone: "tone-energy",
      detail: "Civic service and build lanes currently assigned or running.",
    },
    {
      label: "Events today",
      value: events.to_string(),
      fill: clamp_metric(events * 18),
      tone: "tone-pressure",
      detail: "Meetups, reviews, and district moments visible in the square.",
    },
    {
      label: "Return signal",
      value: "\{retention}%",
      fill: retention,
      tone: "tone-stability",
      detail: "Retention and repeat participation trend from the current town pulse.",
    },
  ]
}

///|
fn render_vitality_metric_grid(model : Model) -> Array[@rabbita.Html] {
  let cards : Array[@rabbita.Html] = []
  for metric in vitality_metrics(model) {
    cards.push(render_metric_card(metric))
  }
  cards
}
