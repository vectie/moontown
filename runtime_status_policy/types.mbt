///|
pub(all) struct TownRuntimeStatus {
  snapshot_path : String
  has_snapshot : Bool
  book_count : Int
  worker_count : Int
  task_count : Int
  execution_count : Int
  event_count : Int
  running_count : Int
  review_count : Int
  failed_count : Int
  stale_count : Int
  completed_count : Int
  standing_goal_count : Int
  enabled_standing_goal_count : Int
  disabled_standing_goal_count : Int
  due_standing_goal_count : Int
  watcher_record_count : Int
  watcher_summary : String
  book_template_request_count : Int
  pending_book_template_request_count : Int
  failed_book_template_request_count : Int
  book_template_request_summary : String
  book_template_latest_event_summary : String
  daemon_tick : Int
  daemon_actions : Array[@scheduler.SchedulerAction]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RuntimeStatusExecutionCounts {
  running : Int
  review : Int
  failed : Int
  stale : Int
  completed : Int
}

///|
pub(all) struct RuntimeStatusStandingGoalCounts {
  total : Int
  enabled : Int
  disabled : Int
  due : Int
}
