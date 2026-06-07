///|
async fn write_planbook_repair_acp_target(workspace_root : String) -> Unit {
  let home = "\{workspace_root}/.moonclaw"
  let path = "\{home}/moonclaw.json"
  let source_root = planbook_repair_source_root()
  let base = read_json_file_or_empty_object(path)
  let codex_command = resolved_codex_command()
  let target : Json = {
    "backend": "codex",
    "label": "Codex PlanBook Repair",
    "cwd": source_root,
    "workspace": source_root,
    "command": codex_command,
    "args": resolved_codex_args(),
    "model": "gpt-5",
  }
  write_text_file(
    path,
    upsert_acp_target_json(base, "codex-main", target).stringify(indent=2),
  )
}

///|
fn resolved_codex_command() -> String {
  match optional_env_text("CODEX_BIN") {
    Some(command) => command
    None => "/Users/kq/.nvm/versions/node/v22.22.1/bin/node"
  }
}

///|
fn resolved_codex_args() -> Array[String] {
  match optional_env_text("CODEX_BIN") {
    Some(_) => ["exec"]
    None =>
      [
        "/Users/kq/.nvm/versions/node/v22.22.1/lib/node_modules/@openai/codex/bin/codex.js",
        "exec", "--sandbox", "workspace-write",
      ]
  }
}
