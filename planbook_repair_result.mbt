///|
async fn reconcile_planbook_repair_result(task : PlanbookRepairTask) -> String {
  let existing = planbook_repair_result_text_for_task(task)
  if existing != "" {
    return existing
  }
  let run_result = planbook_repair_result_text_from_run(task)
  if run_result != "" {
    @support.write_text_file(planbook_repair_result_path(task), run_result)
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
    @planbook_policy.moonclaw_status_is_succeeded(status_label) {
    "\{task.summary} Latest run is indexed as `Succeeded`, but no valid `\{@planbook_policy.repair_result_contract()}` result for criterion `\{task.criterion_id}` was emitted."
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
  let text = @support.read_text_or_empty(planbook_repair_result_path(task))
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
  let content = @support.json_string_field(payload, "content").unwrap_or(
    @support.json_string_field(payload, "summary").unwrap_or(""),
  )
  if planbook_repair_run_result_satisfies_contract(
      payload,
      content,
      task.workspace_root,
      run_id,
      task.criterion_id,
    ) {
    @planbook_policy.repair_result_text_with_patch_receipt(content, payload)
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
  let content = @support.json_string_field(payload, "content").unwrap_or(
    @support.json_string_field(payload, "summary").unwrap_or(""),
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
  @planbook_policy.repair_run_result_satisfies_contract(
    payload,
    text,
    run_id,
    criterion_id,
    planbook_repair_source_root(),
  )
}

///|
fn planbook_repair_run_result_has_accepted_evidence(
  payload : Json,
  text : String,
  run_id : String,
  criterion_id : String,
) -> Bool {
  @planbook_policy.repair_run_result_has_accepted_evidence(
    payload,
    text,
    run_id,
    criterion_id,
    planbook_repair_source_root(),
  )
}

///|
fn planbook_repair_result_satisfies_contract(
  text : String,
  criterion_id : String,
) -> Bool {
  @planbook_policy.repair_result_satisfies_contract(
    text,
    criterion_id,
    planbook_repair_source_root(),
  )
}

///|
fn planbook_repair_result_mentions_criterion(
  text : String,
  criterion_id : String,
) -> Bool {
  @planbook_policy.repair_result_mentions_criterion(text, criterion_id)
}

///|
fn planbook_repair_result_has_accepted_decision(text : String) -> Bool {
  @planbook_policy.repair_result_has_accepted_decision(text)
}

///|
fn planbook_repair_result_has_no_change_decision(text : String) -> Bool {
  @planbook_policy.repair_result_has_no_change_decision(text)
}

///|
fn planbook_repair_result_has_handoff_decision(text : String) -> Bool {
  @planbook_policy.repair_result_has_handoff_decision(text)
}
