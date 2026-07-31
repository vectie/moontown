///|
fn standalone_viewport_requested() -> Bool {
  current_town_surface_route() is LegacyStandaloneViewport
}

///|
fn operations_surface_requested() -> Bool {
  current_town_surface_route() is OperationsConsole
}

///|
fn initial_viewport_mode() -> ViewportMode {
  match current_viewport_mode_param() {
    "editor" => ViewportMode::EditorMode
    "edit" => ViewportMode::EditorMode
    "output" => ViewportMode::OutputMode
    "final" => ViewportMode::OutputMode
    _ => ViewportMode::ViewMode
  }
}

///|
fn initial_selection() -> Selection {
  let module_id = current_viewport_module_param()
  if !module_id.is_empty() {
    Selection::Node(module_id)
  } else {
    let building_id = initial_template_launch().building_id
    if building_id.is_empty() {
      Selection::Overview
    } else {
      Selection::Node(building_id)
    }
  }
}

///|
fn initial_dashboard_section() -> DashboardSection? {
  match current_browser_query_param("area") {
    "districts" => Some(DashboardSection::DistrictSystems)
    "residents" => Some(DashboardSection::ResidentAgentsSection)
    "quests" => Some(DashboardSection::CivicQuestsSection)
    "social" => Some(DashboardSection::SocialCapitalSection)
    _ => initial_template_launch().dashboard_section
  }
}

///|
fn initial_request_composer() -> RequestComposerFocus {
  match current_browser_query_param("request") {
    "watch" => RequestComposerFocus::StandingWatchComposer
    "book" => RequestComposerFocus::EvidenceBookComposer
    _ => RequestComposerFocus::RequestShortcuts
  }
}

///|
fn init_model() -> Model {
  let projection_snapshot = parse_bootstrap_town_snapshot()
  let energy_valley_runtime = initial_energy_valley_runtime_state()
  let visual_projection = parse_bootstrap_visual_projection()
  let module_projections = parse_bootstrap_module_projections()
  let civic_status = parse_bootstrap_civic_status()
  let moondesk_handoff_artifacts = parse_bootstrap_moondesk_handoff_artifacts()
  let moondesk_bridge = parse_bootstrap_moondesk_bridge()
  let daemon_snapshot = parse_bootstrap_daemon_snapshot()
  let live_autonomy = parse_bootstrap_live_autonomy()
  let editor_pipeline = parse_bootstrap_editor_pipeline()
  let standing_goals = parse_bootstrap_standing_goals()
  let watcher_records = parse_bootstrap_watcher_records()
  let operator_requests = parse_bootstrap_operator_requests()
  let book_template_requests = parse_bootstrap_book_template_requests()
  let research_handoff = initial_research_handoff_state()
  let moonflow_receiver = initial_moonflow_receiver_state()
  let energy_valley_save = initial_energy_valley_save()
  {
    tick: 0,
    paused: false,
    selection: initial_selection(),
    state_source: initial_state_source(),
    viewport_mode: initial_viewport_mode(),
    dashboard_section: initial_dashboard_section(),
    request_composer: initial_request_composer(),
    projection_snapshot,
    snapshot_version: town_snapshot_version(),
    energy_valley_runtime,
    visual_projection,
    visual_projection_version: visual_projection_version(),
    module_projections,
    module_projections_version: module_projections_version(),
    civic_status,
    civic_status_version: civic_status_version(),
    moondesk_handoff_artifacts,
    moondesk_handoff_version: moondesk_handoff_version(),
    moondesk_bridge,
    moondesk_bridge_version: moondesk_bridge_version(),
    daemon_snapshot,
    daemon_snapshot_version: daemon_snapshot_version(),
    live_autonomy,
    live_autonomy_version: live_autonomy_version(),
    editor_pipeline,
    editor_pipeline_version: editor_pipeline_version(),
    standing_goals,
    standing_goals_version: standing_goals_version(),
    watcher_records,
    watcher_records_version: watcher_records_version(),
    operator_requests,
    operator_requests_version: operator_requests_version(),
    book_template_requests,
    book_template_requests_version: book_template_requests_version(),
    research_handoff,
    moonflow_receiver,
    request_title: "Track a new research topic",
    request_prompt: "Research the latest useful updates, screen sources carefully, and update the target MoonBook only when the evidence changes the baseline.",
    request_book_id: "research-topic",
    request_cadence: "60",
    request_quality_threshold: "85",
    request_submitting: false,
    request_status: "Ready to submit a standing watch request.",
    book_request_title: "PDF Evidence Watch",
    book_request_book_id: "research-pdf-evidence-watch",
    book_request_purpose: "Watch approved websites for related PDFs, extract full text, analyze with the book-owned method, and notify only when accepted knowledge changes.",
    book_request_websites: "https://example.org/reports\nhttps://example.com/publications",
    book_request_cadence: "60",
    book_request_analysis_method: "",
    book_request_submitting: false,
    book_request_status: "Ready to queue a PDF Evidence Watch MoonBook request.",
    budget: 76,
    energy: 62,
    pressure: 34,
    stability: 78,
    energy_weather: Sunny,
    energy_weather_auto: true,
    energy_time_scale: 60,
    energy_tool: InspectTool,
    energy_board_open: energy_valley_dashboard_requested(
      current_browser_query_param("panel"),
      current_viewport_mode_param(),
    ) ||
    template_launch_requested(),
    energy_guide_open: false,
    energy_reset_open: false,
    energy_intro_open: !browser_energy_valley_intro_seen(),
    energy_request_open: false,
    energy_build_budget: energy_valley_save.budget,
    energy_custom_buildings: energy_valley_save.buildings,
    energy_roads: energy_valley_save.roads,
    energy_parks: energy_valley_save.parks,
    energy_selected_building: None,
    energy_toast: initial_template_launch_status(),
  }
}
