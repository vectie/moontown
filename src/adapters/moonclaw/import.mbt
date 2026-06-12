///|
pub async fn import_packet(
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
  save_packet_file(resolved_packet_path, packet)
  let moon = moon_command()
  let args = proposal_import_args(
    moonclaw_root, resolved_packet_path, resolved_cwd, resolved_home, confirm, run_inline,
  )
  let command = @integration.render_command(moon, args)
  let output = @integration.run_json(moon, args)
  let proposal_id = parse_json_string(output, "proposal_id").unwrap_or(
    "proposal-\{packet.packet_id}",
  )
  let run_id = parse_json_string(output, "run_id")
  {
    packet_id: packet.packet_id,
    packet_path: resolved_packet_path,
    proposal_id,
    run_id,
    status: if run_id is Some(_) {
      @core.TaskExecutionStatus::RunConfirmed
    } else {
      @core.TaskExecutionStatus::ProposalImported
    },
    command,
    summary: if run_id is Some(run_id) {
      "Imported \{packet.packet_id} into MoonClaw proposal \{proposal_id} and started run \{run_id}."
    } else {
      "Imported \{packet.packet_id} into MoonClaw proposal storage as \{proposal_id}."
    },
  }
}

///|
fn proposal_import_args(
  moonclaw_root : String,
  resolved_packet_path : String,
  resolved_cwd : String,
  resolved_home : String,
  confirm : Bool,
  run_inline : Bool,
) -> Array[String] {
  [
    "-C",
    moonclaw_root,
    "run",
    "cmd/main",
    "--",
    "proposal",
    "import",
    resolved_packet_path,
    "--json",
    "--cwd",
    resolved_cwd,
    "--home",
    resolved_home,
    ..if confirm {
      ["--confirm"]
    } else {
      []
    },
    ..if confirm && run_inline {
      ["--inline"]
    } else {
      []
    },
  ]
}
