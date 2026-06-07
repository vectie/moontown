///|
async fn reconcile_planbook_repair_result(task : PlanbookRepairTask) -> String {
  let existing = planbook_repair_result_text_for_task(task)
  if existing != "" {
    return existing
  }
  let run_result = planbook_repair_result_text_from_run(task)
  if run_result != "" {
    write_text_file(planbook_repair_result_path(task), run_result)
  }
  run_result
}

///|
async fn refresh_planbook_repair_task_from_run(
  task : PlanbookRepairTask,
) -> PlanbookRepairTask {
  let run_id = match task.run_id {
    Some(id) => id
    None => return task
  }
  let run_status = planbook_repair_run_status_in_workspace(
    task.workspace_root,
    run_id,
  )
  let run_alive = @moonclaw.run_process_alive(run_id)
  let status = planbook_task_status_from_run(
    task.workspace_root,
    task.criterion_id,
    Some(run_id),
    run_alive,
    run_status,
  )
  let status_label = run_status.unwrap_or("unknown")
  let summary = if status == task.status {
    task.summary
  } else if status == "failed" &&
    planbook_repair_moonclaw_status_is_succeeded(status_label) {
    "\{task.summary} Latest run is indexed as `Succeeded`, but no valid `\{planbook_repair_result_contract()}` result for criterion `\{task.criterion_id}` was emitted."
  } else if status == "stale" {
    "\{task.summary} Latest run is indexed as `\{status_label}`, but no live runner process exists."
  } else {
    "\{task.summary} Latest run status reconciled to `\{status}` from MoonClaw index status `\{status_label}`."
  }
  { ..task, status, summary }
}

///|
async fn planbook_repair_prefer_completed_index_task(
  task : PlanbookRepairTask,
  criterion : PlanbookCriterionStatus,
  workspace_root : String,
) -> PlanbookRepairTask {
  if task.status != "stale" && task.status != "failed" {
    return task
  }
  match latest_planbook_repair_task_from_job_index(criterion, workspace_root) {
    Some(index_task) if index_task.status == "completed" &&
      index_task.run_id != task.run_id => index_task
    _ => task
  }
}

///|
async fn planbook_repair_result_text_for_task(
  task : PlanbookRepairTask,
) -> String {
  let text = read_text_or_empty(planbook_repair_result_path(task))
  if planbook_repair_result_satisfies_contract(text, task.criterion_id) {
    text
  } else {
    ""
  }
}

///|
async fn planbook_repair_result_text_from_run(
  task : PlanbookRepairTask,
) -> String {
  let run_id = match task.run_id {
    Some(run_id) => run_id
    None => return ""
  }
  let payload = match
    moonclaw_run_result_payload_from_run(run_id, task.workspace_root) {
    Some(payload) => payload
    None => return ""
  }
  let content = json_string_field(payload, "content").unwrap_or(
    json_string_field(payload, "summary").unwrap_or(""),
  )
  if planbook_repair_run_result_satisfies_contract(
      payload,
      content,
      task.workspace_root,
      run_id,
      task.criterion_id,
    ) {
    planbook_repair_result_text_with_patch_receipt(content, payload)
  } else {
    ""
  }
}

///|
async fn planbook_run_has_accepted_repair_result(
  workspace_root : String,
  run_id : String,
  criterion_id : String,
) -> Bool {
  let payload = match
    moonclaw_run_result_payload_from_run(run_id, workspace_root) {
    Some(payload) => payload
    None => return false
  }
  let content = json_string_field(payload, "content").unwrap_or(
    json_string_field(payload, "summary").unwrap_or(""),
  )
  planbook_repair_run_result_has_accepted_evidence(
    payload, content, run_id, criterion_id,
  )
}

///|
fn planbook_repair_run_result_satisfies_contract(
  payload : Json,
  text : String,
  workspace_root : String,
  run_id : String,
  criterion_id : String,
) -> Bool {
  ignore(workspace_root)
  if !planbook_repair_result_mentions_criterion(text, criterion_id) {
    return false
  }
  if !planbook_repair_result_has_any_decision(text) {
    return false
  }
  !planbook_repair_result_has_accepted_decision(text) ||
  planbook_repair_run_result_has_accepted_evidence(
    payload, text, run_id, criterion_id,
  )
}

///|
fn planbook_repair_run_result_has_accepted_evidence(
  payload : Json,
  text : String,
  run_id : String,
  criterion_id : String,
) -> Bool {
  planbook_repair_result_has_accepted_decision(text) &&
  planbook_repair_result_has_engineering_evidence(text) &&
  planbook_repair_payload_has_valid_patch_receipt(
    payload,
    criterion_id,
    planbook_repair_source_root(),
    run_id,
  )
}

///|
fn planbook_repair_result_satisfies_contract(
  text : String,
  criterion_id : String,
) -> Bool {
  if !planbook_repair_result_mentions_criterion(text, criterion_id) {
    return false
  }
  if !planbook_repair_result_has_any_decision(text) {
    return false
  }
  !planbook_repair_result_has_accepted_decision(text) ||
  (
    planbook_repair_result_has_engineering_evidence(text) &&
    planbook_repair_text_has_valid_patch_receipt(
      text,
      criterion_id,
      planbook_repair_source_root(),
    )
  )
}

///|
fn planbook_repair_result_mentions_criterion(
  text : String,
  criterion_id : String,
) -> Bool {
  text.contains("criterion_id: \{criterion_id}") ||
  text.contains("\"criterion_id\":\"\{criterion_id}\"") ||
  text.contains("\"criterion_id\": \"\{criterion_id}\"")
}

///|
fn planbook_repair_result_has_any_decision(text : String) -> Bool {
  planbook_repair_result_decisions().any(fn(decision) {
    planbook_repair_result_has_decision(text, decision)
  })
}

///|
fn planbook_repair_result_has_accepted_decision(text : String) -> Bool {
  planbook_repair_result_has_decision(text, "accepted")
}

///|
fn planbook_repair_result_has_external_owner_decision(text : String) -> Bool {
  planbook_repair_result_has_decision(text, "needs_external_owner")
}

///|
fn planbook_repair_result_has_blocked_decision(text : String) -> Bool {
  planbook_repair_result_has_decision(text, "blocked")
}

///|
fn planbook_repair_result_has_no_change_decision(text : String) -> Bool {
  planbook_repair_result_has_decision(text, "no_change")
}

///|
fn planbook_repair_result_has_handoff_decision(text : String) -> Bool {
  planbook_repair_result_has_external_owner_decision(text) ||
  planbook_repair_result_has_blocked_decision(text)
}

///|
fn planbook_repair_result_has_decision(
  text : String,
  decision : String,
) -> Bool {
  text.contains("repair_decision: \{decision}") ||
  text.contains("\"repair_decision\":\"\{decision}\"") ||
  text.contains("\"repair_decision\": \"\{decision}\"")
}

///|
fn planbook_repair_result_decisions() -> Array[String] {
  ["accepted", "needs_external_owner", "blocked", "no_change"]
}

///|
fn planbook_repair_result_has_engineering_evidence(text : String) -> Bool {
  planbook_repair_result_records_validation_passes(text) &&
  planbook_repair_result_engineering_evidence_markers().all(fn(marker) {
    text.contains(marker)
  })
}

///|
fn planbook_repair_result_engineering_evidence_markers() -> Array[String] {
  [
    "validation:", "diff_summary:", "plan_update_status:", "commit_status:", "commit_message:",
    "push_status:",
  ]
}
