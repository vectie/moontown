///|
pub fn standing_watch_empty_completion_no_change_summary(
  task_id : String,
) -> String {
  standing_watch_empty_completion_no_change_lines(task_id).join("\n")
}

///|
fn standing_watch_empty_completion_no_change_lines(
  task_id : String,
) -> Array[String] {
  [
    "standing_goal_decision: no_change",
    "delta_score: 0",
    "new_source_count: 0",
    "next_check_hint: normal",
    "checked_sources_count: 0",
    "new_sources_found: 0",
    "accepted_facts_count: 0",
    "rejected_facts_count: 0",
    "wiki_pages_changed_count: 0",
    "book_changed: no",
    "book_watch_record_id: \{task_id}",
    standing_watch_empty_completion_no_change_reason(),
  ]
}

///|
fn standing_watch_empty_completion_no_change_reason() -> String {
  "MoonBook result was an empty, non-review operational completion; mayor classified it as no_change so it does not block live autonomy."
}
