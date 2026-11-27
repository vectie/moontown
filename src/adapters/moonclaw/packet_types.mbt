///|
#derive(Debug, Eq, ToJson, FromJson)
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
}

///|
pub fn ExternalProposalPacket::new(
  packet_id~ : String,
  title~ : String,
  summary~ : String,
  request_text~ : String,
  profile~ : String,
  output_contract~ : String,
  context_pages~ : Array[String] = [],
  skill_paths~ : Array[String] = [],
  notes~ : Array[String] = [],
  tags~ : Array[String] = [],
  metadata~ : Json = Json::object({}),
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
#derive(Debug, Eq, ToJson, FromJson)
pub struct ProposalImportReceipt {
  packet_id : String
  packet_path : String
  proposal_id : String
  run_id : String?
  status : @core.TaskExecutionStatus
  command : String
  summary : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct ProposalPollResponse {
  task_id : String
  run_id : String
  status : @core.TaskExecutionStatus
  summary : String
  memory_candidates : Array[String]
  result_decision : String
  requires_review : Bool
  notify_town : Bool
}

///|
pub fn timed_out_poll_response(
  task_id : String,
  run_id : String,
  summary : String,
) -> ProposalPollResponse {
  {
    task_id,
    run_id,
    status: Failed,
    summary,
    memory_candidates: [],
    result_decision: "blocked",
    requires_review: true,
    notify_town: true,
  }
}

///|
#derive(Debug, Eq)
pub struct SpawnWorkerRequest {
  worker : @core.WorkerRef
}

///|
pub fn SpawnWorkerRequest::new(worker~ : @core.WorkerRef) -> SpawnWorkerRequest {
  { worker, }
}

///|
#derive(Debug, Eq)
pub struct AssignTaskRequest {
  assignment : @core.AssignmentPlan
  workspace_root : String
  context_summary : String
  skills : Array[String]
}

///|
pub fn AssignTaskRequest::new(
  assignment~ : @core.AssignmentPlan,
  workspace_root~ : String,
  context_summary~ : String,
  skills~ : Array[String] = [],
) -> AssignTaskRequest {
  { assignment, workspace_root, context_summary, skills, }
}

///|
#derive(Debug, Eq)
pub struct PollWorkerResponse {
  worker_id : String
  status : @core.WorkerStatus
  detail : String
}

///|
pub fn PollWorkerResponse::new(
  worker_id~ : String,
  status~ : @core.WorkerStatus,
  detail~ : String,
) -> PollWorkerResponse {
  { worker_id, status, detail, }
}

///|
#derive(Debug, Eq)
pub struct TaskResultResponse {
  task_id : String
  status : @core.TownTaskStatus
  summary : String
  memory_candidates : Array[String]
}

///|
pub fn TaskResultResponse::new(
  task_id~ : String,
  status~ : @core.TownTaskStatus,
  summary~ : String,
  memory_candidates~ : Array[String] = [],
) -> TaskResultResponse {
  { task_id, status, summary, memory_candidates, }
}
