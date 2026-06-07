///|
async fn planbook_task_status_from_run(
  workspace_root : String,
  criterion_id : String,
  run_id : String?,
  run_alive : Bool,
  status : String?,
) -> String {
  match status {
    Some(status) if planbook_repair_moonclaw_status_needs_live_runner(status) &&
      !run_alive => "stale"
    Some(status) if planbook_repair_moonclaw_status_is_succeeded(status) =>
      match run_id {
        Some(id) =>
          if planbook_run_has_accepted_repair_result(
              workspace_root, id, criterion_id,
            ) {
            "completed"
          } else {
            "failed"
          }
        None => "failed"
      }
    _ => planbook_task_status_from_run_status(status)
  }
}

///|
fn planbook_task_status_from_run_status(status : String?) -> String {
  match status {
    Some(status) if planbook_repair_moonclaw_status_is_pending(status) =>
      "dispatched"
    Some(status) if planbook_repair_moonclaw_status_is_running(status) =>
      "running"
    Some(status) if planbook_repair_moonclaw_status_is_succeeded(status) =>
      "failed"
    Some(status) if planbook_repair_moonclaw_status_is_failed_terminal(status) =>
      "failed"
    _ => "dispatched"
  }
}

///|
fn planbook_repair_moonclaw_status_needs_live_runner(status : String) -> Bool {
  planbook_repair_moonclaw_status_is_pending(status) ||
  planbook_repair_moonclaw_status_is_running(status)
}

///|
fn planbook_repair_moonclaw_status_is_pending(status : String) -> Bool {
  planbook_repair_moonclaw_status_bucket(Some(status)) == "pending"
}

///|
fn planbook_repair_moonclaw_status_is_running(status : String) -> Bool {
  planbook_repair_moonclaw_status_bucket(Some(status)) == "running"
}

///|
fn planbook_repair_moonclaw_status_is_succeeded(status : String) -> Bool {
  planbook_repair_moonclaw_status_bucket(Some(status)) == "succeeded"
}

///|
fn planbook_repair_moonclaw_status_is_failed_terminal(status : String) -> Bool {
  planbook_repair_moonclaw_status_bucket(Some(status)) == "failed-terminal"
}

///|
fn planbook_repair_moonclaw_status_bucket(status : String?) -> String {
  match status {
    Some("Pending") => "pending"
    Some("Running") | Some("WaitingForInput") => "running"
    Some("Succeeded") => "succeeded"
    Some("Failed") | Some("Cancelled") => "failed-terminal"
    _ => "unknown"
  }
}

///|
fn planbook_repair_index_recovery_summary(
  criterion : PlanbookCriterionStatus,
  run_id : String?,
  status : String?,
  task_status : String,
) -> String {
  let run_label = run_id.unwrap_or("none")
  let status_label = status.unwrap_or("unknown")
  if task_status == "stale" {
    "Recovered stale repair task from MoonClaw proposal index for criterion `\{criterion.id}`. Run `\{run_label}` is indexed as `\{status_label}`, but no live runner process exists."
  } else if task_status == "failed" &&
    planbook_repair_moonclaw_status_is_succeeded(status_label) {
    "Recovered repair task from MoonClaw proposal index for criterion `\{criterion.id}`. Run `\{run_label}` is indexed as `Succeeded`, but it did not emit accepted `\{planbook_repair_result_contract()}` evidence for this criterion."
  } else {
    "Recovered repair task from MoonClaw proposal index for criterion `\{criterion.id}`."
  }
}
