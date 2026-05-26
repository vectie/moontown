///|
pub struct VisualAgentProjection {
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
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct VisualBuildingProjection {
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
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct VisualModuleProjection {
  module_id : String
  book_id : String
  title : String
  status : String
  source : String
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
  active_agent_count : Int
  effect : String
  message : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct VisualProjection {
  tick : Int
  agents : Array[VisualAgentProjection]
  buildings : Array[VisualBuildingProjection]
  modules : Array[VisualModuleProjection]
  messages : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn build_visual_projection(
  state : @core.TownState,
  tick? : Int = visual_projection_tick(state),
) -> VisualProjection {
  let agents : Array[VisualAgentProjection] = []
  for worker in state.workers {
    agents.push(visual_agent_projection(state, worker))
  }
  let buildings : Array[VisualBuildingProjection] = []
  for book in state.books {
    buildings.push(visual_building_projection(state, book))
  }
  let modules : Array[VisualModuleProjection] = []
  for building in buildings {
    modules.push(visual_module_projection(building, agents))
  }
  {
    tick,
    agents,
    buildings,
    modules,
    messages: visual_projection_messages(state, agents, buildings),
  }
}

///|
pub fn default_visual_projection_path(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/visual-projection.json"
  } else {
    "\{base}/visual-projection.json"
  }
}

///|
pub async fn persist_visual_projection(
  state : @core.TownState,
  snapshot_path : String,
  tick? : Int = visual_projection_tick(state),
) -> Unit {
  let projection = build_visual_projection(state, tick~)
  write_text_file(
    default_visual_projection_path(snapshot_path),
    projection.to_json().stringify(),
  )
}

///|
fn visual_agent_projection(
  state : @core.TownState,
  worker : @core.WorkerRef,
) -> VisualAgentProjection {
  let execution = visual_latest_execution_for_worker(state, worker)
  let phase = visual_agent_phase(worker, execution)
  let status = visual_worker_status(worker.status)
  let book_title = visual_book_title(state, worker.book_id)
  let task_id = execution.map(fn(record) { record.task_id })
  let task_title = task_id.map(fn(id) { visual_task_title(state, id) })
  let run_id = match execution {
    Some(record) => record.run_id
    None => None
  }
  let grid = visual_agent_grid(worker.book_id, worker.id, phase)
  {
    worker_id: worker.id,
    worker_name: worker.name,
    book_id: worker.book_id,
    book_title,
    role: worker.role.to_string(),
    status,
    phase,
    task_id,
    task_title,
    run_id,
    sprite_key: visual_sprite_key(worker.id),
    zone_key: visual_zone_key(worker.book_id, phase, worker.status),
    location: visual_location_label(worker.book_id, phase),
    destination: visual_destination_label(worker.book_id, phase),
    behavior: visual_behavior_for_phase(phase),
    effect: visual_effect_for_phase(phase),
    visible_on_overworld: visual_agent_visible_on_overworld(phase),
    message: visual_agent_message(worker, book_title, task_title, phase),
    grid_x: grid.0,
    grid_y: grid.1,
    z: grid.0 + grid.1,
  }
}

///|
fn visual_building_projection(
  state : @core.TownState,
  book : @core.BookRef,
) -> VisualBuildingProjection {
  let running = visual_count_book_phases(state, book.id, [
    "running", "persisting",
  ])
  let waiting = visual_count_book_phases(state, book.id, [
    "packet", "importing", "waiting",
  ])
  let review = visual_count_book_phases(state, book.id, ["review"])
  let blocked = visual_count_book_phases(state, book.id, [
    "blocked", "failed", "stale",
  ])
  let completed = visual_count_book_phases(state, book.id, ["completed", "idle"])
  let effect = if blocked > 0 {
    "alert-pulse"
  } else if review > 0 {
    "review-glow"
  } else if running > 0 {
    "work-particles"
  } else if waiting > 0 {
    "packet-pulse"
  } else {
    "none"
  }
  {
    book_id: book.id,
    title: book.name,
    zone_key: "book-\{book.id}",
    running_count: running,
    waiting_count: waiting,
    review_count: review,
    blocked_count: blocked,
    completed_count: completed,
    effect,
    message: visual_building_message(book, running, waiting, review, blocked),
  }
}

///|
fn visual_module_projection(
  building : VisualBuildingProjection,
  agents : Array[VisualAgentProjection],
) -> VisualModuleProjection {
  let status = if building.blocked_count > 0 {
    "alert"
  } else if building.review_count > 0 {
    "review"
  } else if building.running_count > 0 {
    "running"
  } else if building.waiting_count > 0 {
    "waiting"
  } else if building.completed_count > 0 {
    "complete"
  } else {
    "calm"
  }
  {
    module_id: visual_module_id_from_book_id(building.book_id),
    book_id: building.book_id,
    title: building.title,
    status,
    source: "runtime",
    running_count: building.running_count,
    waiting_count: building.waiting_count,
    review_count: building.review_count,
    blocked_count: building.blocked_count,
    completed_count: building.completed_count,
    active_agent_count: agents
    .filter(fn(agent) {
      agent.book_id == building.book_id && agent.visible_on_overworld
    })
    .length(),
    effect: building.effect,
    message: building.message,
  }
}

///|
fn visual_module_id_from_book_id(book_id : String) -> String {
  let prefix = "wenyu-"
  if book_id.length() > prefix.length() &&
    book_id[:prefix.length()].to_owned() == prefix {
    book_id[prefix.length():].to_owned()
  } else {
    book_id
  }
}

///|
fn visual_projection_tick(state : @core.TownState) -> Int {
  let mut tick = state.events.length()
  for execution in state.executions {
    if execution.heartbeat_tick > tick {
      tick = execution.heartbeat_tick
    }
  }
  tick
}

///|
fn visual_latest_execution_for_worker(
  state : @core.TownState,
  worker : @core.WorkerRef,
) -> @core.TaskExecutionRecord? {
  let mut matched : @core.TaskExecutionRecord? = None
  for execution in state.executions {
    match execution.assigned_worker_id {
      Some(worker_id) => if worker_id == worker.id { matched = Some(execution) }
      None => ()
    }
  }
  match matched {
    Some(record) => Some(record)
    None =>
      if worker.status == @core.WorkerStatus::Running ||
        worker.status == @core.WorkerStatus::Waiting {
        visual_latest_book_execution_without_worker(state, worker.book_id)
      } else {
        None
      }
  }
}

///|
fn visual_latest_book_execution_without_worker(
  state : @core.TownState,
  book_id : String,
) -> @core.TaskExecutionRecord? {
  let mut matched : @core.TaskExecutionRecord? = None
  for execution in state.executions {
    if execution.book_id == book_id &&
      execution.assigned_worker_id == None &&
      visual_execution_is_live(execution.status) {
      matched = Some(execution)
    }
  }
  matched
}

///|
fn visual_execution_is_live(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::PacketReady
    | @core.TaskExecutionStatus::ProposalImported
    | @core.TaskExecutionStatus::RunConfirmed
    | @core.TaskExecutionStatus::Running
    | @core.TaskExecutionStatus::AwaitingPersistence
    | @core.TaskExecutionStatus::ReviewQueued
    | @core.TaskExecutionStatus::Stale
    | @core.TaskExecutionStatus::Failed => true
    @core.TaskExecutionStatus::Completed => false
  }
}

///|
fn visual_agent_phase(
  worker : @core.WorkerRef,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(record) => visual_phase_for_execution(record.status)
    None =>
      match worker.status {
        @core.WorkerStatus::Running => "running"
        @core.WorkerStatus::Waiting => "waiting"
        @core.WorkerStatus::Idle => "idle"
        @core.WorkerStatus::Blocked => "blocked"
        @core.WorkerStatus::Offline => "offline"
      }
  }
}

///|
fn visual_phase_for_execution(status : @core.TaskExecutionStatus) -> String {
  match status {
    @core.TaskExecutionStatus::PacketReady => "packet"
    @core.TaskExecutionStatus::ProposalImported => "importing"
    @core.TaskExecutionStatus::RunConfirmed => "running"
    @core.TaskExecutionStatus::Running => "running"
    @core.TaskExecutionStatus::AwaitingPersistence => "persisting"
    @core.TaskExecutionStatus::ReviewQueued => "review"
    @core.TaskExecutionStatus::Completed => "completed"
    @core.TaskExecutionStatus::Stale => "stale"
    @core.TaskExecutionStatus::Failed => "failed"
  }
}

///|
fn visual_worker_status(status : @core.WorkerStatus) -> String {
  match status {
    @core.WorkerStatus::Idle => "idle"
    @core.WorkerStatus::Running => "running"
    @core.WorkerStatus::Waiting => "waiting"
    @core.WorkerStatus::Blocked => "blocked"
    @core.WorkerStatus::Offline => "offline"
  }
}

///|
fn visual_count_book_phases(
  state : @core.TownState,
  book_id : String,
  phases : Array[String],
) -> Int {
  let mut count = 0
  for worker in state.workers {
    if worker.book_id == book_id {
      let phase = visual_agent_phase(
        worker,
        visual_latest_execution_for_worker(state, worker),
      )
      for expected in phases {
        if phase == expected {
          count += 1
          break
        }
      }
    }
  }
  count
}

///|
fn visual_book_title(state : @core.TownState, book_id : String) -> String {
  for book in state.books {
    if book.id == book_id {
      return book.name
    }
  }
  book_id
}

///|
fn visual_task_title(state : @core.TownState, task_id : String) -> String {
  match @core.find_task(state, task_id) {
    Some(task) => task.title
    None => task_id
  }
}

///|
fn visual_zone_key(
  book_id : String,
  phase : String,
  status : @core.WorkerStatus,
) -> String {
  if phase == "failed" ||
    phase == "stale" ||
    phase == "blocked" ||
    status == @core.WorkerStatus::Blocked {
    "anomaly-corner"
  } else if phase == "packet" || phase == "importing" {
    "city-hall"
  } else if phase == "waiting" {
    "worker-yard"
  } else if status == @core.WorkerStatus::Offline {
    "gate"
  } else {
    "book-\{book_id}"
  }
}

///|
fn visual_location_label(book_id : String, phase : String) -> String {
  if phase == "packet" || phase == "importing" {
    "city-hall"
  } else if phase == "waiting" {
    "worker-yard"
  } else if phase == "failed" || phase == "stale" || phase == "blocked" {
    "anomaly-corner"
  } else {
    "book-\{book_id}"
  }
}

///|
fn visual_destination_label(book_id : String, phase : String) -> String {
  if phase == "packet" || phase == "importing" || phase == "waiting" {
    "book-\{book_id}"
  } else if phase == "persisting" || phase == "review" {
    "keeper-desk-\{book_id}"
  } else if phase == "failed" || phase == "stale" || phase == "blocked" {
    "recovery-yard"
  } else {
    "inside-\{book_id}"
  }
}

///|
fn visual_behavior_for_phase(phase : String) -> String {
  match phase {
    "packet" => "queueing"
    "importing" => "handoff"
    "running" => "working"
    "persisting" => "carrying-memory"
    "review" => "reviewing"
    "failed" => "recovering"
    "stale" => "recovering"
    "blocked" => "recovering"
    "waiting" => "waiting"
    "offline" => "offline"
    _ => "inside-idle"
  }
}

///|
fn visual_effect_for_phase(phase : String) -> String {
  match phase {
    "packet" => "packet-pulse"
    "importing" => "packet-pulse"
    "running" => "work-particles"
    "persisting" => "memory-glow"
    "review" => "review-glow"
    "failed" => "alert-pulse"
    "stale" => "alert-pulse"
    "blocked" => "alert-pulse"
    "waiting" => "packet-pulse"
    _ => "none"
  }
}

///|
fn visual_agent_visible_on_overworld(phase : String) -> Bool {
  match phase {
    "packet"
    | "importing"
    | "running"
    | "persisting"
    | "failed"
    | "stale"
    | "blocked"
    | "waiting"
    | "review" => true
    _ => false
  }
}

///|
fn visual_agent_message(
  worker : @core.WorkerRef,
  book_title : String,
  task_title : String?,
  phase : String,
) -> String {
  let work = task_title.unwrap_or(book_title)
  match phase {
    "packet" => "\{worker.name} is receiving the town handoff for \{work}."
    "importing" => "\{worker.name} is importing the packet before work starts."
    "running" => "\{worker.name} is actively working on \{work}."
    "persisting" =>
      "\{worker.name} is carrying results back to MoonBook memory."
    "review" => "\{worker.name} is inside the book review room."
    "failed" => "\{worker.name} needs mayor recovery for \{work}."
    "stale" => "\{worker.name} is stale and should be recovered."
    "blocked" => "\{worker.name} is blocked and visible in anomaly triage."
    "waiting" => "\{worker.name} is queued for the next supervised handoff."
    "offline" => "\{worker.name} is offline."
    _ => "\{worker.name} is inside \{book_title}."
  }
}

///|
fn visual_building_message(
  book : @core.BookRef,
  running : Int,
  waiting : Int,
  review : Int,
  blocked : Int,
) -> String {
  if blocked > 0 {
    "\{book.name} needs recovery for \{blocked} blocked or failed worker(s)."
  } else if review > 0 {
    "\{book.name} has \{review} worker(s) in review."
  } else if running > 0 {
    "\{book.name} has \{running} active worker(s)."
  } else if waiting > 0 {
    "\{book.name} has \{waiting} worker(s) waiting for handoff."
  } else {
    "\{book.name} is quiet; idle workers stay inside until selected."
  }
}

///|
fn visual_projection_messages(
  state : @core.TownState,
  agents : Array[VisualAgentProjection],
  buildings : Array[VisualBuildingProjection],
) -> Array[String] {
  let running = agents.filter(fn(agent) { agent.phase == "running" }).length()
  let visible = agents.filter(fn(agent) { agent.visible_on_overworld }).length()
  let blocked = buildings
    .filter(fn(building) { building.blocked_count > 0 })
    .length()
  [
    "\{visible} visible worker(s), \{running} actively running, \{state.executions.length()} execution record(s).",
    if blocked > 0 {
      "\{blocked} book building(s) need mayor recovery."
    } else {
      "No blocked book buildings in the current visual projection."
    },
  ]
}

///|
fn visual_agent_grid(
  book_id : String,
  worker_id : String,
  phase : String,
) -> (Int, Int) {
  if phase == "failed" || phase == "stale" || phase == "blocked" {
    return (142, 72)
  }
  if phase == "packet" || phase == "importing" {
    return (116, 70)
  }
  if phase == "waiting" {
    return (104, 84)
  }
  let seed = visual_hash("\{book_id}/\{worker_id}")
  let base = visual_book_grid(book_id, seed)
  let wiggle_x = seed % 7 - 3
  let wiggle_y = seed / 7 % 7 - 3
  (
    visual_clamp_grid_x(base.0 + wiggle_x),
    visual_clamp_grid_y(base.1 + wiggle_y),
  )
}

///|
fn visual_book_grid(book_id : String, seed : Int) -> (Int, Int) {
  match book_id {
    "research-opc" => (104, 78)
    "research-llm-training-detail" => (112, 72)
    "research-euv-lithography-machine-new-advantages-and-supplements" =>
      (124, 64)
    "research-moontown" => (112, 76)
    "research-moonbook" => (120, 70)
    "research-moonclaw" => (128, 76)
    "wenyu-town-shell" => (116, 78)
    "wenyu-resident-twins" => (96, 86)
    "wenyu-policy-hall" => (136, 64)
    "wenyu-contest-express" => (150, 82)
    "wenyu-social-square" => (104, 68)
    "wenyu-talent-avenue" => (92, 76)
    "wenyu-vitality-dashboard" => (132, 86)
    "wenyu-ai-garden" => (118, 92)
    "wenyu-physical-bridge" => (154, 92)
    _ => (72 + seed % 104, 42 + seed / 11 % 58)
  }
}

///|
fn visual_sprite_key(worker_id : String) -> String {
  "resident_\{visual_hash(worker_id) % 64}"
}

///|
fn visual_hash(text : String) -> Int {
  let mut value = 17
  for char in text {
    value = (value * 31 + char.to_int()) % 1_000_003
  }
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn visual_clamp_grid_x(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn visual_clamp_grid_y(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 143 {
    143
  } else {
    value
  }
}
