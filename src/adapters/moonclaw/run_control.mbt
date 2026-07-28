///|
pub fn confirm_imported_run(
  receipt : ProposalImportReceipt,
) -> ProposalImportReceipt {
  {
    ..receipt,
    run_id: Some(receipt.run_id.unwrap_or("run-\{receipt.packet_id}")),
    status: RunConfirmed,
    summary: "Confirmed proposal \{receipt.proposal_id} into a live run.",
  }
}

///|
pub async fn run_confirmed_run(
  run_id : String,
  moonclaw_root? : String = default_moonclaw_root(),
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
) -> String {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  let (command_name, args) = moonclaw_runtime_invocation(moonclaw_root, [
    "proposal", "run", run_id, "--cwd", resolved_cwd, "--home", resolved_home,
  ])
  let command = @integration.render_command(command_name, args)
  let shell_command = build_detached_shell_command(command_name, args)
  ignore(@integration.run_checked("/bin/zsh", ["-lc", shell_command]))
  command
}
