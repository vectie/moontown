///|
fn render_match_card(match_item : SocialMatchSim) -> @rabbita.Html {
  article(class="match-card", [
    h3("\{match_item.left} x \{match_item.right}"),
    span(
      class="module-signal module-signal-neutral",
      "示例 · 未发送邀请",
    ),
    p(match_item.reason),
    p(match_item.next_step),
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
    p("项目：\{signal.project}"),
    p("技能方向：\{signal.skills}"),
    render_advanced_details("示例资料", [
      p(signal.recent_achievement),
      p(signal.reception_note),
    ]),
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
    render_advanced_details("示例接待备注", [p(stop.operator_note)]),
  ])
}

///|
fn render_social_talent(model : Model) -> @rabbita.Html {
  let route_stops = talent_route_stops(model)
  section(class="social-talent-panel", [
    div(class="runtime-copy", [
      h2("发现与协作"),
      p(
        "以下为人物、合作方向和接待路线示例，不代表真实匹配、认证或邀约。",
      ),
    ]),
    div(class="social-talent-grid", [
      div(class="subpanel", [
        h3("合作示例"),
        div(
          class="feed-list",
          social_matches().map(item => render_match_card(item)),
        ),
      ]),
      div(class="subpanel", [
        h3("人才示例"),
        div(
          class="feed-list",
          talent_signals(model).map(signal => render_talent_card(signal)),
        ),
      ]),
      div(class="subpanel", [
        h3("接待路线示例"),
        div(
          class="route-stop-list",
          route_stops.map(stop => render_route_stop_card(stop)),
        ),
      ]),
    ]),
  ])
}
