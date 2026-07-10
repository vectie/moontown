///|
fn refresh_tick_state(model : Model) -> TickRefreshState {
  let versions = read_tick_refresh_versions()
  let projection_snapshot = refresh_snapshot_file(
    versions.snapshot,
    model.snapshot_version,
    model.projection_snapshot,
  )
  let visual_projection = refresh_visual_projection(
    versions.visual_projection,
    model.visual_projection_version,
    model.visual_projection,
  )
  let module_projections = refresh_module_projections(
    versions.module_projections,
    model,
  )
  let moondesk_handoff_artifacts = refresh_moondesk_handoff_artifacts(
    versions.moondesk_handoff,
    model,
  )
  let moondesk_bridge = refresh_moondesk_bridge(
    versions.moondesk_bridge,
    model.moondesk_bridge_version,
    model.moondesk_bridge,
  )
  let daemon_snapshot = refresh_daemon_snapshot(
    versions.daemon_snapshot,
    model.daemon_snapshot_version,
    model.daemon_snapshot,
  )
  let live_autonomy = refresh_live_autonomy(
    versions.live_autonomy,
    model.live_autonomy_version,
    model.live_autonomy,
  )
  let editor_pipeline = refresh_editor_pipeline(
    versions.editor_pipeline,
    model.editor_pipeline_version,
    model.editor_pipeline,
  )
  let standing_goals = refresh_standing_goals(versions.standing_goals, model)
  let watcher_records = refresh_watcher_records(versions.watcher_records, model)
  let operator_requests = refresh_operator_requests(
    versions.operator_requests,
    model,
  )
  let book_template_requests = refresh_book_template_requests(
    versions.book_template_requests,
    model,
  )
  {
    state_source: refreshed_state_source(model, projection_snapshot),
    projection_snapshot,
    snapshot_version: versions.snapshot,
    visual_projection,
    visual_projection_version: versions.visual_projection,
    module_projections,
    module_projections_version: versions.module_projections,
    moondesk_handoff_artifacts,
    moondesk_handoff_version: versions.moondesk_handoff,
    moondesk_bridge,
    moondesk_bridge_version: versions.moondesk_bridge,
    daemon_snapshot,
    daemon_snapshot_version: versions.daemon_snapshot,
    live_autonomy,
    live_autonomy_version: versions.live_autonomy,
    editor_pipeline,
    editor_pipeline_version: versions.editor_pipeline,
    standing_goals,
    standing_goals_version: versions.standing_goals,
    watcher_records,
    watcher_records_version: versions.watcher_records,
    operator_requests,
    operator_requests_version: versions.operator_requests,
    book_template_requests,
    book_template_requests_version: versions.book_template_requests,
  }
}

///|
fn read_tick_refresh_versions() -> TickRefreshVersions {
  {
    snapshot: town_snapshot_version(),
    visual_projection: visual_projection_version(),
    module_projections: module_projections_version(),
    moondesk_handoff: moondesk_handoff_version(),
    moondesk_bridge: moondesk_bridge_version(),
    daemon_snapshot: daemon_snapshot_version(),
    live_autonomy: live_autonomy_version(),
    editor_pipeline: editor_pipeline_version(),
    standing_goals: standing_goals_version(),
    watcher_records: watcher_records_version(),
    operator_requests: operator_requests_version(),
    book_template_requests: book_template_requests_version(),
  }
}

///|
fn refresh_module_projections(
  version : Int,
  model : Model,
) -> Array[BookProjectionFragment] {
  refresh_array_snapshot(
    version,
    model.module_projections_version,
    model.module_projections,
    parse_bootstrap_module_projections,
  )
}

///|
fn refresh_moondesk_handoff_artifacts(
  version : Int,
  model : Model,
) -> Array[MoondeskHandoffArtifact] {
  refresh_array_snapshot(
    version,
    model.moondesk_handoff_version,
    model.moondesk_handoff_artifacts,
    parse_bootstrap_moondesk_handoff_artifacts,
  )
}

///|
fn refresh_standing_goals(
  version : Int,
  model : Model,
) -> Array[StandingGoalSnapshot] {
  refresh_array_snapshot(
    version,
    model.standing_goals_version,
    model.standing_goals,
    parse_bootstrap_standing_goals,
  )
}

///|
fn refresh_watcher_records(
  version : Int,
  model : Model,
) -> Array[WatcherRunRecordSnapshot] {
  refresh_array_snapshot(
    version,
    model.watcher_records_version,
    model.watcher_records,
    parse_bootstrap_watcher_records,
  )
}

///|
fn refresh_operator_requests(
  version : Int,
  model : Model,
) -> Array[OperatorRequestSnapshot] {
  refresh_array_snapshot(
    version,
    model.operator_requests_version,
    model.operator_requests,
    parse_bootstrap_operator_requests,
  )
}

///|
fn refresh_book_template_requests(
  version : Int,
  model : Model,
) -> Array[BookTemplateRequestSnapshot] {
  refresh_array_snapshot(
    version,
    model.book_template_requests_version,
    model.book_template_requests,
    parse_bootstrap_book_template_requests,
  )
}
