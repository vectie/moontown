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
  let expected_knowledge_catalog_digest = match
    energy_valley_runtime.projection {
    Some(projection) => projection.knowledgeCatalogDigest
    None => None
  }
  let knowledge_domain_catalog = parse_bootstrap_knowledge_domain_catalog(
    expected_knowledge_catalog_digest,
  )
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
  let town_life = town_life_world_migrate_initial_save(
    initial_town_life_save(),
    active_energy_valley_seed(),
  )
  let town_life_world_states = town_life.world_states.unwrap_or([])
  let world_projection = town_life_world_projection_for_states(
    town_life_world_states,
    active_energy_valley_seed(),
  )
  let energy_world_delta = world_projection.ledger
  let model : Model = {
    tick: 0,
    paused: false,
    selection: initial_selection(),
    state_source: initial_state_source(),
    dashboard_section: initial_dashboard_section(),
    request_composer: initial_request_composer(),
    projection_snapshot,
    snapshot_version: town_snapshot_version(),
    energy_valley_runtime,
    energy_first_agent_open: false,
    visual_projection,
    visual_projection_version: visual_projection_version(),
    module_projections,
    module_projections_version: module_projections_version(),
    knowledge_domain_catalog,
    knowledge_domain_catalog_version: knowledge_domain_catalog_version(),
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
    ) ||
    template_launch_requested(),
    energy_guide_open: false,
    energy_reset_open: false,
    energy_status_open: false,
    energy_intro_open: town_life.player is None &&
    !browser_energy_valley_intro_seen(),
    energy_request_open: false,
    resident_explorer_open: false,
    resident_query: "",
    town_chronicle_open: false,
    energy_world_delta,
    energy_selected_building: None,
    energy_toast: initial_template_launch_status(),
    player: town_life.player,
    player_position: town_life.player_position,
    town_life_player_stamp: town_life.player_stamp,
    town_life_player_position_stamp: town_life.player_position_stamp,
    player_motion: None,
    player_follow: false,
    walk_mode: false,
    avatar_wizard_step: 0,
    avatar_draft_name: "",
    avatar_draft_persona: "",
    avatar_draft_color: 0,
    phone_open: false,
    phone_contact: "mayor",
    phone_draft: "",
    phone_log: town_life.phone_log,
    town_life_phone_events: town_life.phone_events.unwrap_or([]),
    town_life_phone_prune_watermarks: town_life.phone_prune_watermarks.unwrap_or([],
    ),
    phone_unread: 0,
    moonclaw_guide_pending: false,
    moonclaw_guide_error: "",
    town_life_writer_id: browser_town_life_v3_writer_id(),
    town_life_writer_counters: town_life.writer_counters.unwrap_or([]),
    spark: town_life_effective_spark(town_life),
    town_life_spark_floor: town_life.spark_floor.unwrap_or(town_life.spark),
    town_life_spark_awards: town_life.spark_awards.unwrap_or([]),
    quest_done: town_life.quest_done,
    life_toast: "",
    life_toast_tick: 0,
    knowledge_dialog_open: false,
    knowledge_draft_topic: "",
    knowledge_target_building: "",
    knowledge_target_site_id: "",
    posts: if town_life.posts.is_empty() {
      community_square_posts()
    } else {
      town_life.posts
    },
    town_life_post_reset_stamp: town_life.post_reset_stamp,
    town_life_post_tombstones: town_life.post_tombstones.unwrap_or([]),
    square_open: current_browser_query_param("share") == "knowledge-building",
    ops_open: false,
    ops_tab: 0,
    ops_reports: town_life.ops_reports.unwrap_or([]),
    town_life_ops_report_events: town_life.ops_report_events.unwrap_or([]),
    town_life_ops_report_prune_watermarks: town_life.ops_report_prune_watermarks.unwrap_or([],
    ),
    last_report_tick: town_life.last_report_tick,
    analytics: town_life.analytics,
    town_life_analytics_events: town_life.analytics_events.unwrap_or([]),
    town_life_analytics_prune_watermarks: town_life.analytics_prune_watermarks.unwrap_or([],
    ),
    ecosystem_attention_receipts: town_life.ecosystem_attention_receipts.unwrap_or([],
    ),
    town_life_attention_counters: town_life.attention_counters.unwrap_or([]),
    town_life_attention_prune_watermarks: [],
    town_life_world_states,
    metro_visible: true,
    checkin_day: town_life.checkin_day,
    map_lab_open: false,
    map_lab_layers: [
      MapLabLandBlocks,
      MapLabRoadsNavigation,
      MapLabPortalsSpurs,
      MapLabActivity,
      MapLabValidation,
    ],
    map_lab_selected_id: "",
    map_lab_query: "",
  }
  town_life_world_apply_projection(model, world_projection)
}
