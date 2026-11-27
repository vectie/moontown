///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct TownRuntimeStatus {
  snapshot_path : String
  has_snapshot : Bool
  book_count : Int32
  worker_count : Int32
  task_count : Int32
  execution_count : Int32
  event_count : Int32
  running_count : Int32
  review_count : Int32
  failed_count : Int32
  stale_count : Int32
  completed_count : Int32
  // Legacy saved status objects omit this field; a missing value means zero.
  awaiting_acceptance_count : Int32?
  standing_goal_count : Int32
  enabled_standing_goal_count : Int32
  disabled_standing_goal_count : Int32
  due_standing_goal_count : Int32
  watcher_record_count : Int32
  watcher_summary : String
  book_template_request_count : Int32
  pending_book_template_request_count : Int32
  failed_book_template_request_count : Int32
  book_template_request_summary : String
  book_template_latest_event_summary : String
  daemon_tick : Int32
  daemon_actions : Array[@scheduler.SchedulerAction]
  summary : String
}

///|
pub(all) struct RuntimeStatusExecutionCounts {
  running : Int32
  review : Int32
  failed : Int32
  stale : Int32
  completed : Int32
  awaiting_acceptance : Int32
}

///|
pub(all) struct RuntimeStatusStandingGoalCounts {
  total : Int32
  enabled : Int32
  disabled : Int32
  due : Int32
}
