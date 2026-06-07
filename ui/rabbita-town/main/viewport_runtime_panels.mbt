///|
fn render_bridge_contract(model : Model) -> @rabbita.Html {
  section(class="bridge-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "24/7 Runtime Contract"),
      h2("From playable prototype to durable daemon town"),
      p(
        class="summary",
        "The UI now exposes the state objects the backend must keep alive: residents, memories, quests, matches, workers, health, and physical bridge events.",
      ),
    ]),
    div(class="bridge-grid", [
      runtime_stat_chip(
        "Daemon tick",
        daemon_tick_count(model),
        "runtime-running",
      ),
      runtime_stat_chip("Residents", resident_count(model), "runtime-packets"),
      runtime_stat_chip(
        "Memory streams",
        resident_sims(model).length(),
        "runtime-imported",
      ),
      runtime_stat_chip(
        "Open quests",
        civic_quests(model).length(),
        "runtime-persisting",
      ),
      runtime_stat_chip(
        "Robot calls",
        robot_service_count(model),
        "runtime-review",
      ),
    ]),
    div(class="contract-list", [
      p(
        "Persisted town state: `.moontown/town.json` should publish the same objects shown here.",
      ),
      p(
        "MoonBook state: each civic module owns durable wiki/memory pages for its domain.",
      ),
      p(
        "MoonClaw state: worker runs emit result packets and memory candidates, never raw global memory writes.",
      ),
      p(
        "Browser bridge: Rabbita should consume a generated `town-runtime.json` or local endpoint instead of synthetic state.",
      ),
    ]),
  ])
}

///|
fn execution_stage_cards(
  executions : Array[@core.TaskExecutionRecord],
) -> Array[@rabbita.Html] {
  let summary = execution_count_summary(executions)
  [
    runtime_stat_chip(
      "Packets",
      summary.packet_ready,
      "runtime-packets",
    ),
    runtime_stat_chip(
      "Imported",
      summary.proposal_imported,
      "runtime-imported",
    ),
    runtime_stat_chip(
      "Running",
      summary.active_run_flow(),
      "runtime-running",
    ),
    runtime_stat_chip(
      "Persisting",
      summary.awaiting_persistence,
      "runtime-persisting",
    ),
    runtime_stat_chip(
      "Review",
      summary.review_queued,
      "runtime-review",
    ),
    runtime_stat_chip(
      "Done",
      summary.completed,
      "runtime-completed",
    ),
    runtime_stat_chip("Issues", summary.issue_count(), "runtime-blocked"),
  ]
}

///|
priv struct WenyuViewportPortalView {
  latest_decision : String
  latest_sources : String
  next_check : String
  execution_count : Int
}

///|
fn wenyu_viewport_portal_view(
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
) -> WenyuViewportPortalView {
  let latest = latest_watcher_metric_view(latest_watcher_record(model))
  let executions_summary = execution_count_summary(executions)
  let next_check = standing_goal_next_check_view(model)
  {
    latest_decision: latest.decision,
    latest_sources: latest.sources,
    next_check: next_check.portal_label,
    execution_count: executions_summary.total,
  }
}

///|
fn render_wenyu_viewport_portal(
  model : Model,
  scene : @ui.SceneRenderModel,
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let portal = wenyu_viewport_portal_view(model, executions)
  section(class="viewport-portal-card", [
    div(class="viewport-portal-copy", [
      p(class="eyebrow", "Canonical Wenyu Viewport"),
      h2("Open the real Wenyu Valley tile map"),
      p(
        class="summary",
        "The dashboard no longer renders a second scaled-down town map. Click through to the standalone viewport so the operator view and the Wenyu Valley map stay consistent.",
      ),
      div(class="viewport-portal-stats", [
        status_chip("Scene: \{scene.title}", "chip-book"),
        status_chip("Latest: \{portal.latest_decision}", "chip-neutral"),
        status_chip("New sources: \{portal.latest_sources}", "chip-neutral"),
        status_chip("Next check: \{portal.next_check}", "chip-clock"),
        status_chip("Executions: \{portal.execution_count}", "chip-neutral"),
      ]),
    ]),
    a(
      href="./viewport.html?assets=generated&v=wenyu",
      class="viewport-portal-button",
      "Open Wenyu Viewport",
    ),
  ])
}
