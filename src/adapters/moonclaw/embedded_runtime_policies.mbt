///|
pub fn embedded_runtime_policy_examples() -> Array[EmbeddedMoonclawRuntime] {
  [
    EmbeddedMoonclawRuntime::new(
      runtime_id="mayor-planner-example",
      display_name="Mayor Planner",
      role_id="mayor",
      planning_layer=Strategic,
      runtime_mode=PlannerOnly,
      tool_access=Limited,
      memory_scope=Global,
      allow_delegate=true,
      allow_workspace_write=false,
      allow_execution_tools=false,
      visible_tools=["town-registry", "health-state"],
      skills=["mayor-supervision", "mayor-goal-decomposition"],
      output_contract=Some("mayor.plan.v1"),
      authority_scope="town",
    ),
    EmbeddedMoonclawRuntime::new(
      runtime_id="step-inspector-example",
      display_name="Step Inspector",
      role_id="observer",
      planning_layer=Execution,
      runtime_mode=PlannerOnly,
      tool_access=Disabled,
      memory_scope=Step,
      allow_workspace_write=false,
      allow_execution_tools=false,
      authority_scope="single-step",
    ),
  ]
}

///|
pub fn embedded_handoff_examples() -> Array[EmbeddedRuntimeHandoff] {
  [
    EmbeddedRuntimeHandoff::new(
      kind=StrategicToDomain,
      objective="Translate a town goal into book-local work.",
      scope_summary="Town mayor to book lead.",
      target_role_id="keeper",
    ),
    EmbeddedRuntimeHandoff::new(
      kind=DomainToExecution,
      objective="Assign a scoped task to a worker claw.",
      scope_summary="Book lead to worker pool.",
      target_role_id="worker",
    ),
    EmbeddedRuntimeHandoff::new(
      kind=ExecutionToDomain,
      objective="Return evidence and memory candidates.",
      scope_summary="Worker result to book lead.",
      target_role_id="keeper",
    ),
    EmbeddedRuntimeHandoff::new(
      kind=DomainToStrategic,
      objective="Escalate readiness or risk to the mayor.",
      scope_summary="Book lead to town mayor.",
      target_role_id="mayor",
    ),
  ]
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
      "assets/skills/mayor-goal-decomposition/SKILL.md", "assets/skills/mayor-supervision/SKILL.md",
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
