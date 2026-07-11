///|
fn append_execution_maintenance_summary(
  summary : String,
  maintenance_summary : String,
) -> String {
  if maintenance_summary.trim().is_empty() {
    summary
  } else {
    "\{maintenance_summary}\n\{summary}"
  }
}

///|
async fn import_packet_with_daemon_timeout(
  packet : @moonclaw.ExternalProposalPacket,
  packet_path : String,
  workspace_root : String,
  run_inline : Bool,
) -> @moonclaw.ProposalImportReceipt {
  let timeout_ms = moontown_moonclaw_import_timeout_ms()
  @async.with_timeout(timeout_ms, () => {
    @moonclaw.import_packet(
      packet,
      packet_path,
      cwd=workspace_root,
      confirm=true,
      run_inline~,
    )
  }) catch {
    _ =>
      raise Failure::Failure(
        "MoonTown external import timed out while importing MoonClaw proposal `\{packet.packet_id}` after \{timeout_ms}ms.",
      )
  }
}

///|
fn is_detached_standing_watch_task(task : @moonbook.BookTask) -> Bool {
  task.kind == @standing_watch_policy.standing_watch_task_kind()
}

///|
fn render_execution_commands(
  import_command : String,
  execution : (@moonclaw.ProposalPollResponse, String?)?,
) -> String {
  match execution {
    Some((_, Some(run_command))) => "\{import_command}\n\{run_command}"
    _ => import_command
  }
}
