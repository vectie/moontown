///|
priv enum RuntimeAvailability {
  DemoRuntime
  ConnectingRuntime
  OfflineRuntime
  LiveRuntime
}

///|
fn runtime_availability(model : Model) -> RuntimeAvailability {
  if model.state_source == StateSourceKind::DemoSimulation {
    DemoRuntime
  } else if model_projection_snapshot_ready(model) {
    LiveRuntime
  } else if model.snapshot_version == 0 {
    ConnectingRuntime
  } else {
    OfflineRuntime
  }
}

///|
fn runtime_is_unavailable(model : Model) -> Bool {
  match runtime_availability(model) {
    ConnectingRuntime | OfflineRuntime => true
    DemoRuntime | LiveRuntime => false
  }
}

///|
fn town_worker_chip_label(model : Model, online : Int) -> String {
  match runtime_availability(model) {
    DemoRuntime => "Demo \{online}"
    ConnectingRuntime => "Connecting"
    OfflineRuntime => "Town offline"
    LiveRuntime => "Workers \{online}"
  }
}

///|
fn render_town_runtime_notice(model : Model) -> @rabbita.Html {
  match runtime_availability(model) {
    ConnectingRuntime =>
      div(class="town-runtime-notice town-runtime-connecting", [
        div(class="town-runtime-notice-copy", [
          p(class="eyebrow", "Live town data"),
          h2("Connecting to the town runtime"),
        ]),
        p("MoonTown is checking the local town projection."),
        a(
          href="./viewport.html?mode=output&v=wenyu",
          class="town-runtime-notice-action",
          "Open status",
        ),
      ])
    OfflineRuntime =>
      div(class="town-runtime-notice town-runtime-offline", [
        div(class="town-runtime-notice-copy", [
          p(class="eyebrow", "Live town data"),
          h2("Town runtime is not connected"),
        ]),
        p(
          "Requests remain available, but operating signals stay empty until a town snapshot is published.",
        ),
        a(
          href="./viewport.html?mode=output&v=wenyu",
          class="town-runtime-notice-action",
          "Open status",
        ),
      ])
    DemoRuntime | LiveRuntime =>
      div(class="town-runtime-notice-empty", no_children())
  }
}

///|
fn render_town_area_unavailable(target : DashboardSection) -> @rabbita.Html {
  section(class="town-area-unavailable", [
    div(class="town-area-unavailable-copy", [
      p(class="eyebrow", "Live town data"),
      h2("\{dashboard_section_label(target)} are not connected"),
      p(
        "This area will show real town records after the runtime publishes a live snapshot.",
      ),
    ]),
    a(
      href="./viewport.html?mode=output&v=wenyu",
      class="town-area-unavailable-action",
      "Open runtime status",
    ),
  ])
}
