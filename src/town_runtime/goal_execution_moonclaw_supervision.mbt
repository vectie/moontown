///|
async fn ensure_run_execution(
  task_id : String,
  run_id : String,
  workspace_root : String,
) -> (@moonclaw.ProposalPollResponse, String?)? {
  let initial = @moonclaw.poll_run(
    task_id,
    run_id,
    cwd=workspace_root,
    detect_orphan=false,
  )
  let launch_command = if initial.status
    is @core.TaskExecutionStatus::RunConfirmed {
    Some(@moonclaw.run_confirmed_run(run_id, cwd=workspace_root))
  } else {
    None
  }
  let current = wait_for_moonclaw_run(task_id, run_id, workspace_root)
  Some((current, launch_command))
}

///|
async fn wait_for_moonclaw_run(
  task_id : String,
  run_id : String,
  workspace_root : String,
) -> @moonclaw.ProposalPollResponse {
  let supervision_seconds = moontown_moonclaw_supervision_seconds()
  let mut latest = @moonclaw.poll_run(
    task_id,
    run_id,
    cwd=workspace_root,
    detect_orphan=false,
  )
  if supervision_seconds <= 0 {
    return latest
  }
  for attempt = 0; attempt < supervision_seconds; attempt = attempt + 1 {
    if !is_live_moonclaw_status(latest.status) {
      return latest
    }
    @async.sleep(1_000)
    latest = @moonclaw.poll_run(
      task_id,
      run_id,
      cwd=workspace_root,
      detect_orphan=false,
    )
  }
  @moonclaw.timed_out_poll_response(
    task_id,
    run_id,
    "MoonClaw run \{run_id} did not settle within the \{supervision_seconds} second Moontown supervision window; treating it as failed so the mayor can record blockers and continue recovery.",
  )
}

///|
fn is_live_moonclaw_status(status : @core.TaskExecutionStatus) -> Bool {
  @core.live_execution_status(status)
}
