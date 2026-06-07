fn module_interior_furniture(civic : WenyuTownModule) -> Array[@rabbita.Html] {
  match civic.interior_kind {
    "mayor" =>
      [
        div(class="furniture furniture-map-table", [span("Runtime Map")]),
        div(class="furniture furniture-radio", [span("Mayor Radio")]),
        div(class="furniture furniture-policy-board", [span("Patrol Board")]),
        div(class="furniture furniture-archive", [span("Town Ledger")]),
      ]
    "policy" =>
      [
        div(class="furniture furniture-policy-board", [span("Policy Wall")]),
        div(class="furniture furniture-desk", [span("Eligibility Desk")]),
        div(class="furniture furniture-archive", [span("Source Shelf")]),
        div(class="furniture furniture-review-table", [span("Checklist Table")]),
      ]
    "contest" =>
      [
        div(class="furniture furniture-stage", [span("Mock Stage")]),
        div(class="furniture furniture-scoreboard", [span("Judge Board")]),
        div(class="furniture furniture-desk", [span("Deck Clinic")]),
        div(class="furniture furniture-log-wall", [span("Countdown Wall")]),
      ]
    "social" =>
      [
        div(class="furniture furniture-cafe-table", [span("Cafe Table")]),
        div(class="furniture furniture-signal-post", [span("Match Board")]),
        div(class="furniture furniture-bench", [span("Intro Bench")]),
        div(class="furniture furniture-log-wall", [span("Follow Up")]),
      ]
    "talent" =>
      [
        div(class="furniture furniture-gallery", [span("Talent Wall")]),
        div(class="furniture furniture-scoreboard", [span("Skill Heatmap")]),
        div(class="furniture furniture-desk", [span("Tour Desk")]),
        div(class="furniture furniture-archive", [span("Evidence Shelf")]),
      ]
    "vitality" =>
      [
        div(class="furniture furniture-scoreboard", [span("Pulse Board")]),
        div(class="furniture furniture-map-table", [span("Heat Map")]),
        div(class="furniture furniture-radio", [span("Service Radio")]),
        div(class="furniture furniture-log-wall", [span("Metric Ledger")]),
      ]
    "garden" =>
      [
        div(class="furniture furniture-garden-bed", [span("Tool Trial")]),
        div(class="furniture furniture-bench", [span("Tutorial Bench")]),
        div(class="furniture furniture-signal-post", [span("Daily Tip")]),
        div(class="furniture furniture-review-table", [span("Before / After")]),
      ]
    "bridge" =>
      [
        div(class="furniture furniture-robot-bay", [span("Robot Bay")]),
        div(class="furniture furniture-radio", [span("Venue Link")]),
        div(class="furniture furniture-map-table", [span("Offline Map")]),
        div(class="furniture furniture-review-table", [span("Confirm Gate")]),
      ]
    "research" =>
      [
        div(class="furniture furniture-desk", [span("Research Desk")]),
        div(class="furniture furniture-bookshelf", [span("Source Wall")]),
        div(class="furniture furniture-map-table", [span("Synthesis Map")]),
        div(class="furniture furniture-review-table", [span("Review Gate")]),
      ]
    "market" =>
      [
        div(class="furniture furniture-market-stall", [span("Point Stall")]),
        div(class="furniture furniture-scoreboard", [span("Rewards")]),
        div(class="furniture furniture-desk", [span("Redeem Desk")]),
        div(class="furniture furniture-log-wall", [span("Benefit Ledger")]),
      ]
    "broadcast" =>
      [
        div(class="furniture furniture-radio", [span("Story Radar")]),
        div(class="furniture furniture-scoreboard", [span("Signal Board")]),
        div(class="furniture furniture-review-table", [span("Review Desk")]),
        div(class="furniture furniture-log-wall", [span("Broadcast Wall")]),
      ]
    _ =>
      [
        div(class="furniture furniture-desk", [span("Module Desk")]),
        div(class="furniture furniture-signal-post", [span("Signal Post")]),
        div(class="furniture furniture-review-table", [span("Review Table")]),
      ]
  }
}
