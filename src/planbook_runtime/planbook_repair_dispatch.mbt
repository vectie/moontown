///|
async fn materialize_planbook_repair_task(
  criterion : PlanbookCriterionStatus,
  snapshot_path : String,
  workspace_root : String,
  book_catalog_path : String,
  dispatch : Bool,
  run_inline : Bool,
) -> PlanbookRepairTask {
  ignore(snapshot_path)
  ignore(book_catalog_path)
  let task_id = planbook_repair_task_id(criterion.id)
  let packet_path = planbook_repair_packet_path(workspace_root, task_id)
  write_planbook_repair_workspace(criterion, workspace_root)
  clear_stale_planbook_repair_result(workspace_root, criterion)
  let packet = planbook_repair_packet(criterion, task_id)
  let mut proposal_id : String? = None
  let mut run_id : String? = None
  let mut task_status = "queued"
  let mut summary = "Queued bounded repair packet for `\{criterion.id}`. Daemon ticks dispatch one Codex ACP repair automatically when no repair is active; `planbook repair --dispatch` is the explicit operator/debug trigger."
  if dispatch {
    let imported = @moonclaw.import_packet(
      packet,
      packet_path,
      cwd=workspace_root,
      confirm=true,
      run_inline~,
    ) catch {
      error => {
        let detail = "MoonClaw repair dispatch failed: \{error}"
        if planbook_repair_transient_dispatch_error(detail) {
          @moonclaw.save_packet_file(packet_path, packet)
          return {
            id: task_id,
            criterion_id: criterion.id,
            title: criterion.title,
            status: "queued",
            owner: criterion.owner,
            workspace_root,
            packet_path,
            proposal_id: None,
            run_id: None,
            summary: "MoonClaw repair dispatch deferred due to transient transport/resource contention: \{error}. Daemon will retry while the gap remains open.",
            validation_command: planbook_repair_validation_command(),
            generated_at_ms: @env.now(),
          }
        }
        return {
          id: task_id,
          criterion_id: criterion.id,
          title: criterion.title,
          status: "blocked",
          owner: criterion.owner,
          workspace_root,
          packet_path,
          proposal_id: None,
          run_id: None,
          summary: "MoonClaw repair dispatch failed: \{error}",
          validation_command: planbook_repair_validation_command(),
          generated_at_ms: @env.now(),
        }
      }
    }
    proposal_id = Some(imported.proposal_id)
    run_id = imported.run_id
    let launch_command = match imported.run_id {
      Some(run_id) if !run_inline =>
        Some(@moonclaw.run_confirmed_run(run_id, cwd=workspace_root))
      _ => None
    }
    task_status = if imported.run_id is Some(_) {
      "dispatched"
    } else {
      "queued"
    }
    summary = match launch_command {
      Some(command) => "\{imported.summary} Detached runner: \{command}"
      None => imported.summary
    }
  } else {
    @moonclaw.save_packet_file(packet_path, packet)
  }
  {
    id: task_id,
    criterion_id: criterion.id,
    title: criterion.title,
    status: task_status,
    owner: criterion.owner,
    workspace_root,
    packet_path,
    proposal_id,
    run_id,
    summary,
    validation_command: planbook_repair_validation_command(),
    generated_at_ms: @env.now(),
  }
}

///|
fn planbook_repair_transient_dispatch_error(detail : String) -> Bool {
  @runtime_error_policy.transient_external_dependency_error(detail)
}

///|
async fn clear_stale_planbook_repair_result(
  workspace_root : String,
  criterion : PlanbookCriterionStatus,
) -> Unit {
  let result_path = planbook_repair_result_path_for_workspace(workspace_root)
  let result_text = @support.read_text_or_empty(result_path)
  if result_text != "" &&
    planbook_repair_handoff_is_stale(criterion, result_text) {
    @support.write_text_file(
      planbook_repair_superseded_result_path(workspace_root),
      result_text,
    )
    @fs.remove(result_path) catch {
      _ => @support.write_text_file(result_path, "")
    }
  }
}

///|
async fn write_planbook_repair_status(
  task : PlanbookRepairTask,
  workspace_root : String,
  snapshot_path : String,
) -> Unit {
  @support.write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  @support.write_text_file(
    default_planbook_repair_markdown_path(snapshot_path~),
    render_planbook_repair_markdown(task),
  )
  @support.write_text_file(
    planbook_repair_workspace_status_page_path(workspace_root),
    render_planbook_repair_markdown(task),
  )
  append_planbook_change_log(
    workspace_root,
    "repair task \{task.status}",
    "Repair `\{task.id}` for criterion `\{task.criterion_id}` is `\{task.status}`. Summary: \{task.summary}",
  )
}
