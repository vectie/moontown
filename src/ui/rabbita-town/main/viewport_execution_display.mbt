///|
fn execution_display_title(execution : @core.TaskExecutionRecord) -> String {
  let label = execution_task_display_label(execution.task_id, execution.book_id)
  match execution_feed_kind(execution.status) {
    RunningExecution => "\{label} is running"
    AwaitingPersistenceExecution => "\{label} is waiting for MoonBook save"
    StaleExecution => "\{label} needs recovery"
    FailedExecution => "\{label} failed"
    QuietExecution => label
  }
}

///|
fn execution_display_detail(execution : @core.TaskExecutionRecord) -> String {
  match execution_feed_kind(execution.status) {
    RunningExecution => execution_running_detail(execution.book_id)
    AwaitingPersistenceExecution =>
      "The run is done; the next town action is keeper save and evidence capture."
    StaleExecution =>
      "Town supervision should recover the missed handoff or retry this work lane."
    FailedExecution =>
      "A work failure surfaced in the book lifecycle and should be reviewed."
    QuietExecution => execution.summary
  }
}

///|
fn execution_running_detail(book_id : String) -> String {
  match book_id {
    "wenyu-town-shell" =>
      "The town shell work lane is updating the operator surface."
    "wenyu-resident-twins" =>
      "Resident twin work is updating public-safe memory and reflection surfaces."
    "policy-hall" =>
      "Policy Hall work is preparing civic quest and rule updates."
    "wenyu-contest-express" =>
      "Contest Express work is checking event and readiness signals."
    "social-square" =>
      "Social Square work is preparing matching and cafe coordination."
    "talent-avenue" => "Talent Avenue work is refreshing talent graph signals."
    "ai-garden" =>
      "AI Garden work is preparing learning and assistant guidance."
    "wenyu-physical-bridge" =>
      "Physical Bridge work is syncing venue and robot service signals."
    _ => "A MoonBook work lane is running under town supervision."
  }
}

///|
fn execution_task_display_label(task_id : String, book_id : String) -> String {
  match task_id {
    "task-town-shell-implementation-backlog" => "Town shell backlog"
    "task-town-shell-code-patch" => "Town shell code patch"
    "task-town-shell-image-asset-pack" => "Town shell asset pack"
    "task-resident-twins-code-patch" => "Resident twins code patch"
    "task-policy-quest" => "Policy quest"
    "task-contest-readiness" => "Contest readiness"
    "task-cafe-match" => "Cafe match"
    "task-talent-graph" => "Talent graph"
    "task-ai-tip" => "AI Garden guidance"
    "task-physical-bridge-sync" => "Physical bridge sync"
    _ => execution_book_display_label(book_id)
  }
}

///|
fn execution_book_display_label(book_id : String) -> String {
  match book_id {
    "wenyu-town-shell" => "Town shell work"
    "wenyu-resident-twins" => "Resident twins work"
    "policy-hall" => "Policy Hall work"
    "wenyu-contest-express" => "Contest Express work"
    "social-square" => "Social Square work"
    "talent-avenue" => "Talent Avenue work"
    "ai-garden" => "AI Garden work"
    "wenyu-physical-bridge" => "Physical Bridge work"
    _ => "MoonBook work"
  }
}
