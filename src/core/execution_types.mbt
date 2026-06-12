///|
pub(all) enum TaskExecutionStatus {
  PacketReady
  ProposalImported
  RunConfirmed
  Running
  AwaitingPersistence
  ReviewQueued
  Completed
  Stale
  Failed
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct AssignmentPlan {
  task_id : String
  worker_id : String
  book_id : String
  isolation : IsolationMode
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn AssignmentPlan::new(
  task_id~ : String,
  worker_id~ : String,
  book_id~ : String,
  isolation~ : IsolationMode,
  reason~ : String,
) -> AssignmentPlan {
  AssignmentPlan::{ task_id, worker_id, book_id, isolation, reason }
}

///|
pub struct TaskExecutionRecord {
  task_id : String
  book_id : String
  packet_id : String
  packet_path : String
  proposal_id : String?
  run_id : String?
  status : TaskExecutionStatus
  summary : String
  output_contract : String
  context_pages : Array[String]
  skill_paths : Array[String]
  last_command : String?
  assigned_worker_id : String?
  attempt : Int
  heartbeat_tick : Int
  stale_after_tick : Int
  next_retry_tick : Int?
  result_decision : String
  requires_review : Bool
  notify_town : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn TaskExecutionRecord::new(
  task_id~ : String,
  book_id~ : String,
  packet_id~ : String,
  packet_path~ : String,
  proposal_id? : String? = None,
  run_id? : String? = None,
  status~ : TaskExecutionStatus,
  summary~ : String,
  output_contract~ : String,
  context_pages? : Array[String] = [],
  skill_paths? : Array[String] = [],
  last_command? : String? = None,
  assigned_worker_id? : String? = None,
  attempt? : Int = 1,
  heartbeat_tick? : Int = 0,
  stale_after_tick? : Int = 3,
  next_retry_tick? : Int? = None,
  result_decision? : String = "pending",
  requires_review? : Bool = false,
  notify_town? : Bool = false,
) -> TaskExecutionRecord {
  TaskExecutionRecord::{
    task_id,
    book_id,
    packet_id,
    packet_path,
    proposal_id,
    run_id,
    status,
    summary,
    output_contract,
    context_pages,
    skill_paths,
    last_command,
    assigned_worker_id,
    attempt,
    heartbeat_tick,
    stale_after_tick,
    next_retry_tick,
    result_decision,
    requires_review,
    notify_town,
  }
}
