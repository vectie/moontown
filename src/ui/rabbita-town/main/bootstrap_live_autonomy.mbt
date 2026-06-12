///|
fn parse_bootstrap_daemon_snapshot() -> DaemonSnapshot? {
  let text = load_bootstrap_daemon_snapshot_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_live_autonomy() -> LiveAutonomySnapshot? {
  let text = load_bootstrap_live_autonomy_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  let decoded : LiveAutonomySnapshot = @json.from_json(parsed) catch {
    _ =>
      match parsed {
        Object(object) => live_autonomy_snapshot_from_object(object)
        _ => return None
      }
  }
  Some(decoded)
}

///|
fn live_json_int(object : Map[String, Json], key : String) -> Int {
  match object.get(key) {
    Some(Number(value, ..)) => value.to_int()
    _ => 0
  }
}

///|
fn live_json_string(
  object : Map[String, Json],
  key : String,
  fallback : String,
) -> String {
  match object.get(key) {
    Some(String(value)) => value
    _ => fallback
  }
}

///|
fn live_json_string_array(
  object : Map[String, Json],
  key : String,
) -> Array[String] {
  match object.get(key) {
    Some(value) => @json.from_json(value) catch { _ => [] }
    None => []
  }
}

///|
fn live_autonomy_snapshot_from_object(
  object : Map[String, Json],
) -> LiveAutonomySnapshot {
  {
    generated_at_ms: live_json_string(object, "generated_at_ms", ""),
    tick: live_json_int(object, "tick"),
    status: live_json_string(object, "status", "unknown"),
    summary: live_json_string(object, "summary", ""),
    active_worker_count: live_json_int(object, "active_worker_count"),
    review_count: live_json_int(object, "review_count"),
    blocked_count: live_json_int(object, "blocked_count"),
    accepted_update_count: live_json_int(object, "accepted_update_count"),
    no_change_count: live_json_int(object, "no_change_count"),
    failed_count: live_json_int(object, "failed_count"),
    due_goal_count: live_json_int(object, "due_goal_count"),
    standing_goal_count: live_json_int(object, "standing_goal_count"),
    enabled_standing_goal_count: live_json_int(
      object, "enabled_standing_goal_count",
    ),
    disabled_standing_goal_count: live_json_int(
      object, "disabled_standing_goal_count",
    ),
    planbook_open_count: live_json_int(object, "planbook_open_count"),
    planbook_repair_active_count: live_json_int(
      object, "planbook_repair_active_count",
    ),
    book_template_request_count: live_json_int(
      object, "book_template_request_count",
    ),
    pending_book_template_request_count: live_json_int(
      object, "pending_book_template_request_count",
    ),
    failed_book_template_request_count: live_json_int(
      object, "failed_book_template_request_count",
    ),
    book_template_request_summary: live_json_string(
      object, "book_template_request_summary", "none",
    ),
    book_template_latest_event_summary: live_json_string(
      object, "book_template_latest_event_summary", "none",
    ),
    latest_watcher_summary: live_json_string(
      object, "latest_watcher_summary", "none",
    ),
    visual_projection_path: live_json_string(
      object, "visual_projection_path", "",
    ),
    journal_path: live_json_string(object, "journal_path", ""),
    digest_path: live_json_string(object, "digest_path", ""),
    planbook_change_log_path: live_json_string(
      object, "planbook_change_log_path", "",
    ),
    planbook_engineering_digest_path: live_json_string(
      object, "planbook_engineering_digest_path", "",
    ),
    latest_change_summary: live_json_string(
      object, "latest_change_summary", "none",
    ),
    next_actions: live_json_string_array(object, "next_actions"),
  }
}
