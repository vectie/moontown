///|
fn render_match_card(match_item : SocialMatchSim) -> @rabbita.Html {
  article(class="match-card", [
    h3("\{match_item.left} x \{match_item.right}"),
    p(match_item.reason),
    p("Next: \{match_item.next_step}"),
    span(class="module-signal", "Confidence \{match_item.confidence}%"),
  ])
}

///|
fn render_talent_card(signal : TalentSignalSim) -> @rabbita.Html {
  article(class="talent-card", [
    div(class="talent-card-head", [
      h3(signal.name),
      span(class="module-signal talent-card-signal", signal.evidence_status),
    ]),
    p(signal.domain),
    p("Project: \{signal.project}"),
    p("Skills: \{signal.skills}"),
    render_memory_strip(
      "Recent win",
      signal.recent_achievement,
      strip_class="memory-strip talent-card-strip",
    ),
    render_memory_strip(
      "Reception note",
      signal.reception_note,
      strip_class="memory-strip talent-card-strip",
    ),
    render_metric_track(signal.activity),
    p("Activity brightness: \{signal.activity}%"),
  ])
}

///|
fn render_route_stop_card(stop : TalentRouteStopSim) -> @rabbita.Html {
  article(class="route-stop-card", [
    div(class="route-stop-head", [
      span(class="route-stop-order", stop.order.to_string()),
      div(class="route-stop-title", [h3(stop.stop_title), p(stop.signal_name)]),
      span(class="module-signal talent-card-signal", stop.evidence_status),
    ]),
    p(stop.talking_point),
    render_memory_strip(
      "Operator note",
      stop.operator_note,
      strip_class="memory-strip route-stop-strip",
    ),
    render_metric_track(stop.readiness),
    p("Route readiness: \{stop.readiness}%"),
  ])
}

///|
fn render_social_talent(model : Model) -> @rabbita.Html {
  let route_stops = talent_route_stops(model)
  section(class="social-talent-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Social Capital"),
      h2("Weak ties, talent graph, and reception-ready evidence"),
      p(
        class="summary",
        "The town should prove community warmth through visible matches, skill density, and operator-friendly talent projections.",
      ),
    ]),
    div(class="social-talent-grid", [
      div(class="subpanel", [
        h3("Agent Matches"),
        div(
          class="feed-list",
          social_matches().map(item => render_match_card(item)),
        ),
      ]),
      div(class="subpanel", [
        h3("Talent Star Avenue"),
        div(
          class="feed-list",
          talent_signals(model).map(signal => render_talent_card(signal)),
        ),
      ]),
      div(class="subpanel", [
        h3("Reception Route"),
        p(
          "Guide visitors through a proof-first route, keep operator notes projection-safe, and close with a clear next action.",
        ),
        div(
          class="route-stop-list",
          route_stops.map(stop => render_route_stop_card(stop)),
        ),
      ]),
    ]),
  ])
}
