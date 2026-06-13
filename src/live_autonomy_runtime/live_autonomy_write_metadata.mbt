///|
priv struct LiveAutonomyWriteMetadata {
  tick : Int
  planbook_open : Int
  planbook_repair_active : Int
  planbook_change_log_path : String
  planbook_engineering_digest_path : String
  latest_change_summary : String
  book_template_request_status : @book_templates.BookTemplateRequestStatus
  prior_stable_waiting_observation_streak : Int
}

///|
priv struct LiveAutonomyPlanbookMetadata {
  planbook_open : Int
  planbook_repair_active : Int
  planbook_change_log_path : String
  planbook_engineering_digest_path : String
  latest_change_summary : String
}

///|
async fn live_autonomy_planbook_metadata(
  snapshot_path : String,
) -> LiveAutonomyPlanbookMetadata {
  let planbook_open = planbook_open_gap_count(snapshot_path~)
  let planbook_repair_active = planbook_repair_active_count(snapshot_path~)
  let planbook_change_log_path = live_autonomy_planbook_change_log_path()
  let latest_change_summary = normalized_planbook_latest_change_summary(
    latest_planbook_change_summary(planbook_change_log_path),
    planbook_open,
    planbook_repair_active,
  )
  {
    planbook_open,
    planbook_repair_active,
    planbook_change_log_path,
    planbook_engineering_digest_path: live_autonomy_planbook_engineering_digest_path(),
    latest_change_summary,
  }
}

///|
async fn live_autonomy_write_metadata(
  state : @core.TownState,
  snapshot_path : String,
  daemon_tick : Int?,
) -> LiveAutonomyWriteMetadata {
  let planbook = live_autonomy_planbook_metadata(snapshot_path)
  let tick = match daemon_tick {
    Some(value) => value
    None => live_autonomy_tick(state)
  }
  {
    tick,
    planbook_open: planbook.planbook_open,
    planbook_repair_active: planbook.planbook_repair_active,
    planbook_change_log_path: planbook.planbook_change_log_path,
    planbook_engineering_digest_path: planbook.planbook_engineering_digest_path,
    latest_change_summary: planbook.latest_change_summary,
    book_template_request_status: @book_templates_runtime.inspect_book_template_request_status(
      request_path=@book_templates.request_path_for_snapshot(snapshot_path),
    ),
    prior_stable_waiting_observation_streak: prior_live_autonomy_stable_waiting_observation_streak(
      snapshot_path, tick,
    ),
  }
}
