///|
fn live_autonomy_journal_probe_line(
  tick : Int32,
  due_goal_count~ : Int32 = 0,
) -> String {
  Json::object({
    "tick": ToJson::to_json(tick),
    "active_worker_count": ToJson::to_json(0),
    "review_count": ToJson::to_json(0),
    "blocked_count": ToJson::to_json(0),
    "failed_count": ToJson::to_json(0),
    "due_goal_count": ToJson::to_json(due_goal_count),
    "planbook_open_count": ToJson::to_json(0),
    "planbook_repair_active_count": ToJson::to_json(0),
    "pending_book_template_request_count": ToJson::to_json(0),
    "failed_book_template_request_count": ToJson::to_json(0),
  }).stringify()
}

///|
fn live_autonomy_journal_snapshot_line(
  tick : Int32,
  status~ : String = "watching",
  summary~ : String = "old",
) -> String {
  Json::object({
    "generated_at_ms": ToJson::to_json("1"),
    "tick": ToJson::to_json(tick),
    "status": ToJson::to_json(status),
    "summary": ToJson::to_json(summary),
    "active_worker_count": ToJson::to_json(0),
    "review_count": ToJson::to_json(0),
    "blocked_count": ToJson::to_json(0),
    "accepted_update_count": ToJson::to_json(0),
    "no_change_count": ToJson::to_json(0),
    "failed_count": ToJson::to_json(0),
    "transient_infrastructure_debt_count": ToJson::to_json(0),
    "due_goal_count": ToJson::to_json(0),
    "standing_goal_count": ToJson::to_json(0),
    "enabled_standing_goal_count": ToJson::to_json(0),
    "disabled_standing_goal_count": ToJson::to_json(0),
    "planbook_open_count": ToJson::to_json(0),
    "planbook_repair_active_count": ToJson::to_json(0),
    "book_template_request_count": ToJson::to_json(0),
    "pending_book_template_request_count": ToJson::to_json(0),
    "failed_book_template_request_count": ToJson::to_json(0),
    "book_template_request_summary": ToJson::to_json("none"),
    "book_template_latest_event_summary": ToJson::to_json("none"),
    "latest_watcher_summary": ToJson::to_json("none"),
    "visual_projection_path": ToJson::to_json(""),
    "journal_path": ToJson::to_json(""),
    "digest_path": ToJson::to_json(""),
    "planbook_change_log_path": ToJson::to_json(""),
    "planbook_engineering_digest_path": ToJson::to_json(""),
    "latest_change_summary": ToJson::to_json("none"),
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
