///|
async fn planbook_repair_task_in_flight(task : PlanbookRepairTask) -> Bool {
  if task.status != "dispatched" && task.status != "running" {
    return false
  }
  let run_id = match task.run_id {
    Some(run_id) => run_id
    None => return false
  }
  match planbook_repair_run_status(task, run_id) {
    Some(status) if planbook_repair_moonclaw_status_needs_live_runner(status) =>
      @moonclaw.run_process_alive(run_id)
    Some(_) => false
    None => @moonclaw.run_process_alive(run_id)
  }
}

///|
async fn planbook_repair_run_status(
  task : PlanbookRepairTask,
  run_id : String,
) -> String? {
  planbook_repair_run_status_in_workspace(task.workspace_root, run_id)
}

///|
async fn planbook_repair_run_status_in_workspace(
  workspace_root : String,
  run_id : String,
) -> String? {
  let path = planbook_repair_job_index_path(workspace_root)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  match parsed {
    Object(root) =>
      match root.get("runs") {
        Some(Array(runs)) => {
          for item in runs {
            match item {
              Object(run) =>
                if json_object_string(run, "id") == Some(run_id) {
                  return json_object_string(run, "status")
                }
              _ => ()
            }
          }
          None
        }
        _ => None
      }
    _ => None
  }
}

///|
async fn latest_planbook_repair_task_from_job_index(
  criterion : PlanbookCriterionStatus,
  workspace_root : String,
) -> PlanbookRepairTask? {
  let path = planbook_repair_job_proposals_path(workspace_root)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  match parsed {
    Object(root) =>
      match root.get("proposals") {
        Some(Array(proposals)) => {
          let mut found : PlanbookRepairTask? = None
          for item in proposals {
            match item {
              Object(proposal) => {
                let request_text = json_object_string(proposal, "request_text").unwrap_or(
                  "",
                )
                if request_text.contains("Open criterion: `\{criterion.id}`") {
                  let proposal_id = json_object_string(proposal, "id")
                  let run_id = json_object_string(proposal, "last_run_id")
                  let run_status = match run_id {
                    Some(id) =>
                      planbook_repair_run_status_in_workspace(
                        workspace_root, id,
                      )
                    None => None
                  }
                  let run_alive = match run_id {
                    Some(id) => @moonclaw.run_process_alive(id)
                    None => false
                  }
                  let task_status = planbook_task_status_from_run(
                    workspace_root,
                    criterion.id,
                    run_id,
                    run_alive,
                    run_status,
                  )
                  found = Some({
                    id: planbook_repair_task_id(criterion.id),
                    criterion_id: criterion.id,
                    title: criterion.title,
                    status: task_status,
                    owner: criterion.owner,
                    workspace_root,
                    packet_path: planbook_repair_packet_path_for_criterion(
                      workspace_root,
                      criterion.id,
                    ),
                    proposal_id,
                    run_id,
                    summary: planbook_repair_index_recovery_summary(
                      criterion, run_id, run_status, task_status,
                    ),
                    validation_command: planbook_repair_validation_command(),
                    generated_at_ms: @env.now(),
                  })
                }
              }
              _ => ()
            }
          }
          found
        }
        _ => None
      }
    _ => None
  }
}
