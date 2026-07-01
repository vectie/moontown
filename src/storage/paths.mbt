///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}

///|
pub fn snapshot_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    moontown_product_state_dir()
  } else {
    base
  }
}

///|
pub fn moonsuite_product_id() -> String {
  "moontown"
}

///|
fn active_workspace_root() -> String {
  @os.cwd() catch {
    _ => "."
  }
}

///|
pub fn moontown_product_state_dir_for_workspace_root(
  workspace_root : String,
) -> String {
  @moonsuite.product_dir(
    @moonsuite.suite_root_for_workspace_root(workspace_root),
    moonsuite_product_id(),
  )
}

///|
pub fn moontown_product_state_dir() -> String {
  moontown_product_state_dir_for_workspace_root(active_workspace_root())
}

///|
pub fn moontown_product_artifact_for_workspace_root(
  workspace_root : String,
  relative : String,
) -> String {
  @moonsuite.product_artifact_for_workspace_root(
    workspace_root,
    moonsuite_product_id(),
    relative,
  )
}

///|
pub fn moontown_product_artifact(relative : String) -> String {
  moontown_product_artifact_for_workspace_root(
    active_workspace_root(),
    relative,
  )
}

///|
pub fn moontown_product_service_path() -> String {
  moontown_product_artifact("service.json")
}

///|
pub fn moontown_product_tmp_dir() -> String {
  @moonsuite.product_tmp_dir(
    @moonsuite.suite_root_for_workspace_root(active_workspace_root()),
    moonsuite_product_id(),
  )
}

///|
fn safe_watcher_goal_id(goal_id : String) -> String {
  let builder = StringBuilder::new()
  let mut emitted = 0
  let mut last_dash = false
  for char in goal_id.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      emitted += 1
      last_dash = false
    } else if !last_dash && emitted > 0 {
      builder.write_char('-')
      emitted += 1
      last_dash = true
    }
  }
  let value = builder.to_string().trim(chars="-").to_owned()
  if value.is_empty() {
    "standing-goal"
  } else {
    value
  }
}
