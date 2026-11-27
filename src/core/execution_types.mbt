///|
#derive(Debug, Eq, ToJson, FromJson)
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
  // Book review is approved; the original goal acceptance is still unevaluated.
  AwaitingAcceptance
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct AssignmentPlan {
  task_id : String
  worker_id : String
  book_id : String
  isolation : IsolationMode
  reason : String
}

///|
pub fn AssignmentPlan::new(
  task_id~ : String,
  worker_id~ : String,
  book_id~ : String,
  isolation~ : IsolationMode,
  reason~ : String,
) -> AssignmentPlan {
  { task_id, worker_id, book_id, isolation, reason, }
}

///|
#derive(Debug, Eq, ToJson, FromJson)
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
  attempt : Int32
  heartbeat_tick : Int32
  stale_after_tick : Int32
  next_retry_tick : Int32?
  result_decision : String
  requires_review : Bool
  notify_town : Bool
}

///|
pub fn TaskExecutionRecord::new(
  task_id~ : String,
  book_id~ : String,
  packet_id~ : String,
  packet_path~ : String,
  proposal_id~ : String? = None,
  run_id~ : String? = None,
  status~ : TaskExecutionStatus,
  summary~ : String,
  output_contract~ : String,
  context_pages~ : Array[String] = [],
  skill_paths~ : Array[String] = [],
  last_command~ : String? = None,
  assigned_worker_id~ : String? = None,
  attempt~ : Int32 = 1,
  heartbeat_tick~ : Int32 = 0,
  stale_after_tick~ : Int32 = 3,
  next_retry_tick~ : Int32? = None,
  result_decision~ : String = "pending",
  requires_review~ : Bool = false,
  notify_town~ : Bool = false,
) -> TaskExecutionRecord {
  {
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
