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
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct ProposalImportReceipt {
  packet_id : String
  packet_path : String
  proposal_id : String
  run_id : String?
  status : @core.TaskExecutionStatus
  command : String
  summary : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct ProposalPollResponse {
  task_id : String
  run_id : String
  status : @core.TaskExecutionStatus
  summary : String
  memory_candidates : Array[String]
  requires_review : Bool
  notify_town : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
struct RunsIndexFile {
  runs : Array[StoredRun]
} derive(Show, Eq, ToJson, FromJson)

///|
struct StoredRun {
  id : String
  workspace_dir : String?
  status : String
  summary : String?
  error : String?
} derive(Show, Eq, ToJson, FromJson)

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
      "step_metadata": {
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
      },
    },
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
) -> String {
  let confirm_flag = if confirm { " --confirm" } else { "" }
  "moon -C \{moonclaw_root} run cmd/main -- proposal import \{packet_path} --json --cwd \{cwd} --home \{home}\{confirm_flag}"
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
) -> ProposalImportReceipt {
  let resolved_cwd = resolve_root_path(cwd)
  let resolved_home = resolve_home_path(home, resolved_cwd)
  let resolved_packet_path = resolve_packet_path(packet_path)
  save_packet_file(resolved_packet_path, packet)
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
  ]
  let command = @integration.render_command("moon", args)
  let output = @integration.run_json("moon", args)
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
  let args = [
    "-C", moonclaw_root, "run", "cmd/main", "--", "proposal", "run", run_id, "--cwd",
    resolved_cwd, "--home", resolved_home,
  ]
  let command = @integration.render_command("moon", args)
  let shell_command = build_detached_shell_command("moon", args)
  ignore(@integration.run_checked("/bin/zsh", ["-lc", shell_command]))
  command
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
        indexed_status == @core.TaskExecutionStatus::Running &&
        !moonclaw_run_process_alive(run.id)
      let status = if orphaned {
        @core.TaskExecutionStatus::Failed
      } else {
        indexed_status
      }
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
        requires_review: false,
        notify_town: false,
      }
  }
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
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text()
  let parsed = @json.parse(text) catch { _ => return None }
  let index : RunsIndexFile = @json.from_json(parsed) catch { _ => return None }
  index.runs.iter().find_first(fn(run) { run.id == run_id })
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
      "MoonClaw run \{run.id} failed: \{run.error.unwrap_or(detail).trim().to_string()}\{workspace_suffix}"
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
