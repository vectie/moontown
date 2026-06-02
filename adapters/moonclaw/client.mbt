///|
pub enum EmbeddedPlanningLayer {
  Strategic
  Domain
  Execution
} derive(Debug, Eq)

///|
pub enum EmbeddedRuntimeMode {
  PlannerOnly
  Executor
} derive(Debug, Eq)

///|
pub enum EmbeddedToolAccess {
  Disabled
  Limited
  Full
} derive(Debug, Eq)

///|
pub enum EmbeddedMemoryScope {
  Step
  Workspace
  Domain
  Global
} derive(Debug, Eq)

///|
pub enum EmbeddedHandoffKind {
  StrategicToDomain
  DomainToExecution
  ExecutionToDomain
  DomainToStrategic
} derive(Debug, Eq)

///|
pub impl Show for EmbeddedPlanningLayer with fn output(self, logger) {
  match self {
    Strategic => logger.write_string("Strategic")
    Domain => logger.write_string("Domain")
    Execution => logger.write_string("Execution")
  }
}

///|
pub impl Show for EmbeddedRuntimeMode with fn output(self, logger) {
  match self {
    PlannerOnly => logger.write_string("PlannerOnly")
    Executor => logger.write_string("Executor")
  }
}

///|
pub impl Show for EmbeddedToolAccess with fn output(self, logger) {
  match self {
    Disabled => logger.write_string("Disabled")
    Limited => logger.write_string("Limited")
    Full => logger.write_string("Full")
  }
}

///|
pub impl Show for EmbeddedMemoryScope with fn output(self, logger) {
  match self {
    Step => logger.write_string("Step")
    Workspace => logger.write_string("Workspace")
    Domain => logger.write_string("Domain")
    Global => logger.write_string("Global")
  }
}

///|
pub impl Show for EmbeddedHandoffKind with fn output(self, logger) {
  match self {
    StrategicToDomain => logger.write_string("StrategicToDomain")
    DomainToExecution => logger.write_string("DomainToExecution")
    ExecutionToDomain => logger.write_string("ExecutionToDomain")
    DomainToStrategic => logger.write_string("DomainToStrategic")
  }
}

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
} derive(Debug, Eq)

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
} derive(Debug, Eq)

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
struct RunsIndexFile {
  runs : Array[StoredRun]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct StoredRun {
  id : String
  workspace_dir : String?
  status : String
  summary : String?
  error : String?
} derive(Debug, Eq, ToJson, FromJson)

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

///|
pub fn default_packet_directory() -> String {
  ".moontown/packets"
}

///|
pub fn packet_file_path(packet_dir : String, packet_id : String) -> String {
  "\{packet_dir}/\{packet_id}.json"
}

///|
pub fn proposal_packet_from_bundle(
  bundle : @moonbook.WorkerContextBundle,
  title : String,
  summary : String,
  profile : String,
  packet_id? : String? = None,
  task? : @moonbook.BookTask? = None,
  notes? : Array[String] = [],
  tags? : Array[String] = [],
) -> ExternalProposalPacket {
  let resolved_packet_id = packet_id.unwrap_or("packet-\{bundle.task_id}")
  {
    packet_id: resolved_packet_id,
    title,
    summary,
    request_text: bundle.prompt,
    profile,
    output_contract: packet_output_contract(bundle.output_contract),
    context_pages: bundle.context_pages,
    skill_paths: bundle.skill_paths,
    notes,
    tags,
    metadata: {
      "producer": "moontown".to_json(),
      "book_id": bundle.book_id.to_json(),
      "workspace_root": bundle.workspace_root.to_json(),
      "task_id": bundle.task_id.to_json(),
      "memory_summary": bundle.memory_summary.to_json(),
      "disable_waiting_for_input": true.to_json(),
      "best_effort_on_missing_input": true.to_json(),
      "profile_metadata": {
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
      },
      "step_metadata": packet_step_metadata(task),
    },
  }
}

///|
fn packet_step_metadata(task : @moonbook.BookTask?) -> Json {
  let fields : Map[String, Json] = {
    "disable_waiting_for_input": true.to_json(),
    "best_effort_on_missing_input": true.to_json(),
  }
  match task {
    Some(task) => {
      let provider_kind = provider_task_kind_for_book_task(task)
      let course_task = is_moontown_course_task(task)
      let research_bootstrap = !course_task &&
        is_moontown_research_bootstrap_task(task)
      let task_prompt = if research_bootstrap {
        research_bootstrap_task_prompt()
      } else if course_task {
        course_task_prompt()
      } else {
        task.prompt
      }
      let target_pages = if research_bootstrap {
        research_bootstrap_target_pages()
      } else if course_task {
        course_target_pages()
      } else {
        task.target_pages
      }
      let task_spec : Map[String, Json] = {
        "id": task.id.to_json(),
        "title": task.title.to_json(),
        "kind": provider_kind.to_json(),
        "prompt": task_prompt.to_json(),
        "priority": task.priority.to_json(),
        "requires_review": task.requires_review.to_json(),
        "target_pages": target_pages.to_json(),
      }
      fields.set("extension_task_id", task.id.to_json())
      fields.set("bookapi_task_id", task.id.to_json())
      fields.set("extension_task_spec", Json::object(task_spec))
      fields.set("bookapi_task_spec", Json::object(task_spec))
      fields.set("extension_task_kind", provider_kind.to_json())
      fields.set("bookapi_task_kind", provider_kind.to_json())
      fields.set("extension_priority", task.priority.to_json())
      fields.set("bookapi_priority", task.priority.to_json())
      fields.set("extension_requires_review", task.requires_review.to_json())
      fields.set("bookapi_requires_review", task.requires_review.to_json())
      fields.set("extension_target_pages", target_pages.to_json())
      fields.set("bookapi_target_pages", target_pages.to_json())
    }
    None => ()
  }
  Json::object(fields)
}

///|
fn research_bootstrap_task_prompt() -> String {
  [
    "Produce MoonClaw raw research bootstrap artifacts only.", "Use web discovery before local file inspection.",
    "Let the LLM choose sources and claims from screened evidence.", "Do not materialize durable wiki pages in this worker task; MoonBook owns wiki materialization from the raw envelope.",
    "If a tool or source is blocked, write explicit blockers and continue with evidence limits.",
  ].join(" ")
}

///|
fn research_bootstrap_target_pages() -> Array[String] {
  [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/deep-report.md", "raw/bootstrap/marketing-brief.md",
  ]
}

///|
fn course_task_prompt() -> String {
  [
    "Produce MoonClaw beginner-course artifacts only.", "Load `skills/wenyu-beginner-course/SKILL.md` and `skills/wiki-course/SKILL.md` before writing.",
    "Write a beginner workbook, not a research report.", "Use evidence only as support behind lessons.",
    "Do not materialize unrelated durable wiki pages; MoonBook owns broader wiki materialization.",
  ].join(" ")
}

///|
fn course_target_pages() -> Array[String] {
  [
    "raw/bootstrap/course-outline.md", "raw/bootstrap/deep-report.md", "wiki/synthesis/beginner-course.md",
  ]
}

///|
fn is_moontown_course_task(task : @moonbook.BookTask) -> Bool {
  let route_text = "\{task.kind} \{task.id} \{task.title}".to_lower()
  route_text.contains("course") ||
  route_text.contains("syllabus") ||
  route_text.contains("learning path") ||
  route_text.contains("beginner") ||
  route_text.contains("workbook") ||
  route_text.contains("lesson") ||
  positive_course_prompt_signal(task.prompt)
}

///|
fn positive_course_prompt_signal(prompt : String) -> Bool {
  let combined = prompt.to_lower()
  combined.contains("produce moonclaw beginner-course") ||
  combined.contains("produce beginner-course") ||
  combined.contains("produce course artifacts") ||
  combined.contains("write a beginner workbook") ||
  combined.contains("run course projection repair") ||
  combined.contains("create a course") ||
  combined.contains("build a course") ||
  combined.contains("generate a course") ||
  combined.contains("syllabus") ||
  combined.contains("learning path") ||
  combined.contains("workbook") ||
  combined.contains("lesson")
}

///|
fn is_moontown_research_bootstrap_task(task : @moonbook.BookTask) -> Bool {
  task.kind == "ingest" &&
  task.id.contains("research-bootstrap-ingest") &&
  task.prompt.to_lower().contains("research")
}

///|
fn provider_task_kind_for_book_task(task : @moonbook.BookTask) -> String {
  let combined = "\{task.kind} \{task.title} \{task.prompt}".to_lower()
  if task.kind == "ingest" && combined.contains("bootstrap") {
    "bootstrap_gather"
  } else {
    task.kind
  }
}

///|
fn packet_output_contract(lines : Array[String]) -> String {
  if lines.is_empty() {
    "Return exactly one JSON object."
  } else {
    lines.join("\n")
  }
}

///|
pub async fn save_packet_file(
  path : String,
  packet : ExternalProposalPacket,
) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(packet.to_json().stringify()),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn load_packet_file(path : String) -> ExternalProposalPacket? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text()
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
pub fn build_import_command(
  packet_path : String,
  moonclaw_root? : String = "../moonclaw",
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  confirm? : Bool = false,
  run_inline? : Bool = false,
) -> String {
  let confirm_flag = if confirm { " --confirm" } else { "" }
  let inline_flag = if confirm && run_inline { " --inline" } else { "" }
  "moon -C \{moonclaw_root} run cmd/main -- proposal import \{packet_path} --json --cwd \{cwd} --home \{home}\{confirm_flag}\{inline_flag}"
}

///|
pub fn build_run_command(
  run_id : String,
  moonclaw_root? : String = "../moonclaw",
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
) -> String {
  "moon -C \{moonclaw_root} run cmd/main -- proposal run \{run_id} --cwd \{cwd} --home \{home}"
}

///|
pub fn default_moonclaw_home() -> String {
  ".moonclaw"
}

///|
pub async fn import_packet(
  packet : ExternalProposalPacket,
  packet_path : String,
  moonclaw_root? : String = "../moonclaw",
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  confirm? : Bool = false,
  run_inline? : Bool = false,
) -> ProposalImportReceipt {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  let resolved_packet_path = resolve_packet_path(packet_path)
  save_packet_file(resolved_packet_path, packet)
  let moon = moon_command()
  let args = [
    "-C",
    moonclaw_root,
    "run",
    "cmd/main",
    "--",
    "proposal",
    "import",
    resolved_packet_path,
    "--json",
    "--cwd",
    resolved_cwd,
    "--home",
    resolved_home,
    ..if confirm {
      ["--confirm"]
    } else {
      []
    },
    ..if confirm && run_inline {
      ["--inline"]
    } else {
      []
    },
  ]
  let command = @integration.render_command(moon, args)
  let output = @integration.run_json(moon, args)
  let proposal_id = parse_json_string(output, "proposal_id").unwrap_or(
    "proposal-\{packet.packet_id}",
  )
  let run_id = parse_json_string(output, "run_id")
  {
    packet_id: packet.packet_id,
    packet_path: resolved_packet_path,
    proposal_id,
    run_id,
    status: if run_id is Some(_) {
      @core.TaskExecutionStatus::RunConfirmed
    } else {
      @core.TaskExecutionStatus::ProposalImported
    },
    command,
    summary: if run_id is Some(run_id) {
      "Imported \{packet.packet_id} into MoonClaw proposal \{proposal_id} and started run \{run_id}."
    } else {
      "Imported \{packet.packet_id} into MoonClaw proposal storage as \{proposal_id}."
    },
  }
}

///|
pub async fn import_packet_detached(
  packet : ExternalProposalPacket,
  packet_path : String,
  moonclaw_root? : String = "../moonclaw",
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  confirm? : Bool = false,
  run_inline? : Bool = false,
) -> ProposalImportReceipt {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  let resolved_packet_path = resolve_packet_path(packet_path)
  let receipt_path = detached_import_receipt_path(resolved_packet_path)
  let stderr_path = receipt_path + ".err"
  save_packet_file(resolved_packet_path, packet)
  ensure_parent_directory(receipt_path)
  let moon = moon_command()
  let args = [
    "-C",
    moonclaw_root,
    "run",
    "cmd/main",
    "--",
    "proposal",
    "import",
    resolved_packet_path,
    "--json",
    "--cwd",
    resolved_cwd,
    "--home",
    resolved_home,
    ..if confirm {
      ["--confirm"]
    } else {
      []
    },
    ..if confirm && run_inline {
      ["--inline"]
    } else {
      []
    },
  ]
  let command = @integration.render_command(moon, args)
  let shell_command = build_detached_shell_command_with_output(
    moon, args, receipt_path, stderr_path,
  )
  ignore(@integration.run_checked("/bin/zsh", ["-lc", shell_command]))
  {
    packet_id: packet.packet_id,
    packet_path: resolved_packet_path,
    proposal_id: "detached-\{packet.packet_id}",
    run_id: None,
    status: @core.TaskExecutionStatus::ProposalImported,
    command: "\{command} > \{receipt_path} 2> \{stderr_path}",
    summary: "Launched detached MoonClaw import for \{packet.packet_id}; waiting for receipt \{receipt_path}.",
  }
}

///|
pub async fn detached_import_receipt(
  packet_id : String,
  packet_path : String,
) -> ProposalImportReceipt? {
  let resolved_packet_path = resolve_packet_path(packet_path)
  let receipt_path = detached_import_receipt_path(resolved_packet_path)
  if !@fs.exists(receipt_path) {
    return None
  }
  let text = @fs.read_file(receipt_path).text() catch { _ => return None }
  let parsed = parse_json_from_command_text(text) catch {
    _ =>
      return detached_import_failure_receipt(
        packet_id, resolved_packet_path, text,
      )
  }
  let proposal_id = parse_json_string(parsed, "proposal_id").unwrap_or(
    "proposal-\{packet_id}",
  )
  let run_id = parse_json_string(parsed, "run_id")
  let receipt_status = import_receipt_status(
    run_id,
    parse_json_string(parsed, "status"),
  )
  Some({
    packet_id,
    packet_path: resolved_packet_path,
    proposal_id,
    run_id,
    status: receipt_status,
    command: "detached MoonClaw import receipt \{receipt_path}",
    summary: if receipt_status == @core.TaskExecutionStatus::Completed {
      "Detached MoonClaw import completed for \{packet_id}; inline run finished."
    } else if run_id is Some(run_id) {
      "Detached MoonClaw import completed for \{packet_id}; run \{run_id} is ready for supervision."
    } else {
      "Detached MoonClaw import completed for \{packet_id}; no run id was returned yet."
    },
  })
}

///|
fn detached_import_failure_receipt(
  packet_id : String,
  packet_path : String,
  text : String,
) -> ProposalImportReceipt? {
  if detached_import_text_is_nonterminal_log_noise(text) {
    return None
  }
  let detail = compact_detached_import_failure_text(text)
  if detail.is_empty() {
    None
  } else {
    Some({
      packet_id,
      packet_path,
      proposal_id: "proposal-\{packet_id}",
      run_id: None,
      status: @core.TaskExecutionStatus::Failed,
      command: "detached MoonClaw import failure receipt \{detached_import_receipt_path(packet_path)}",
      summary: "Detached MoonClaw import failed for \{packet_id}: \{detail}",
    })
  }
}

///|
fn detached_import_text_is_nonterminal_log_noise(text : String) -> Bool {
  if detached_import_text_is_only_runtime_event_logs(text) {
    return true
  }
  let lowered = text.to_lower()
  let has_startup_log = lowered.contains("\"tag\":\"model\"") ||
    lowered.contains("\"tag\":\"job-analysis\"") ||
    lowered.contains("loading skills from directory") ||
    lowered.contains("loaded skill")
  let has_runtime_event = lowered.contains("\"msg\":\"received event\"") ||
    lowered.contains("\"msg\":\"tokencounted\"") ||
    lowered.contains("\"msg\":\"contextpruned\"")
  (has_startup_log || has_runtime_event) &&
  !detached_import_text_has_top_level_terminal_failure_signal(text)
}

///|
fn detached_import_text_is_only_runtime_event_logs(text : String) -> Bool {
  let mut saw_log = false
  for raw in text.split("\n") {
    let line = raw.trim()
    if line.is_empty() {
      continue
    }
    let parsed = @json.parse(line) catch { _ => return false }
    if !json_looks_like_moonclaw_runtime_log(parsed) {
      return false
    }
    if json_runtime_log_has_terminal_failure_signal(parsed) {
      return false
    }
    saw_log = true
  }
  saw_log
}

///|
fn detached_import_text_has_top_level_terminal_failure_signal(
  text : String,
) -> Bool {
  for raw in text.split("\n") {
    let line = raw.trim()
    if line.is_empty() {
      continue
    }
    let parsed = @json.parse(line) catch {
      _ =>
        if detached_import_non_json_line_has_terminal_failure_signal(
            line.to_owned().to_lower(),
          ) {
          return true
        } else {
          continue
        }
    }
    if json_looks_like_moonclaw_runtime_log(parsed) {
      if json_runtime_log_has_terminal_failure_signal(parsed) {
        return true
      }
    } else if !json_looks_like_import_receipt(parsed) &&
      detached_import_non_json_line_has_terminal_failure_signal(
        line.to_owned().to_lower(),
      ) {
      return true
    }
  }
  false
}

///|
fn detached_import_non_json_line_has_terminal_failure_signal(
  lowered : String,
) -> Bool {
  detached_import_text_has_terminal_failure_signal(lowered)
}

///|
fn json_looks_like_moonclaw_runtime_log(json : Json) -> Bool {
  match json {
    Object(object) =>
      object.get("level") is Some(_) &&
      object.get("msg") is Some(_) &&
      object.get("tag") is Some(_)
    _ => false
  }
}

///|
fn json_runtime_log_has_terminal_failure_signal(json : Json) -> Bool {
  match parse_json_string(json, "msg") {
    Some(message) =>
      detached_import_text_has_terminal_failure_signal(message.to_lower())
    None => false
  }
}

///|
fn detached_import_text_has_terminal_failure_signal(lowered : String) -> Bool {
  lowered.contains("failure(") ||
  lowered.contains(" failed:") ||
  lowered.contains("runtime error") ||
  lowered.contains("jsondecodeerror") ||
  lowered.contains("abort() called") ||
  lowered.contains("panic")
}

///|
fn compact_detached_import_failure_text(text : String) -> String {
  let builder = StringBuilder::new()
  let mut count = 0
  for raw in text.split("\n") {
    if count >= 6 {
      break
    }
    let line = raw.trim()
    if line.is_empty() {
      continue
    }
    if count > 0 {
      builder.write_string(" | ")
    }
    builder.write_string(line.to_owned())
    count += 1
  }
  builder.to_string()
}

///|
fn import_receipt_status(
  run_id : String?,
  status_text : String?,
) -> @core.TaskExecutionStatus {
  match status_text.map(fn(text) { text.to_lower() }) {
    Some("succeeded") | Some("completed") =>
      @core.TaskExecutionStatus::Completed
    Some("failed") => @core.TaskExecutionStatus::Failed
    _ =>
      if run_id is Some(_) {
        @core.TaskExecutionStatus::RunConfirmed
      } else {
        @core.TaskExecutionStatus::ProposalImported
      }
  }
}

///|
pub fn detached_import_receipt_path(packet_path : String) -> String {
  resolve_packet_path(packet_path) + ".import.json"
}

///|
pub fn confirm_imported_run(
  receipt : ProposalImportReceipt,
) -> ProposalImportReceipt {
  {
    ..receipt,
    run_id: Some(receipt.run_id.unwrap_or("run-\{receipt.packet_id}")),
    status: @core.TaskExecutionStatus::RunConfirmed,
    summary: "Confirmed proposal \{receipt.proposal_id} into a live run.",
  }
}

///|
pub async fn run_confirmed_run(
  run_id : String,
  moonclaw_root? : String = "../moonclaw",
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
) -> String {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  let moon = moon_command()
  let args = [
    "-C", moonclaw_root, "run", "cmd/main", "--", "proposal", "run", run_id, "--cwd",
    resolved_cwd, "--home", resolved_home,
  ]
  let command = @integration.render_command(moon, args)
  let shell_command = build_detached_shell_command(moon, args)
  ignore(@integration.run_checked("/bin/zsh", ["-lc", shell_command]))
  command
}

///|
fn moon_command() -> String {
  match @sys.get_env_var("MOON_BIN") {
    Some(value) if !value.is_empty() => value
    _ =>
      match @sys.get_env_var("HOME") {
        Some(home) if !home.is_empty() => home + "/.moon/bin/moon"
        _ => "moon"
      }
  }
}

///|
fn build_detached_shell_command(
  command : String,
  args : Array[String],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("nohup ")
  builder.write_string(shell_quote(command))
  for arg in args {
    builder.write_char(' ')
    builder.write_string(shell_quote(arg))
  }
  builder.write_string(" >/dev/null 2>&1 &")
  builder.to_string()
}

///|
fn build_detached_shell_command_with_output(
  command : String,
  args : Array[String],
  stdout_path : String,
  stderr_path : String,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("nohup ")
  builder.write_string(shell_quote(command))
  for arg in args {
    builder.write_char(' ')
    builder.write_string(shell_quote(arg))
  }
  builder.write_string(" >")
  builder.write_string(shell_quote(stdout_path))
  builder.write_string(" 2>")
  builder.write_string(shell_quote(stderr_path))
  builder.write_string(" &")
  builder.to_string()
}

///|
fn shell_quote(text : String) -> String {
  let escaped = text.replace(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
pub async fn poll_run(
  task_id : String,
  run_id : String,
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
  detect_orphan? : Bool = true,
) -> ProposalPollResponse {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  match load_run(run_id, resolved_home) {
    Some(run) => {
      let workspace_dir = run.workspace_dir.unwrap_or(resolved_cwd)
      let result_payload = load_run_result_payload(workspace_dir)
      let indexed_status = town_status_for_run_status(run.status)
      let orphaned = detect_orphan &&
        orphan_detectable_run_status(indexed_status) &&
        !moonclaw_run_process_alive(run.id)
      let status = if orphaned {
        @core.TaskExecutionStatus::Failed
      } else {
        indexed_status
      }
      let result_decision = parse_json_string(result_payload, "result_decision").unwrap_or(
        if status == @core.TaskExecutionStatus::Failed {
          "blocked"
        } else if status == @core.TaskExecutionStatus::Completed {
          "accepted"
        } else {
          "pending"
        },
      )
      {
        task_id,
        run_id,
        status,
        summary: if orphaned {
          "MoonClaw run \{run.id} is indexed as Running, but no live proposal process was found; treating it as failed for mayor recovery."
        } else {
          run_summary(run, result_payload)
        },
        memory_candidates: [],
        result_decision,
        requires_review: parse_json_bool(result_payload, "requires_review").unwrap_or(
          false,
        ),
        notify_town: parse_json_bool(result_payload, "notify_town").unwrap_or(
          status == @core.TaskExecutionStatus::Completed,
        ),
      }
    }
    None =>
      {
        task_id,
        run_id,
        status: @core.TaskExecutionStatus::Running,
        summary: "Run \{run_id} has not been indexed in MoonClaw yet.",
        memory_candidates: [],
        result_decision: "pending",
        requires_review: false,
        notify_town: false,
      }
  }
}

///|
fn orphan_detectable_run_status(status : @core.TaskExecutionStatus) -> Bool {
  status == @core.TaskExecutionStatus::RunConfirmed ||
  status == @core.TaskExecutionStatus::Running
}

///|
pub async fn run_workspace_dir(
  run_id : String,
  home? : String = default_moonclaw_home(),
  cwd? : String = ".",
) -> String? {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  load_run(run_id, resolved_home).bind(fn(run) { run.workspace_dir })
}

///|
pub async fn run_process_alive(run_id : String) -> Bool {
  moonclaw_run_process_alive(run_id)
}

///|
async fn moonclaw_run_process_alive(run_id : String) -> Bool {
  let listed = @integration.run_checked("ps", ["-ef"]) catch {
    _ => return true
  }
  let needle = "proposal run \{run_id}"
  for line in listed.stdout.split("\n") {
    if line.contains(needle) {
      return true
    }
  }
  false
}

///|
fn parse_json_string(json : Json, key : String) -> String? {
  match json {
    Object(object) =>
      match object.get(key) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn parse_json_bool(json : Json, key : String) -> Bool? {
  match json {
    Object(object) =>
      match object.get(key) {
        Some(True) => Some(true)
        Some(False) => Some(false)
        _ => None
      }
    _ => None
  }
}

///|
fn parse_json_from_command_text(text : String) -> Json raise {
  let trimmed = text.trim().to_owned()
  let whole = @json.parse(trimmed) catch {
    _ => {
      let lines = trimmed.split("\n").to_array()
      let count = lines.length()
      for offset in 0..<count {
        let start = count - offset - 1
        let line = lines[start].trim().to_owned()
        if line.has_prefix("{") || line.has_prefix("[") {
          let builder = StringBuilder::new()
          for index in start..<count {
            if index > start {
              builder.write_char('\n')
            }
            builder.write_string(lines[index].to_owned())
          }
          let candidate = builder.to_string()
          let parsed = @json.parse(candidate) catch { _ => continue }
          if json_looks_like_import_receipt(parsed) {
            return parsed
          }
          let single = @json.parse(line) catch { _ => continue }
          if json_looks_like_import_receipt(single) {
            return single
          }
        }
      }
      raise Failure::Failure("Expected JSON output in command text.")
    }
  }
  if json_looks_like_import_receipt(whole) {
    whole
  } else {
    raise Failure::Failure("Expected MoonClaw import receipt JSON.")
  }
}

///|
fn json_looks_like_import_receipt(json : Json) -> Bool {
  match json {
    Object(object) =>
      object.get("proposal_id") is Some(_) ||
      object.get("run_id") is Some(_) ||
      object.get("status") is Some(_)
    _ => false
  }
}

///|
fn resolve_packet_path(packet_path : String) -> String {
  resolve_root_path(packet_path)
}

///|
fn resolve_root_path(path : String) -> String {
  if path.has_prefix("/") {
    path
  } else {
    match @env.current_dir() {
      Some(dir) => @path.Path(dir).join(@path.Path(path)).to_string()
      None => path
    }
  }
}

///|
fn resolve_home_path(home : String, cwd : String) -> String {
  if home.has_prefix("/") {
    home
  } else {
    @path.Path(cwd).join(@path.Path(home)).to_string()
  }
}

///|
fn run_store_root(home : String) -> String {
  @path.Path(home).join(@path.Path("jobs")).to_string()
}

///|
async fn load_run(run_id : String, home : String) -> StoredRun? {
  let path = @path.Path(run_store_root(home))
    .join(@path.Path("index/runs.json"))
    .to_string()
  let indexed = if @fs.exists(path) {
    let text = @fs.read_file(path).text() catch { _ => "" }
    let parsed = @json.parse(text) catch { _ => {} }
    let index : RunsIndexFile = @json.from_json(parsed) catch {
      _ => { runs: [] }
    }
    index.runs.iter().find_first(fn(run) { run.id == run_id })
  } else {
    None
  }
  match load_run_meta(run_id, home) {
    Some(meta) => Some(meta)
    None => indexed
  }
}

///|
async fn load_run_meta(run_id : String, home : String) -> StoredRun? {
  let path = @path.Path(run_store_root(home))
    .join(@path.Path("runs"))
    .join(@path.Path(run_id))
    .join(@path.Path("meta.json"))
    .to_string()
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text() catch { _ => return None }
  let parsed = @json.parse(text) catch { _ => return None }
  let meta : StoredRun = @json.from_json(parsed) catch { _ => return None }
  if meta.id == run_id {
    Some(meta)
  } else {
    None
  }
}

///|
async fn load_run_result_payload(workspace_dir : String) -> Json {
  let path = @path.Path(workspace_dir)
    .join(@path.Path("result.json"))
    .to_string()
  if !@fs.exists(path) {
    return {}
  }
  let text = @fs.read_file(path).text() catch { _ => return {} }
  @json.parse(text) catch {
    _ => {}
  }
}

///|
fn town_status_for_run_status(status : String) -> @core.TaskExecutionStatus {
  match status {
    "Pending" => @core.TaskExecutionStatus::RunConfirmed
    "Running" => @core.TaskExecutionStatus::Running
    "WaitingForInput" => @core.TaskExecutionStatus::Running
    "Succeeded" => @core.TaskExecutionStatus::Completed
    "Failed" => @core.TaskExecutionStatus::Failed
    "Cancelled" => @core.TaskExecutionStatus::Failed
    _ => @core.TaskExecutionStatus::Running
  }
}

///|
fn run_summary(run : StoredRun, result_payload : Json) -> String {
  let detail = parse_json_string(result_payload, "summary").unwrap_or(
    run.summary.unwrap_or(""),
  )
  let workspace_suffix = match run.workspace_dir {
    Some(workspace_dir) => " workspace=\{workspace_dir}"
    None => ""
  }
  match run.status {
    "Succeeded" =>
      if detail.is_blank() {
        "MoonClaw run \{run.id} completed successfully.\{workspace_suffix}"
      } else {
        "MoonClaw run \{run.id} completed: \{detail}\{workspace_suffix}"
      }
    "Failed" | "Cancelled" =>
      "MoonClaw run \{run.id} failed: \{run.error.unwrap_or(detail).trim().to_owned()}\{workspace_suffix}"
    "WaitingForInput" =>
      "MoonClaw run \{run.id} is waiting for input.\{workspace_suffix}"
    _ =>
      if detail.is_blank() {
        "MoonClaw run \{run.id} is \{run.status}.\{workspace_suffix}"
      } else {
        "MoonClaw run \{run.id} is \{run.status}: \{detail}\{workspace_suffix}"
      }
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
      "skills/mayor-goal-decomposition/SKILL.md", "skills/mayor-supervision/SKILL.md",
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

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}
