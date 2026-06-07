///|
async fn current_live_autonomy_spine(
  snapshot_path : String,
  fallback : LiveAutonomySpine,
) -> LiveAutonomySpine {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let inputs = load_live_autonomy_runtime_inputs(
        snapshot_path,
        snapshot.town,
      )
      build_live_autonomy_spine(
        current_live_autonomy_build_input(
          snapshot.town,
          snapshot_path,
          inputs,
          fallback,
        ),
      )
    }
    None => fallback
  }
}

///|
async fn current_live_autonomy_build_input(
  state : @core.TownState,
  snapshot_path : String,
  inputs : LiveAutonomyRuntimeInputs,
  fallback : LiveAutonomySpine,
) -> LiveAutonomyBuildInput {
  {
    state,
    snapshot_path,
    standing_goals: inputs.standing_goals,
    watcher_records: inputs.watcher_records,
    tick_summary: "",
    daemon_tick: Some(inputs.daemon_tick),
    planbook_open: fallback.planbook_open_count,
    planbook_repair_active: fallback.planbook_repair_active_count,
    planbook_change_log_path: fallback.planbook_change_log_path,
    planbook_engineering_digest_path: fallback.planbook_engineering_digest_path,
    latest_change_summary: fallback.latest_change_summary,
    book_template_request_status: inspect_book_template_request_status(
      request_path=default_book_template_request_path(snapshot_path~),
    ),
    prior_stable_waiting_observation_streak: prior_live_autonomy_stable_waiting_observation_streak(
      snapshot_path,
      inputs.daemon_tick,
    ),
  }
}

///|
fn decode_live_autonomy_spine(json : Json) -> LiveAutonomySpine? {
  Some(@json.from_json(json)) catch {
    _ => None
  }
}
