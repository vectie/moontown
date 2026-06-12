///|
pub fn runtime_status_summary(
  state : @core.TownState,
  execution_counts : RuntimeStatusExecutionCounts,
  standing_goal_counts : RuntimeStatusStandingGoalCounts,
  watcher_record_count : Int,
  template_request_counts : @book_templates.BookTemplateRuntimeCounts,
  planned_action_count : Int,
) -> String {
  [
    runtime_status_inventory_summary(state),
    runtime_status_execution_summary(execution_counts),
    runtime_status_standing_goal_summary(standing_goal_counts),
    runtime_status_template_request_summary(template_request_counts),
    runtime_status_metric("watcher_records", watcher_record_count),
    runtime_status_metric("planned_actions", planned_action_count),
  ].join(" ")
}

///|
fn runtime_status_inventory_summary(state : @core.TownState) -> String {
  [
    runtime_status_metric("books", state.books.length()),
    runtime_status_metric("workers", state.workers.length()),
    runtime_status_metric("tasks", state.tasks.length()),
    runtime_status_metric("executions", state.executions.length()),
  ].join(" ")
}

///|
fn runtime_status_execution_summary(
  counts : RuntimeStatusExecutionCounts,
) -> String {
  [
    runtime_status_metric("running", counts.running),
    runtime_status_metric("review", counts.review),
    runtime_status_metric("failed", counts.failed),
    runtime_status_metric("stale", counts.stale),
  ].join(" ")
}

///|
fn runtime_status_standing_goal_summary(
  counts : RuntimeStatusStandingGoalCounts,
) -> String {
  [
    runtime_status_metric("standing_goals", counts.total),
    runtime_status_metric("enabled_standing_goals", counts.enabled),
    runtime_status_metric("disabled_standing_goals", counts.disabled),
    runtime_status_metric("due_goals", counts.due),
  ].join(" ")
}

///|
fn runtime_status_template_request_summary(
  counts : @book_templates.BookTemplateRuntimeCounts,
) -> String {
  [
    runtime_status_metric("book_template_requests", counts.total),
    runtime_status_metric("pending_template_requests", counts.pending),
    runtime_status_metric("failed_template_requests", counts.failed),
  ].join(" ")
}

///|
fn runtime_status_metric(key : String, value : Int) -> String {
  "\{key}=\{value}"
}
