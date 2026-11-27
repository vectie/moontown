///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct LiveAutonomySpine {
  generated_at_ms : UInt64
  tick : Int32
  status : String
  summary : String
  stable_waiting : Bool
  stable_waiting_observation_streak : Int32
  stable_waiting_blockers : Array[String]
  active_worker_count : Int32
  review_count : Int32
  blocked_count : Int32
  accepted_update_count : Int32
  no_change_count : Int32
  failed_count : Int32
  transient_infrastructure_debt_count : Int32
  due_goal_count : Int32
  standing_goal_count : Int32
  enabled_standing_goal_count : Int32
  disabled_standing_goal_count : Int32
  planbook_open_count : Int32
  planbook_repair_active_count : Int32
  book_template_request_count : Int32
  pending_book_template_request_count : Int32
  failed_book_template_request_count : Int32
  book_template_request_summary : String
  book_template_latest_event_summary : String
  latest_watcher_summary : String
  visual_projection_path : String
  journal_path : String
  digest_path : String
  planbook_change_log_path : String
  planbook_engineering_digest_path : String
  latest_change_summary : String
  next_actions : Array[String]
}

///|
#derive(Debug, Eq)
pub(all) struct LiveAutonomyMetricCounts {
  active_workers : Int32
  review : Int32
  blocked : Int32
  accepted_updates : Int32
  no_change : Int32
  failed : Int32
  transient_infrastructure_debt : Int32
  enabled_standing_goals : Int32
  disabled_standing_goals : Int32
  due_goals : Int32
}

///|
#derive(FromJson)
pub(all) struct LiveAutonomyJournalTick {
  tick : Int32
}

///|
#derive(FromJson)
pub(all) struct LiveAutonomyStabilityProbe {
  tick : Int32
  active_worker_count : Int32
  review_count : Int32
  blocked_count : Int32
  failed_count : Int32
  due_goal_count : Int32
  planbook_open_count : Int32
  planbook_repair_active_count : Int32
  pending_book_template_request_count : Int32
  failed_book_template_request_count : Int32
}
