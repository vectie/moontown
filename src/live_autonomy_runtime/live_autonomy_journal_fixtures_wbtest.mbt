///|
fn live_autonomy_journal_probe_line(
  tick : Int,
  due_goal_count? : Int = 0,
) -> String {
  Json::object({
    "tick": tick.to_json(),
    "active_worker_count": (0).to_json(),
    "review_count": (0).to_json(),
    "blocked_count": (0).to_json(),
    "failed_count": (0).to_json(),
    "due_goal_count": due_goal_count.to_json(),
    "planbook_open_count": (0).to_json(),
    "planbook_repair_active_count": (0).to_json(),
    "pending_book_template_request_count": (0).to_json(),
    "failed_book_template_request_count": (0).to_json(),
  }).stringify()
}

///|
fn live_autonomy_journal_snapshot_line(
  tick : Int,
  status? : String = "watching",
  summary? : String = "old",
) -> String {
  Json::object({
    "generated_at_ms": "1".to_json(),
    "tick": tick.to_json(),
    "status": status.to_json(),
    "summary": summary.to_json(),
    "active_worker_count": (0).to_json(),
    "review_count": (0).to_json(),
    "blocked_count": (0).to_json(),
    "accepted_update_count": (0).to_json(),
    "no_change_count": (0).to_json(),
    "failed_count": (0).to_json(),
    "transient_infrastructure_debt_count": (0).to_json(),
    "due_goal_count": (0).to_json(),
    "standing_goal_count": (0).to_json(),
    "enabled_standing_goal_count": (0).to_json(),
    "disabled_standing_goal_count": (0).to_json(),
    "planbook_open_count": (0).to_json(),
    "planbook_repair_active_count": (0).to_json(),
    "book_template_request_count": (0).to_json(),
    "pending_book_template_request_count": (0).to_json(),
    "failed_book_template_request_count": (0).to_json(),
    "book_template_request_summary": "none".to_json(),
    "book_template_latest_event_summary": "none".to_json(),
    "latest_watcher_summary": "none".to_json(),
    "visual_projection_path": "".to_json(),
    "journal_path": "".to_json(),
    "digest_path": "".to_json(),
    "planbook_change_log_path": "".to_json(),
    "planbook_engineering_digest_path": "".to_json(),
    "latest_change_summary": "none".to_json(),
    "next_actions": Json::array([]),
  }).stringify()
}

///|
async fn write_live_autonomy_journal_probe_lines(
  snapshot_path : String,
  lines : Array[String],
) -> Unit {
  @support.write_text_file(
    default_town_journal_path(snapshot_path~),
    lines.join("\n") + "\n",
  )
}
