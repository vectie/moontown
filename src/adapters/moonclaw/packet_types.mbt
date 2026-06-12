///|
pub struct ExternalProposalPacket {
  packet_id : String
  title : String
  summary : String
  request_text : String
  profile : String
  output_contract : String
  context_pages : Array[String]
  skill_paths : Array[String]
  notes : Array[String]
  tags : Array[String]
  metadata : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn ExternalProposalPacket::new(
  packet_id~ : String,
  title~ : String,
  summary~ : String,
  request_text~ : String,
  profile~ : String,
  output_contract~ : String,
  context_pages? : Array[String] = [],
  skill_paths? : Array[String] = [],
  notes? : Array[String] = [],
  tags? : Array[String] = [],
  metadata? : Json = Json::object({}),
) -> ExternalProposalPacket {
  {
    packet_id,
    title,
    summary,
    request_text,
    profile,
    output_contract,
    context_pages,
    skill_paths,
    notes,
    tags,
    metadata,
  }
}

///|
pub struct ProposalImportReceipt {
  packet_id : String
  packet_path : String
  proposal_id : String
  run_id : String?
  status : @core.TaskExecutionStatus
  command : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct ProposalPollResponse {
  task_id : String
  run_id : String
  status : @core.TaskExecutionStatus
  summary : String
  memory_candidates : Array[String]
  result_decision : String
  requires_review : Bool
  notify_town : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn timed_out_poll_response(
  task_id : String,
  run_id : String,
  summary : String,
) -> ProposalPollResponse {
  {
    task_id,
    run_id,
    status: @core.TaskExecutionStatus::Failed,
    summary,
    memory_candidates: [],
    result_decision: "blocked",
    requires_review: true,
    notify_town: true,
  }
}

///|
pub struct SpawnWorkerRequest {
  worker : @core.WorkerRef
} derive(Debug, Eq)

///|
pub fn SpawnWorkerRequest::new(worker~ : @core.WorkerRef) -> SpawnWorkerRequest {
  { worker, }
}

///|
pub struct AssignTaskRequest {
  assignment : @core.AssignmentPlan
  workspace_root : String
  context_summary : String
  skills : Array[String]
} derive(Debug, Eq)

///|
pub fn AssignTaskRequest::new(
  assignment~ : @core.AssignmentPlan,
  workspace_root~ : String,
  context_summary~ : String,
  skills? : Array[String] = [],
) -> AssignTaskRequest {
  { assignment, workspace_root, context_summary, skills }
}

///|
pub struct PollWorkerResponse {
  worker_id : String
  status : @core.WorkerStatus
  detail : String
} derive(Debug, Eq)

///|
pub fn PollWorkerResponse::new(
  worker_id~ : String,
  status~ : @core.WorkerStatus,
  detail~ : String,
) -> PollWorkerResponse {
  { worker_id, status, detail }
}

///|
pub struct TaskResultResponse {
  task_id : String
  status : @core.TownTaskStatus
  summary : String
  memory_candidates : Array[String]
} derive(Debug, Eq)

///|
pub fn TaskResultResponse::new(
  task_id~ : String,
  status~ : @core.TownTaskStatus,
  summary~ : String,
  memory_candidates? : Array[String] = [],
) -> TaskResultResponse {
  { task_id, status, summary, memory_candidates }
}
