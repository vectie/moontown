///|
fn dashboard_test_dispatch() -> Dispatch[Msg] {
  Emit(fn(_msg) { @rabbita.none })
}

///|
fn render_default_dashboard_test_html(model : Model) -> String {
  @rabbita.render_to_string(
    @rabbita.static_cell(
      render_dashboard_page(
        dashboard_test_dispatch(),
        model,
        render_scene_context(model),
      ),
    ),
  )
}

///|
fn default_dashboard_forbidden_copy() -> Array[String] {
  [
    ".json", "daemon.json", "standing-goals.json", "book-template-requests.json",
    "task-", "packet-", "run-", "proposal-", "Live spine", "Snapshot bridge",
    "Switch Source", "State sources", "endpoint", "payload", "dispatch tick",
    "Inspector Inject Budget", "Inspector Relieve Queue", "Inspector Stability Drill",
    ">Pause<", ">Step<", ">Inject Budget<", ">Relieve Queue<", ">Stability Drill<",
    "Town shell plus live civic systems", "Digital twins with memory",
    "Policy, contest, social, and offline workflows as playable services",
    "Weak ties, talent graph, and reception-ready evidence",
    ">Title<", ">Target book<", ">Check frequency<", ">Quality threshold<",
    ">Book title<", ">Book id<", ">Websites<", ">Purpose<",
    ">Special analysis rules<",
    "Advanced Operations", "Town work health", "Available:",
    "Town work is stable enough for normal watch",
    "Review work is waiting. Resolve review items",
    "Legend", "City Hall is the mayor runtime",
    "Moonbook houses hold keeper-owned domain planning",
    "Worker avatars now move between yard, hall, books",
    "Open the Wenyu viewport when you need the full map",
    "Canonical Wenyu Viewport", "Open the real Wenyu Valley tile map",
    "second scaled-down town map", "Executions:", "Executions ",
    "deeper runtime tools", "Open the advanced viewport",
    "Open Advanced Viewport", "Advanced tools open separately",
    "runtime intervention",
    "phone-message-panel", "phone-topbar", "message-bubble",
    "No standing watcher connected", "through the daemon",
    "deeper town tools",
    "Preview live", "Preview paused", "Town check waiting",
    "Professional view", "Town data connected",
  ]
}

///|
test "default dashboard hides developer and rare runtime controls" {
  let html = render_default_dashboard_test_html(init_model())
  for copy in default_dashboard_forbidden_copy() {
    if html.contains(copy) {
      fail("default dashboard contains forbidden copy: \{copy}")
    }
  }
}

///|
test "default dashboard keeps professional operating actions visible" {
  let html = render_default_dashboard_test_html(init_model())
  assert_true(html.contains("Professional workspace"))
  assert_true(html.contains("No active watch"))
  assert_true(html.contains("Current town pulse"))
  assert_true(html.contains("Open Wenyu Map"))
  assert_true(html.contains("Open Wenyu Valley workspace"))
  assert_true(html.contains("Save Watch"))
  assert_true(html.contains("Queue PDF Watch Book"))
  assert_true(html.contains("Operating Brief"))
  assert_true(html.contains("Current focus"))
  assert_true(html.contains("Focused town surfaces"))
  assert_true(html.contains("Districts"))
  assert_true(html.contains("Residents"))
  assert_true(html.contains("Quests"))
  assert_true(html.contains("Social capital"))
  assert_true(html.contains("Choose the next safe request"))
}

///|
test "dashboard ecosystem sections render only the selected detail surface" {
  let districts = render_default_dashboard_test_html({
    ..init_model(),
    dashboard_section: DashboardSection::DistrictSystems,
  })
  assert_true(districts.contains("Town shell plus live civic systems"))
  assert_true(!districts.contains("Digital twins with memory"))
  let residents = render_default_dashboard_test_html({
    ..init_model(),
    dashboard_section: DashboardSection::ResidentAgentsSection,
  })
  assert_true(residents.contains("Digital twins with memory"))
  assert_true(!residents.contains("Town shell plus live civic systems"))
}

///|
test "dashboard request launcher renders one selected composer at a time" {
  let watch = render_default_dashboard_test_html({
    ..init_model(),
    request_composer: RequestComposerFocus::StandingWatchComposer,
  })
  assert_true(watch.contains(">Title<"))
  assert_true(watch.contains(">Target book<"))
  assert_true(!watch.contains(">Book title<"))
  assert_true(!watch.contains(">Websites<"))
  let book = render_default_dashboard_test_html({
    ..init_model(),
    request_composer: RequestComposerFocus::EvidenceBookComposer,
  })
  assert_true(book.contains(">Book title<"))
  assert_true(book.contains(">Websites<"))
  assert_true(!book.contains(">Target book<"))
  assert_true(!book.contains(">Quality threshold<"))
}
