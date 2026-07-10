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
    "Professional town workspace", "Focused town surfaces", "dashboard-overview-card",
    "dashboard-overview-grid", "request-idle-panel", "Choose the next safe request",
    "Activity Ledger", "activity-ledger-panel", "feed-panel", "feed-item", "Closed by default",
    "Default closed", "town-area-closed-panel", "town-launchpad-grid", "town-launchpad-card",
    "launchpad-card-", "attention-workbench-grid", "attention-next-card", "attention-signal-card",
    "Open detail only when needed", "dashboard-section-kicker", "Live civic modules",
    "Projection-safe twins", "Service workflows", "Matches and reception", "Start the next safe job",
    "Create a standing watch or queue a PDF evidence book only when there is concrete work to add.",
    "request-shortcut-grid", "request-shortcut-card", "request-shortcut-action",
    "Keep watching a topic", "Create a PDF evidence watch", "Track useful evidence changes in an existing MoonBook.",
    "Use when a new durable book needs approved PDF sources.", "town-launchpad-map",
    "town-launchpad-map-copy", "town-launchpad-map-stats", "town-launchpad-map-button",
    "Open Wenyu Valley workspace", "Inspect districts, residents, standing watches, and active work in place.",
    "Latest:", "New sources:", "Next check:", "Active work:", "operator-masthead",
    "operator-masthead-title", "operator-masthead-alerts", "operator-masthead-brand",
    "Wenyu Valley workspace", "Civic watches, resident agents, district services, and review-ready feedback loops.",
    "town-status-bar", "town-status-title", "town-status-alerts", "Town Launchpad",
    "Current town pulse", "Health, watches, review needs, book queue, and map entry stay close to the request path.",
    "Attention Workbench", "attention-review-strip", "attention-review-copy", "attention-strip-chips",
    "attention-strip-chip", "alert-strip", "Request intake", "Save Watch", "Queue PDF Watch Book",
    "Civic surfaces", "Town health", "Standing watches", "Book queue", "Social capital",
    "Review queued work", "No active alerts", "Workers online:", "Open Wenyu Map",
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
  assert_true(html.contains("Next opening"))
  assert_true(html.contains("Moontown"))
  assert_true(html.contains("Wenyu Valley / AI Innovation Town"))
  assert_true(html.contains("Demo mode"))
  assert_true(html.contains("Demo 8"))
  assert_true(html.contains("Review 1"))
  assert_true(html.contains("town-launchpad-signal-rail"))
  assert_true(html.contains("town-launchpad-gateway"))
  assert_true(html.contains(">Map<"))
  assert_true(html.contains("town-operations-deck"))
  assert_true(html.contains("town-ecosystem-preview"))
  assert_true(html.contains("tilemap/wenyu_reference_tilemap_iso.png"))
  assert_true(html.contains("Save"))
  assert_true(html.contains("Queue"))
  assert_true(html.contains("Request Desk"))
  assert_true(html.contains("Requests"))
  assert_true(html.contains("request-action-dock"))
  assert_true(html.contains("Standing watch"))
  assert_true(html.contains("Evidence book"))
  assert_true(html.contains("Attention"))
  assert_true(html.contains("Review work"))
  assert_true(html.contains("attention-dock"))
  assert_true(html.contains("Latest signal"))
  assert_true(html.contains("Town Areas"))
  assert_true(html.contains("Districts"))
  assert_true(html.contains("Residents"))
  assert_true(html.contains("Quests"))
  assert_true(html.contains(">Social<"))
}

///|
test "default dashboard groups secondary operating surfaces in one deck" {
  let html = render_default_dashboard_test_html(init_model())
  assert_true(html.contains("town-operations-deck"))
  assert_true(html.contains("request-desk"))
  assert_true(html.contains("attention-dock"))
  assert_true(html.contains("town-areas-launcher"))
  assert_true(html.contains("town-area-detail-empty"))
  assert_true(!html.contains("town-area-detail-body"))
  assert_true(html.contains("town-ecosystem-preview-visual"))
  assert_true(html.contains("request-action-dock"))
  assert_true(html.contains("dashboard-section-tabs"))
  assert_true(html.contains("aria-label=\"Request type\""))
  assert_true(html.contains("aria-label=\"Town areas\""))
  assert_true(html.contains("aria-controls=\"request-composer-panel\""))
  assert_true(html.contains("aria-controls=\"town-area-detail\""))
}

///|
test "dashboard ecosystem sections render only the selected detail surface" {
  let districts = render_default_dashboard_test_html({
    ..init_model(),
    dashboard_section: Some(DashboardSection::DistrictSystems),
  })
  assert_true(districts.contains("District Systems"))
  assert_true(districts.contains("town-area-detail"))
  assert_true(districts.contains("aria-pressed=\"true\""))
  assert_true(districts.contains("civic-module-card-visual"))
  assert_true(districts.contains("tilemap/districts/town_shell.png"))
  assert_true(!districts.contains("Resident Agents"))
  assert_true(!districts.contains("Points flow"))
  assert_true(!districts.contains("Robot calls"))
  let residents = render_default_dashboard_test_html({
    ..init_model(),
    dashboard_section: Some(DashboardSection::ResidentAgentsSection),
  })
  assert_true(residents.contains("Resident Agents"))
  assert_true(residents.contains("resident-avatar"))
  assert_true(residents.contains("tilemap/actors/roster/resident_0.png"))
  assert_true(residents.contains("Current signal"))
  assert_true(!residents.contains("District Systems"))
  assert_true(!residents.contains(">Memory<"))
  assert_true(!residents.contains(">Reflection<"))
  assert_true(!residents.contains(">Plan<"))
  assert_true(!residents.contains("Latest handoff"))
}

///|
test "dashboard ecosystem sections stay closed by default" {
  let html = render_default_dashboard_test_html(init_model())
  assert_true(!html.contains("District Systems"))
  assert_true(!html.contains("Resident Agents"))
  assert_true(!html.contains("Civic Quests"))
  assert_true(!html.contains("Social Capital"))
  assert_true(!html.contains("Town shell plus live civic systems"))
  assert_true(!html.contains("Digital twins with memory"))
  assert_true(!html.contains("Policy, contest, social, and offline workflows"))
  assert_true(!html.contains("Weak ties, talent graph"))
}

///|
test "dashboard ecosystem detail surfaces hide implementation copy" {
  let residents = render_default_dashboard_test_html({
    ..init_model(),
    dashboard_section: Some(DashboardSection::ResidentAgentsSection),
  })
  assert_true(!residents.contains("UI contract"))
  assert_true(!residents.contains("Memory Stream"))
  assert_true(!residents.contains("MoonClaw handoff"))
  assert_true(!residents.contains("direct durable memory writes"))
  let quests = render_default_dashboard_test_html({
    ..init_model(),
    dashboard_section: Some(DashboardSection::CivicQuestsSection),
  })
  assert_true(!quests.contains("static service text"))
  assert_true(!quests.contains("mayor can supervise"))
  let social = render_default_dashboard_test_html({
    ..init_model(),
    dashboard_section: Some(DashboardSection::SocialCapitalSection),
  })
  assert_true(!social.contains("The town should prove"))
  assert_true(!social.contains("Guide visitors"))
}

///|
test "dashboard request launcher renders one selected composer at a time" {
  let watch = render_default_dashboard_test_html({
    ..init_model(),
    request_composer: RequestComposerFocus::StandingWatchComposer,
  })
  assert_true(watch.contains(">Title<"))
  assert_true(watch.contains("aria-expanded=\"true\""))
  assert_true(watch.contains("aria-live=\"polite\""))
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
