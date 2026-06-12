///|
async fn write_dispatched_planbook_repair_with_run_status(
  snapshot_path : String,
  workspace_root : String,
  run_id : String,
  run_status : String,
  summary : String,
) -> Unit {
  let task : PlanbookRepairTask = {
    id: planbook_repair_task_id("live-runtime-recovery"),
    criterion_id: "live-runtime-recovery",
    title: "Live runtime failures are visible to PlanBook repair",
    status: "dispatched",
    owner: "moontown+moonclaw",
    workspace_root,
    packet_path: planbook_repair_packet_path_for_criterion(
      workspace_root, "live-runtime-recovery",
    ),
    proposal_id: Some("proposal"),
    run_id: Some(run_id),
    summary,
    validation_command: "moon test",
    generated_at_ms: 1,
  }
  @support.write_text_file(
    default_planbook_repair_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  @support.write_text_file(
    planbook_repair_job_index_path(workspace_root),
    "{\"runs\":[{\"id\":\"\{run_id}\",\"status\":\"\{run_status}\"}]}",
  )
}

///|
async test "planbook repair does not treat orphaned pending run as active" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-repair-pending-active-wbtest",
  )
  write_dispatched_planbook_repair_with_run_status(
    workspace.snapshot_path,
    workspace.workspace_root,
    "run-pending",
    "Pending",
    "Pending repair",
  )
  assert_eq(
    planbook_repair_active_count(snapshot_path=workspace.snapshot_path),
    0,
  )
}

///|
async test "planbook repair does not treat orphaned waiting-for-input run as active" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-repair-waiting-active-wbtest",
  )
  write_dispatched_planbook_repair_with_run_status(
    workspace.snapshot_path,
    workspace.workspace_root,
    "run-waiting",
    "WaitingForInput",
    "Waiting repair",
  )
  assert_eq(
    planbook_repair_active_count(snapshot_path=workspace.snapshot_path),
    0,
  )
}

///|
async test "planbook repair does not treat orphaned running run as active" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-planbook-repair-orphaned-active-wbtest",
  )
  write_dispatched_planbook_repair_with_run_status(
    workspace.snapshot_path,
    workspace.workspace_root,
    "run-orphaned",
    "Running",
    "Orphaned repair",
  )
  assert_eq(
    planbook_repair_active_count(snapshot_path=workspace.snapshot_path),
    0,
  )
}
