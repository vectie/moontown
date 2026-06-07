///|
pub struct PlanbookCriterionStatus {
  id : String
  plan_id : String
  title : String
  owner : String
  satisfied : Bool
  evidence : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct PlanbookAutonomyStatus {
  generated_at_ms : UInt64
  book_id : String
  workspace_root : String
  status : String
  open_count : Int
  satisfied_count : Int
  criteria : Array[PlanbookCriterionStatus]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_planbook_autonomy_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/autonomy.json"
}

///|
pub fn default_planbook_autonomy_digest_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/autonomy.md"
}

///|
pub async fn inspect_moontown_planbook_autonomy(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> PlanbookAutonomyStatus {
  let criteria = planbook_autonomy_criteria(
    snapshot_path, workspace_root, book_catalog_path,
  )
  let mut satisfied = 0
  for item in criteria {
    if item.satisfied {
      satisfied += 1
    }
  }
  let open = criteria.length() - satisfied
  {
    generated_at_ms: @env.now(),
    book_id: default_planbook_book_id(),
    workspace_root,
    status: if open == 0 {
      "self-healing-ready"
    } else {
      "self-healing-open"
    },
    open_count: open,
    satisfied_count: satisfied,
    criteria,
  }
}

///|
pub async fn write_moontown_planbook_autonomy(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  if !@fs.exists("\{workspace_root}/wiki/index.md") {
    ignore(bootstrap_moontown_planbook(book_catalog_path~, workspace_root~))
  } else {
    ensure_planbook_seed_files(workspace_root)
  }
  let status = inspect_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path~,
  )
  let status_path = default_planbook_autonomy_path(snapshot_path~)
  let digest_path = default_planbook_autonomy_digest_path(snapshot_path~)
  write_text_file(status_path, status.to_json().stringify(indent=2))
  write_text_file(digest_path, render_planbook_autonomy_markdown(status))
  write_planbook_autonomy_workspace(status, workspace_root)
  "PlanBook autonomy status: \{status.status}; open=\{status.open_count}; satisfied=\{status.satisfied_count}; wrote \{status_path} and \{digest_path}."
}

///|
pub async fn render_moontown_planbook_autonomy_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let status = inspect_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path~,
  )
  render_planbook_autonomy_markdown(status)
}

///|
pub async fn planbook_open_gap_count(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> Int {
  let status = inspect_moontown_planbook_autonomy(snapshot_path~)
  status.open_count
}
