///|
async fn ensure_wenyu_codex_acp_target(root : String) -> Unit {
  write_wenyu_codex_acp_target_config("\{root}/moonclaw.json", root)
  write_wenyu_codex_acp_target_config("\{root}/.moonclaw/moonclaw.json", root)
}

///|
async fn write_wenyu_codex_acp_target_config(
  path : String,
  root : String,
) -> Unit {
  let base = read_json_file_or_empty_object(path)
  write_text_file(
    path,
    upsert_codex_moontown_target_json(base, root).stringify(indent=2),
  )
}

///|
fn upsert_codex_moontown_target_json(config : Json, book_root : String) -> Json {
  let with_workspace = upsert_agent_default_json(
    config,
    "workspace",
    book_root.to_json(),
  )
  upsert_acp_target_json(
    with_workspace,
    "wenyu-codex-moontown",
    codex_moontown_target_json(),
  )
}

///|
fn codex_moontown_target_json() -> Json {
  {
    "backend": "codex",
    "label": "Codex Moontown Builder",
    "cwd": "/Users/kq/Workspace/moontown",
    "workspace": "/Users/kq/Workspace/moontown",
    "command": "/Users/kq/.nvm/versions/node/v22.22.1/bin/codex",
    "args": [
      "exec", "--model", "gpt-5.4", "--sandbox", "workspace-write", "--cd", "/Users/kq/Workspace/moontown",
      "--add-dir", "/Users/kq/Workspace/moonbook", "--add-dir", "/Users/kq/Workspace/moonclaw",
    ],
    "model": "gpt-5.4",
  }
}
