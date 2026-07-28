///|
fn advance_model(model : Model) -> Model {
  let refresh = refresh_tick_state(model)
  let metrics = tick_metric_state(model)
  let next_tick = model.tick + 1
  let weather = if model.energy_weather_auto && next_tick % 75 == 0 {
    match
      energy_valley_variation(
        active_energy_valley_seed(),
        next_tick / 75,
        0,
        349,
        100,
      ) {
      value if value < 42 => Sunny
      value if value < 68 => Cloudy
      value if value < 88 => Rain
      _ => Snow
    }
  } else {
    model.energy_weather
  }
  let ticked = { ..model, tick: next_tick, energy_weather: weather }
  let refreshed = apply_tick_refresh_state(ticked, refresh)
  apply_tick_metric_state(refreshed, metrics)
}

///|
fn apply_tick_refresh_state(model : Model, refresh : TickRefreshState) -> Model {
  {
    ..model,
    state_source: refresh.state_source,
    projection_snapshot: refresh.projection_snapshot,
    snapshot_version: refresh.snapshot_version,
    energy_valley_runtime: refresh.energy_valley_runtime,
    visual_projection: refresh.visual_projection,
    visual_projection_version: refresh.visual_projection_version,
    module_projections: refresh.module_projections,
    module_projections_version: refresh.module_projections_version,
    moondesk_handoff_artifacts: refresh.moondesk_handoff_artifacts,
    moondesk_handoff_version: refresh.moondesk_handoff_version,
    moondesk_bridge: refresh.moondesk_bridge,
    moondesk_bridge_version: refresh.moondesk_bridge_version,
    daemon_snapshot: refresh.daemon_snapshot,
    daemon_snapshot_version: refresh.daemon_snapshot_version,
    live_autonomy: refresh.live_autonomy,
    live_autonomy_version: refresh.live_autonomy_version,
    editor_pipeline: refresh.editor_pipeline,
    editor_pipeline_version: refresh.editor_pipeline_version,
    standing_goals: refresh.standing_goals,
    standing_goals_version: refresh.standing_goals_version,
    watcher_records: refresh.watcher_records,
    watcher_records_version: refresh.watcher_records_version,
    operator_requests: refresh.operator_requests,
    operator_requests_version: refresh.operator_requests_version,
    book_template_requests: refresh.book_template_requests,
    book_template_requests_version: refresh.book_template_requests_version,
  }
}

///|
fn apply_tick_metric_state(model : Model, metrics : TickMetricState) -> Model {
  {
    ..model,
    budget: metrics.budget,
    energy: metrics.energy,
    pressure: metrics.pressure,
    stability: metrics.stability,
  }
}
