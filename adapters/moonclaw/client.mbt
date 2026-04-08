///|
pub struct SpawnWorkerRequest {
  worker : @core.WorkerRef
} derive(Show, Eq)

///|
pub struct AssignTaskRequest {
  assignment : @core.AssignmentPlan
  workspace_root : String
  context_summary : String
  skills : Array[String]
} derive(Show, Eq)

///|
pub struct PollWorkerResponse {
  worker_id : String
  status : @core.WorkerStatus
  detail : String
} derive(Show, Eq)

///|
pub struct TaskResultResponse {
  task_id : String
  status : @core.TownTaskStatus
  summary : String
  memory_candidates : Array[String]
} derive(Show, Eq)

///|
pub fn stub_spawn(req : SpawnWorkerRequest) -> String {
  "spawned \{req.worker.id}"
}

///|
pub fn stub_assign(req : AssignTaskRequest) -> String {
  "assigned \{req.assignment.task_id} to \{req.assignment.worker_id} in \{req.workspace_root}"
}

///|
pub fn stub_poll(worker_id : String) -> PollWorkerResponse {
  {
    worker_id,
    status: @core.WorkerStatus::Idle,
    detail: "moonclaw adapter stub",
  }
}

///|
pub fn stub_result(task_id : String) -> TaskResultResponse {
  {
    task_id,
    status: @core.TownTaskStatus::Done,
    summary: "moonclaw completed the starter task",
    memory_candidates: ["observation:success"],
  }
}
