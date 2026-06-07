///|
pub struct LiveAutonomySpine {
  generated_at_ms : UInt64
  tick : Int
  status : String
  summary : String
  stable_waiting : Bool
  stable_waiting_observation_streak : Int
  stable_waiting_blockers : Array[String]
  active_worker_count : Int
  review_count : Int
  blocked_count : Int
  accepted_update_count : Int
  no_change_count : Int
  failed_count : Int
  transient_infrastructure_debt_count : Int
  due_goal_count : Int
  standing_goal_count : Int
  enabled_standing_goal_count : Int
  disabled_standing_goal_count : Int
  planbook_open_count : Int
  planbook_repair_active_count : Int
  book_template_request_count : Int
  pending_book_template_request_count : Int
  failed_book_template_request_count : Int
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
} derive(Debug, Eq, ToJson, FromJson)

///|
struct LiveAutonomyJournalTick {
  tick : Int
} derive(FromJson)

///|
struct LiveAutonomyStabilityProbe {
  tick : Int
  active_worker_count : Int
  review_count : Int
  blocked_count : Int
  failed_count : Int
  due_goal_count : Int
  planbook_open_count : Int
  planbook_repair_active_count : Int
  pending_book_template_request_count : Int
  failed_book_template_request_count : Int
} derive(FromJson)
