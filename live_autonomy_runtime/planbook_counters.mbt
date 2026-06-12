///|
fn default_planbook_book_id() -> String {
  "plan-moontown-quality"
}

///|
fn default_planbook_workspace_root() -> String {
  @moonbook.default_workspace_root(default_planbook_book_id())
}

///|
async fn planbook_open_gap_count(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> Int {
  let parsed = match
    @support.read_optional_json_file(
      default_planbook_autonomy_path(snapshot_path),
    ) {
    Some(json) => json
    None => return 0
  }
  json_int_field(parsed, "open_count", fallback=0)
}

///|
async fn planbook_repair_active_count(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> Int {
  if @support.read_optional_json_file(
      default_planbook_repair_path(snapshot_path),
    )
    is Some(_) {
    1
  } else {
    0
  }
}

///|
fn default_planbook_autonomy_path(snapshot_path : String) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/autonomy.json"
}

///|
fn default_planbook_repair_path(snapshot_path : String) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/repair-task.json"
}

///|
fn planbook_autonomy_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
fn json_int_field(value : Json, key : String, fallback~ : Int) -> Int {
  match value {
    Object(object) =>
      match object.get(key) {
        Some(Number(value, ..)) => value.to_int()
        _ => fallback
      }
    _ => fallback
  }
}
