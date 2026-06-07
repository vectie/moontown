///|
struct PlanbookAutonomyTestWorkspace {
  snapshot_path : String
  workspace_root : String
  catalog_path : String
}

///|
async fn planbook_autonomy_test_workspace(
  root : String,
) -> PlanbookAutonomyTestWorkspace {
  ignore_checked_command("rm", ["-rf", root])
  PlanbookAutonomyTestWorkspace::{
    snapshot_path: "\{root}/town.json",
    workspace_root: "\{root}/books/plan-moontown-quality",
    catalog_path: "\{root}/catalog.json",
  }
}
