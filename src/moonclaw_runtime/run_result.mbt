///|
pub fn moonclaw_run_result_path(workspace_dir : String) -> String {
  "\{workspace_dir}/result.json"
}

///|
pub async fn moonclaw_run_result_text_from_workspace(
  workspace_dir : String,
  fallback_summary? : Bool = false,
) -> String {
  let parsed = match moonclaw_run_result_payload_from_workspace(workspace_dir) {
    Some(parsed) => parsed
    None => return ""
  }
  @support.json_string_field(parsed, "content").unwrap_or(
    if fallback_summary {
      @support.json_string_field(parsed, "summary").unwrap_or("")
    } else {
      ""
    },
  )
}

///|
pub async fn moonclaw_run_result_payload_from_workspace(
  workspace_dir : String,
) -> Json? {
  let result_path = moonclaw_run_result_path(workspace_dir)
  if !@fs.exists(result_path) {
    return None
  }
  Some(@json.parse(@fs.read_file(result_path).text())) catch {
    _ => None
  }
}

///|
pub async fn moonclaw_run_result_payload_from_run(
  run_id : String,
  cwd : String,
  home? : String = @moonclaw.default_moonclaw_home(),
) -> Json? {
  let workspace_dir = match @moonclaw.run_workspace_dir(run_id, cwd~, home~) {
    Some(workspace_dir) => workspace_dir
    None => return None
  }
  moonclaw_run_result_payload_from_workspace(workspace_dir)
}

///|
pub async fn moonclaw_run_result_text_from_run(
  run_id : String,
  cwd : String,
  fallback_summary? : Bool = false,
  home? : String = @moonclaw.default_moonclaw_home(),
) -> String {
  let workspace_dir = match @moonclaw.run_workspace_dir(run_id, cwd~, home~) {
    Some(workspace_dir) => workspace_dir
    None => return ""
  }
  moonclaw_run_result_text_from_workspace(workspace_dir, fallback_summary~)
}
