///|
priv struct ProjectionSnapshot {
  town : @core.TownState
  event_count : Int
} derive(FromJson)

///|
priv struct VisualAgentSnapshot {
  worker_id : String
  worker_name : String
  book_id : String
  book_title : String
  role : String
  status : String
  phase : String
  task_id : String?
  task_title : String?
  run_id : String?
  sprite_key : String
  zone_key : String
  location : String
  destination : String
  behavior : String
  effect : String
  visible_on_overworld : Bool
  message : String
  grid_x : Int
  grid_y : Int
  z : Int
} derive(FromJson)

///|
priv struct VisualBuildingSnapshot {
  book_id : String
  title : String
  zone_key : String
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
  effect : String
  message : String
} derive(FromJson)

///|
priv struct VisualModuleSnapshot {
  module_id : String
  book_id : String
  status : String
  source : String
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
  active_agent_count : Int
  message : String
} derive(FromJson)

///|
priv struct VisualProjectionSnapshot {
  tick : Int
  agents : Array[VisualAgentSnapshot]
  buildings : Array[VisualBuildingSnapshot]
  modules : Array[VisualModuleSnapshot]?
  messages : Array[String]
} derive(FromJson)

///|
priv struct DaemonJobSnapshot {
  id : String
  kind : String
  interval_seconds : Int
} derive(FromJson)

///|
priv struct DaemonSnapshot {
  daemon_id : String
  lease_owner : String
  tick_sequence : Int
  last_heartbeat_event_count : Int
  active_goal_ids : Array[String]
  jobs : Array[DaemonJobSnapshot]
} derive(FromJson)

///|
priv struct LiveAutonomySnapshot {
  generated_at_ms : String
  tick : Int
  status : String
  summary : String
  active_worker_count : Int
  review_count : Int
  blocked_count : Int
  accepted_update_count : Int
  no_change_count : Int
  failed_count : Int
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
} derive(FromJson)

///|
priv struct StandingGoalSnapshot {
  id : String
  title : String
  prompt : String
  target_book_id : String?
  cadence_ticks : Int
  next_due_tick : Int
  last_run_tick : Int?
  enabled : Bool
  source_policy : String
  quality_threshold : Int
} derive(FromJson)

///|
priv struct WatcherRunRecordSnapshot {
  goal_id : String
  tick : Int
  target_book_id : String
  decision : String
  delta_score : Int
  new_source_count : Int
  checked_sources_count : Int?
  new_sources_found : Int?
  accepted_facts_count : Int?
  rejected_facts_count : Int?
  wiki_pages_changed_count : Int?
  book_changed : String?
  detail : String
  task_id : String?
  run_id : String?
  next_due_tick : Int
} derive(FromJson)

///|
priv struct OperatorRequestSnapshot {
  id : String
  status : String
  created_at : String
  title : String
  prompt : String
  target_book_id : String
  cadence_ticks : Int
  source_policy : String
  quality_threshold : Int
  standing_goal_id : String
} derive(FromJson)

///|
priv struct RequestSubmitResult {
  ok : Bool
  request_id : String?
  standing_goal_id : String?
  status : String?
  error : String?
} derive(FromJson)
