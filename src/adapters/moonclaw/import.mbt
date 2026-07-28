///|
pub async fn import_packet(
  packet : ExternalProposalPacket,
  packet_path : String,
  moonclaw_root? : String = default_moonclaw_root(),
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  confirm? : Bool = false,
  run_inline? : Bool = false,
) -> ProposalImportReceipt {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  let resolved_packet_path = resolve_packet_path(packet_path)
  save_packet_file(resolved_packet_path, packet)
  let cli_args = proposal_import_cli_args(
    resolved_packet_path, resolved_cwd, resolved_home, confirm, run_inline,
  )
  let (command_name, args) = moonclaw_runtime_invocation(
    moonclaw_root, cli_args,
  )
  let command = @integration.render_command(command_name, args)
  let output = @integration.run_json(command_name, args)
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
      RunConfirmed
    } else {
      ProposalImported
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
fn proposal_import_cli_args(
  resolved_packet_path : String,
  resolved_cwd : String,
  resolved_home : String,
  confirm : Bool,
  run_inline : Bool,
) -> Array[String] {
  [
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
