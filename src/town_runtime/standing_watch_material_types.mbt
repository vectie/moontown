///|
priv struct MaterialWatchInput {
  goal : @core.StandingGoal
  task_id : String
  plan : @material_watch_plan.Plan
  before : Array[@material_watch_plan.Source]
  after : Array[@material_watch_plan.Source]
} derive(Eq, ToJson, FromJson)

///|
priv struct MaterialWatchChange {
  input : MaterialWatchInput
  input_path : String
  execution : @core.TaskExecutionRecord?
  book_receipt : @moonbook.PersistResultOutcome?
} derive(Eq, ToJson, FromJson)

///|
priv struct MaterialWatchJournal {
  contract : String
  goal_id : String
  book_id : String
  baseline_plan : @material_watch_plan.Plan
  baseline : Array[@material_watch_plan.Source]
  changes : Array[MaterialWatchChange]
} derive(Eq, ToJson, FromJson)

///|
priv enum MaterialWatchPreparation {
  Quiet(String)
  Waiting(String, String?)
  Dispatch(MaterialWatchChange)
}

///|
extend MaterialWatchInput with ToJson::{to_json}

///|
extend MaterialWatchJournal with ToJson::{to_json}

///|
fn material_watch_plan_path(goal : @core.StandingGoal) -> String? {
  let prefix = "local-material:"
  if goal.source_policy.has_prefix(prefix) {
    Some(goal.source_policy[prefix.length():].trim().to_owned())
  } else {
    None
  }
}

///|
fn material_watch_hash(value : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(value)))
}

///|
fn material_watch_directory(snapshot_path : String, goal_id : String) -> String {
  @storage.watcher_ledger_dir_for_snapshot(snapshot_path) +
  "/material-" +
  material_watch_hash(goal_id)
}

///|
fn material_watch_summary(change : MaterialWatchChange) -> String {
  let lines = [
    "material_watch_input: " + change.input_path,
    "material_watch_input_sha256: " +
    material_watch_hash(change.input.to_json().stringify()),
    "Material change review: " +
    material_watch_display_text(change.input.plan.intent),
    "Acceptance: " + material_watch_display_text(change.input.plan.acceptance),
    "Next owner action: " +
    material_watch_display_text(change.input.plan.next_action),
  ]
  for source in change.input.after {
    lines.push(
      "Source: " +
      material_watch_display_text(source.path) +
      " sha256=" +
      source.sha256,
    )
  }
  lines.join("\n")
}

///|
/// Plan text is evidence, never a legacy watcher decision marker. Exact text is
/// retained in the JSON input; the status summary uses one-line display text.
fn material_watch_display_text(text : String) -> String {
  text
  .replace_all(old=":", new="：")
  .replace_all(old="=", new="＝")
  .replace_all(old="\n", new=" ")
  .replace_all(old="\r", new=" ")
}

///|
fn preserve_material_watch_summary(
  previous : String,
  summary : String,
) -> String {
  if @standing_watch_policy.standing_watch_marker_value(
      previous, "material_watch_input",
    )
    is None {
    return summary
  }
  let lines = [summary]
  for raw in previous.split("\n") {
    let line = raw.to_owned()
    if [
        "material_watch_input:", "material_watch_input_sha256:", "Material change review:",
        "Acceptance:", "Next owner action:", "Source:", "material_watch_book_persisted:",
      ].any(prefix => line.has_prefix(prefix)) &&
      !summary.contains(line) {
      lines.push(line)
    }
  }
  lines.join("\n")
}

///|
fn bind_material_watch_execution(
  execution : @core.TaskExecutionRecord,
  change : MaterialWatchChange,
) -> @core.TaskExecutionRecord {
  let execution = if execution.run_id is None {
    copy_execution_with(
      execution,
      result_decision=@core.unconfirmed_standing_watch_decision(),
      next_retry_tick=None,
      status=if execution.status == Completed ||
        execution.status == Failed ||
        execution.status == AwaitingPersistence {
        Stale
      } else {
        execution.status
      },
    )
  } else {
    execution
  }
  let summary = material_watch_summary(change)
  if execution.summary.contains(summary) {
    execution
  } else {
    copy_execution_with(
      execution,
      summary=execution.summary + "\n" + summary,
      context_pages=if execution.context_pages.contains(change.input_path) {
        execution.context_pages
      } else {
        [..execution.context_pages, change.input_path]
      },
    )
  }
}
