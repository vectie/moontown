///|
pub enum EmbeddedPlanningLayer {
  Strategic
  Domain
  Execution
} derive(Show, Eq)

///|
pub enum EmbeddedRuntimeMode {
  PlannerOnly
  Executor
} derive(Show, Eq)

///|
pub enum EmbeddedToolAccess {
  Disabled
  Limited
  Full
} derive(Show, Eq)

///|
pub enum EmbeddedMemoryScope {
  Step
  Workspace
  Domain
  Global
} derive(Show, Eq)

///|
pub enum EmbeddedHandoffKind {
  StrategicToDomain
  DomainToExecution
  ExecutionToDomain
  DomainToStrategic
} derive(Show, Eq)

///|
pub struct EmbeddedMoonclawRuntime {
  runtime_id : String
  display_name : String
  role_id : String
  planning_layer : EmbeddedPlanningLayer
  runtime_mode : EmbeddedRuntimeMode
  tool_access : EmbeddedToolAccess
  memory_scope : EmbeddedMemoryScope
  allow_delegate : Bool
  allow_workspace_write : Bool
  allow_execution_tools : Bool
  visible_tools : Array[String]
  skills : Array[String]
  output_contract : String?
  authority_scope : String
} derive(Show, Eq)

///|
pub fn EmbeddedMoonclawRuntime::new(
  runtime_id~ : String,
  display_name~ : String,
  role_id~ : String,
  planning_layer? : EmbeddedPlanningLayer = Execution,
  runtime_mode? : EmbeddedRuntimeMode = Executor,
  tool_access? : EmbeddedToolAccess = Full,
  memory_scope? : EmbeddedMemoryScope = Workspace,
  allow_delegate? : Bool = false,
  allow_workspace_write? : Bool = true,
  allow_execution_tools? : Bool = true,
  visible_tools? : Array[String] = [],
  skills? : Array[String] = [],
  output_contract? : String? = None,
  authority_scope~ : String,
) -> EmbeddedMoonclawRuntime {
  EmbeddedMoonclawRuntime::{
    runtime_id,
    display_name,
    role_id,
    planning_layer,
    runtime_mode,
    tool_access,
    memory_scope,
    allow_delegate,
    allow_workspace_write,
    allow_execution_tools,
    visible_tools,
    skills,
    output_contract,
    authority_scope,
  }
}

///|
pub struct EmbeddedRuntimeHandoff {
  kind : EmbeddedHandoffKind
  objective : String
  scope_summary : String
  constraints : Array[String]
  output_contract : String?
  target_role_id : String
} derive(Show, Eq)

///|
pub fn EmbeddedRuntimeHandoff::new(
  kind~ : EmbeddedHandoffKind,
  objective~ : String,
  scope_summary~ : String,
  constraints? : Array[String] = [],
  output_contract? : String? = None,
  target_role_id~ : String,
) -> EmbeddedRuntimeHandoff {
  EmbeddedRuntimeHandoff::{
    kind,
    objective,
    scope_summary,
    constraints,
    output_contract,
    target_role_id,
  }
}

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

///|
pub fn mayor_runtime() -> EmbeddedMoonclawRuntime {
  EmbeddedMoonclawRuntime::new(
    runtime_id="mayor",
    display_name="Mayor claw",
    role_id="mayor",
    planning_layer=Strategic,
    runtime_mode=PlannerOnly,
    tool_access=Limited,
    memory_scope=Global,
    allow_delegate=true,
    allow_workspace_write=false,
    allow_execution_tools=false,
    visible_tools=[
      "town-registry", "event-log", "scheduler-state", "health-state",
    ],
    skills=[
      "routing", "scheduling", "experiment-design", "safety-policy", "health-triage",
    ],
    output_contract=Some("mayor.dispatch.packet.v1"),
    authority_scope="town",
  )
}

///|
pub fn keeper_runtime(book : @core.BookRef) -> EmbeddedMoonclawRuntime {
  EmbeddedMoonclawRuntime::new(
    runtime_id="keeper-\{book.id}",
    display_name="\{book.name} Keeper",
    role_id="keeper",
    planning_layer=Domain,
    runtime_mode=PlannerOnly,
    tool_access=Limited,
    memory_scope=Domain,
    allow_delegate=true,
    allow_workspace_write=false,
    allow_execution_tools=false,
    visible_tools=[
      "book-workspace", "book-memory", "review-queue", "local-summaries",
    ],
    skills=[
      "wiki-maintenance", "source-synthesis", "memory-promotion", "review-policy",
      "task-shaping",
    ],
    output_contract=Some("keeper.plan.packet.v1"),
    authority_scope="book:\{book.id}",
  )
}

///|
pub fn worker_runtime(worker : @core.WorkerRef) -> EmbeddedMoonclawRuntime {
  EmbeddedMoonclawRuntime::new(
    runtime_id="worker-\{worker.id}",
    display_name=worker.name,
    role_id="worker",
    planning_layer=Execution,
    runtime_mode=Executor,
    tool_access=Full,
    memory_scope=Workspace,
    allow_delegate=false,
    allow_workspace_write=true,
    allow_execution_tools=true,
    visible_tools=["shell", "git", "filesystem", "browser", "domain-tools"],
    skills=worker.capabilities,
    output_contract=Some("worker.execution.packet.v1"),
    authority_scope="worker:\{worker.id}",
  )
}

///|
pub fn mayor_to_keeper_handoff(
  book_id : String,
  objective : String,
  scope_summary : String,
  constraints? : Array[String] = [],
) -> EmbeddedRuntimeHandoff {
  EmbeddedRuntimeHandoff::new(
    kind=StrategicToDomain,
    objective~,
    scope_summary~,
    constraints~,
    output_contract=Some("keeper.plan.packet.v1"),
    target_role_id="keeper:\{book_id}",
  )
}
