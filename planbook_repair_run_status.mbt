///|
async fn planbook_task_status_from_run(
  workspace_root : String,
  criterion_id : String,
  run_id : String?,
  run_alive : Bool,
  status : String?,
) -> String {
  match status {
    Some(status) if @planbook_policy.moonclaw_status_needs_live_runner(status) &&
      !run_alive => "stale"
    Some(status) if @planbook_policy.moonclaw_status_is_succeeded(status) =>
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
    _ => @planbook_policy.task_status_from_run_status(status)
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
    @planbook_policy.moonclaw_status_is_succeeded(status_label) {
    "Recovered repair task from MoonClaw proposal index for criterion `\{criterion.id}`. Run `\{run_label}` is indexed as `Succeeded`, but it did not emit accepted `\{@planbook_policy.repair_result_contract()}` evidence for this criterion."
  } else {
    "Recovered repair task from MoonClaw proposal index for criterion `\{criterion.id}`."
  }
}
