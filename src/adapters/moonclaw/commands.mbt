///|
pub fn build_import_command(
  packet_path : String,
  moonclaw_root? : String = default_moonclaw_root(),
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  confirm? : Bool = false,
  run_inline? : Bool = false,
) -> String {
  let confirm_flag = if confirm { " --confirm" } else { "" }
  let inline_flag = if confirm && run_inline { " --inline" } else { "" }
  "moon -C \{moonclaw_root} run cmd/main -- proposal import \{packet_path} --json --cwd \{cwd} --home \{home}\{confirm_flag}\{inline_flag}"
}

///|
pub fn build_run_command(
  run_id : String,
  moonclaw_root? : String = default_moonclaw_root(),
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
) -> String {
  "moon -C \{moonclaw_root} run cmd/main -- proposal run \{run_id} --cwd \{cwd} --home \{home}"
}

///|
pub fn default_moonclaw_home() -> String {
  ".moonclaw"
}
