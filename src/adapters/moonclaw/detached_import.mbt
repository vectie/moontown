///|
pub async fn import_packet_detached(
  packet : ExternalProposalPacket,
  packet_path : String,
  moonclaw_root? : String = "../moonclaw",
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  confirm? : Bool = false,
  run_inline? : Bool = false,
) -> ProposalImportReceipt {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  let resolved_packet_path = resolve_packet_path(packet_path)
  let receipt_path = detached_import_receipt_path(resolved_packet_path)
  let stderr_path = receipt_path + ".err"
  save_packet_file(resolved_packet_path, packet)
  ensure_parent_directory(receipt_path)
  let moon = moon_command()
  let args = proposal_import_args(
    moonclaw_root, resolved_packet_path, resolved_cwd, resolved_home, confirm, run_inline,
  )
  let command = @integration.render_command(moon, args)
  let shell_command = build_detached_shell_command_with_output(
    moon, args, receipt_path, stderr_path,
  )
  ignore(@integration.run_checked("/bin/zsh", ["-lc", shell_command]))
  {
    packet_id: packet.packet_id,
    packet_path: resolved_packet_path,
    proposal_id: "detached-\{packet.packet_id}",
    run_id: None,
    status: @core.TaskExecutionStatus::ProposalImported,
    command: "\{command} > \{receipt_path} 2> \{stderr_path}",
    summary: "Launched detached MoonClaw import for \{packet.packet_id}; waiting for receipt \{receipt_path}.",
  }
}

///|
pub async fn detached_import_receipt(
  packet_id : String,
  packet_path : String,
) -> ProposalImportReceipt? {
  let resolved_packet_path = resolve_packet_path(packet_path)
  let receipt_path = detached_import_receipt_path(resolved_packet_path)
  match moonclaw_optional_file_size(receipt_path) {
    Some(size) if size > 1_000_000L =>
      return Some({
        packet_id,
        packet_path: resolved_packet_path,
        proposal_id: "proposal-\{packet_id}",
        run_id: None,
        status: @core.TaskExecutionStatus::Failed,
        command: "detached MoonClaw import oversized receipt \{receipt_path}",
        summary: "Detached MoonClaw import produced an oversized receipt for \{packet_id} (\{size} bytes); treating it as failed operational output instead of parsing daemon stdout as JSON.",
      })
    _ => ()
  }
  let text = match moonclaw_read_optional_text(receipt_path) {
    Some(text) => text
    None => return None
  }
  let parsed = parse_json_from_command_text(text) catch {
    _ =>
      return detached_import_failure_receipt(
        packet_id, resolved_packet_path, text,
      )
  }
  let proposal_id = parse_json_string(parsed, "proposal_id").unwrap_or(
    "proposal-\{packet_id}",
  )
  let run_id = parse_json_string(parsed, "run_id")
  let receipt_status = import_receipt_status(
    run_id,
    parse_json_string(parsed, "status"),
  )
  Some({
    packet_id,
    packet_path: resolved_packet_path,
    proposal_id,
    run_id,
    status: receipt_status,
    command: "detached MoonClaw import receipt \{receipt_path}",
    summary: if receipt_status == @core.TaskExecutionStatus::Completed {
      "Detached MoonClaw import completed for \{packet_id}; inline run finished."
    } else if run_id is Some(run_id) {
      "Detached MoonClaw import completed for \{packet_id}; run \{run_id} is ready for supervision."
    } else {
      "Detached MoonClaw import completed for \{packet_id}; no run id was returned yet."
    },
  })
}

///|
pub fn detached_import_receipt_path(packet_path : String) -> String {
  resolve_packet_path(packet_path) + ".import.json"
}
