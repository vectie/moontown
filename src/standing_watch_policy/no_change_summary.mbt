///|
pub fn standing_watch_empty_completion_no_change_summary(
  task_id : String,
) -> String {
  standing_watch_empty_completion_no_change_lines(task_id).join("\n")
}

///|
pub fn standing_watch_empty_review_completion_summary(
  observed : @core.TaskExecutionRecord,
) -> String {
  [
    observed.summary,
    "keeper_auto_triage: empty_completion_no_change",
    standing_watch_empty_review_completion_reason_line(),
    standing_watch_empty_completion_no_change_summary(observed.task_id),
  ].join("\n")
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

///|
fn standing_watch_empty_review_completion_reason_line() -> String {
  "keeper_auto_triage_reason: \{standing_watch_empty_review_completion_reason()}"
}

///|
fn standing_watch_empty_review_completion_reason() -> String {
  [
    "watcher completed without a standing-goal decision marker, candidate insight, evidence delta, or source delta,",
    "so mayor treats it as no_change instead of human review debt.",
  ].join(" ")
}
