///|
pub struct PlanbookImplementationBacklogItem {
  id : String
  title : String
  owner : String
  priority : Int
  status : String
  source_plan : String
  rationale : String
  target_files : Array[String]
  acceptance : Array[String]
  validation : Array[String]
  created_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn implementation_backlog_path(workspace_root : String) -> String {
  "\{workspace_root}/raw/backlog/implementation-backlog.json"
}

///|
pub fn backlog_markdown_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/planning/implementation-backlog.md"
}

///|
pub fn change_log_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/history/change-log.md"
}

///|
pub fn backlog_progress_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/planning/backlog-progress.md"
}

///|
pub fn backlog_stop_policy_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/planning/stop-policy.md"
}

///|
pub fn backlog_completion_path(
  workspace_root : String,
  item_id : String,
) -> String {
  "\{workspace_root}/raw/backlog/completed/\{item_id}.md"
}
