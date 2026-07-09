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
    "task-", "packet-", "run-", "proposal-", "Live spine", "Snapshot bridge", "Switch Source",
    "State sources", "endpoint", "payload", "dispatch tick", "Inspector Inject Budget",
    "Inspector Relieve Queue", "Inspector Stability Drill", ">Pause<", ">Step<",
    ">Inject Budget<", ">Relieve Queue<", ">Stability Drill<", "Town shell plus live civic systems",
    "Digital twins with memory", "Policy, contest, social, and offline workflows as playable services",
    "Weak ties, talent graph, and reception-ready evidence", ">Title<", ">Target book<",
    ">Check frequency<", ">Quality threshold<", ">Book title<", ">Book id<", ">Websites<",
    ">Purpose<", ">Special analysis rules<", "Advanced Operations", "Town work health",
    "Available:", "Town work is stable enough for normal watch", "Review work is waiting. Resolve review items",
    "Legend", "City Hall is the mayor runtime", "Moonbook houses hold keeper-owned domain planning",
    "Worker avatars now move between yard, hall, books", "Open the Wenyu viewport when you need the full map",
    "Canonical Wenyu Viewport", "Open the real Wenyu Valley tile map", "second scaled-down town map",
    "Executions:", "Executions ", "deeper runtime tools", "Open the advanced viewport",
    "Open Advanced Viewport", "Advanced tools open separately", "runtime intervention",
    "Progress And Requests", "Mayor command center", "Live status ", "Town loop active",
    "Due checks ", "Requests ", "Decision mix", "Watch Portfolio", "Long-horizon topics",
    "Standing Watch Portfolio", "operator-console", "operator-stat", "operator-watch-column",
    "watch-portfolio", "watch-timeline", "Operating Brief", "Current focus", "metric-grid",
    "professional-brief", "operator-focus", "professional-status-strip", "phone-message-panel",
    "phone-topbar", "message-bubble", "No standing watcher connected", "through the daemon",
    "deeper town tools", "Preview live", "Preview paused", "Town check waiting",
    "Professional view", "Town data connected", "Town Overview", "professional-overview",
    "viewport-portal", "town-main", "scene-column", "town-header", "title-block",
    "Professional town workspace", "Focused town surfaces",
    "dashboard-overview-card", "dashboard-overview-grid", "request-idle-panel",
    "Choose the next safe request",
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
  assert_true(html.contains("Signal"))
  assert_true(html.contains("Next opening"))
  assert_true(html.contains("operator-masthead"))
  assert_true(html.contains("Wenyu Valley workspace"))
  assert_true(html.contains("Town Launchpad"))
  assert_true(html.contains("Current town pulse"))
  assert_true(html.contains("Open Wenyu Map"))
  assert_true(html.contains("Open Wenyu Valley workspace"))
  assert_true(html.contains("Save Watch"))
  assert_true(html.contains("Queue PDF Watch Book"))
  assert_true(html.contains("Request Desk"))
  assert_true(html.contains("Start the next safe job"))
  assert_true(html.contains("Attention Workbench"))
  assert_true(html.contains("Activity Ledger"))
  assert_true(html.contains("Town Areas"))
  assert_true(html.contains("Open detail only when needed"))
  assert_true(html.contains("Districts"))
  assert_true(html.contains("Residents"))
  assert_true(html.contains("Quests"))
  assert_true(html.contains("Social capital"))
  assert_true(html.contains("Keep watching a topic"))
  assert_true(html.contains("Create a PDF evidence watch"))
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
