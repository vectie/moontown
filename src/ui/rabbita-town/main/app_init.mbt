///|
fn standalone_viewport_requested() -> Bool {
  let path = current_browser_path()
  path.contains("viewport")
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
  if module_id.is_empty() {
    Selection::Overview
  } else {
    Selection::Node(module_id)
  }
}

///|
fn init_model() -> Model {
  let projection_snapshot = parse_bootstrap_town_snapshot()
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
  {
    tick: 0,
    paused: false,
    selection: initial_selection(),
    state_source: initial_state_source(projection_snapshot),
    viewport_mode: initial_viewport_mode(),
    dashboard_section: None,
    request_composer: RequestComposerFocus::RequestShortcuts,
    projection_snapshot,
    snapshot_version: town_snapshot_version(),
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
    energy: 68,
    pressure: 34,
    stability: 78,
  }
}
