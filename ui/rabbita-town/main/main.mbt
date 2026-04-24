///|
using @html {
  article,
  aside,
  button,
  div,
  h1,
  h2,
  h3,
  header,
  img,
  main_,
  p,
  section,
  span,
}

///|
using @rabbita {type Cmd, type Dispatch}

///|
priv enum Strategy {
  Balanced
  Throughput
  Recovery
} derive(Eq)

///|
priv enum Selection {
  Overview
  Node(String)
  Worker(String)
}

///|
priv enum StateSourceKind {
  DemoSimulation
  SnapshotFile
} derive(Eq)

///|
priv struct Model {
  tick : Int
  paused : Bool
  strategy : Strategy
  selection : Selection
  state_source : StateSourceKind
  budget : Int
  energy : Int
  pressure : Int
  stability : Int
}

///|
priv enum Msg {
  Tick
  TogglePause
  Step
  SelectWorker(String)
  SelectNode(String)
  SelectOverview
  SetStrategy(Strategy)
  ToggleStateSource
  InjectBudget
  RelieveQueue
  StabilityDrill
}

///|
priv struct WorkerSim {
  id : String
  title : String
  role : String
  book_id : String
  status : @core.WorkerStatus
  zone_key : String
  energy : Int
  load : Int
  summary : String
}

///|
priv struct FeedItem {
  title : String
  detail : String
  tone : String
}

///|
priv struct ResidentSim {
  name : String
  venture : String
  need : String
  mood : String
  agent_goal : String
  memory : String
  plan : String
  zone : String
}

///|
priv struct CivicQuestSim {
  title : String
  area : String
  stage : String
  reward : String
  status : String
}

///|
priv struct SocialMatchSim {
  left : String
  right : String
  reason : String
  next_step : String
  confidence : Int
}

///|
priv struct TalentSignalSim {
  name : String
  domain : String
  skills : String
  activity : Int
}

///|
fn init_model() -> Model {
  {
    tick: 0,
    paused: false,
    strategy: Strategy::Balanced,
    selection: Selection::Overview,
    state_source: StateSourceKind::DemoSimulation,
    budget: 76,
    energy: 68,
    pressure: 34,
    stability: 78,
  }
}

///|
fn schedule_tick(dispatch : Dispatch[Msg]) -> Cmd {
  @rabbita.delay(dispatch(Tick), 1200)
}

///|
fn update(dispatch : Dispatch[Msg], msg : Msg, model : Model) -> (Cmd, Model) {
  match msg {
    Tick => {
      let next = advance_model(model)
      let cmd = if next.paused {
        @rabbita.none
      } else {
        schedule_tick(dispatch)
      }
      (cmd, next)
    }
    TogglePause => {
      let next = { ..model, paused: !model.paused }
      let cmd = if next.paused {
        @rabbita.none
      } else {
        schedule_tick(dispatch)
      }
      (cmd, next)
    }
    Step =>
      if model.paused {
        (@rabbita.none, advance_model(model))
      } else {
        (@rabbita.none, model)
      }
    SelectWorker(worker_id) =>
      (@rabbita.none, { ..model, selection: Worker(worker_id) })
    SelectNode(node_key) =>
      (@rabbita.none, { ..model, selection: Node(node_key) })
    SelectOverview => (@rabbita.none, { ..model, selection: Overview })
    SetStrategy(strategy) => (@rabbita.none, { ..model, strategy, })
    ToggleStateSource =>
      (
        @rabbita.none,
        { ..model, state_source: next_state_source(model.state_source) },
      )
    InjectBudget =>
      (
        @rabbita.none,
        {
          ..model,
          budget: clamp_metric(model.budget + 14),
          pressure: clamp_metric(model.pressure - 6),
          energy: clamp_metric(model.energy + 3),
        },
      )
    RelieveQueue =>
      (
        @rabbita.none,
        {
          ..model,
          pressure: clamp_metric(model.pressure - 16),
          energy: clamp_metric(model.energy - 2),
          stability: clamp_metric(model.stability + 4),
        },
      )
    StabilityDrill =>
      (
        @rabbita.none,
        {
          ..model,
          stability: clamp_metric(model.stability + 15),
          energy: clamp_metric(model.energy + 5),
          budget: clamp_metric(model.budget - 7),
        },
      )
  }
}

///|
fn advance_model(model : Model) -> Model {
  let recovery_active = mayor_recovery_active(model)
  let budget_delta = match model.strategy {
    Balanced => -2
    Throughput => -4
    Recovery => -1
  }
  let energy_delta = match model.strategy {
    Balanced => -1
    Throughput => -4
    Recovery => 2
  }
  let pressure_delta = match model.strategy {
    Balanced => 1
    Throughput => 5
    Recovery => -3
  }
  let stability_delta = match model.strategy {
    Balanced => 0
    Throughput => -3
    Recovery => 3
  }
  let overload_penalty = if model.pressure > 70 { 4 } else { 0 }
  let brittle_penalty = if model.stability < 35 { 3 } else { 0 }
  let budget_penalty = if model.budget < 24 { 2 } else { 0 }
  let energy_penalty = if model.energy < 28 { 3 } else { 0 }
  let budget_bonus = if model.tick % 6 == 0 { 2 } else { 0 }
  let energy_bonus = if model.tick % 5 == 0 { 1 } else { 0 }
  let pressure_relief = if model.tick % 4 == 0 { 1 } else { 0 }
  let stability_bonus = if model.tick % 5 == 0 { 1 } else { 0 }
  let supervision_budget = if recovery_active { 8 } else { 0 }
  let supervision_energy = if recovery_active { 10 } else { 0 }
  let supervision_pressure = if recovery_active { 14 } else { 0 }
  let supervision_stability = if recovery_active { 12 } else { 0 }
  let next_budget = clamp_metric(
    model.budget + budget_delta + budget_bonus + supervision_budget,
  )
  let next_energy = clamp_metric(
    model.energy +
    energy_delta -
    overload_penalty +
    energy_bonus +
    supervision_energy,
  )
  let next_pressure = clamp_metric(
    model.pressure +
    pressure_delta +
    brittle_penalty +
    energy_penalty -
    pressure_relief -
    supervision_pressure,
  )
  let next_stability = clamp_metric(
    model.stability +
    stability_delta -
    overload_penalty -
    budget_penalty +
    stability_bonus +
    supervision_stability,
  )
  {
    ..model,
    tick: model.tick + 1,
    budget: next_budget,
    energy: next_energy,
    pressure: next_pressure,
    stability: next_stability,
  }
}

///|
fn mayor_recovery_active(model : Model) -> Bool {
  model.pressure > 76 ||
  model.stability < 36 ||
  model.energy < 28 ||
  model.budget < 24
}

///|
fn clamp_metric(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
fn town_scene(model : Model) -> @ui.SceneRenderModel {
  let state = state_for_model(model)
  let report = @health.inspect_town(state)
  @ui.build_scene_render(@ui.build_dashboard(state, report))
}

///|
fn state_for_model(model : Model) -> @core.TownState {
  match model.state_source {
    StateSourceKind::DemoSimulation => demo_state(model)
    StateSourceKind::SnapshotFile => snapshot_placeholder_state(model)
  }
}

///|
fn next_state_source(source : StateSourceKind) -> StateSourceKind {
  match source {
    StateSourceKind::DemoSimulation => StateSourceKind::SnapshotFile
    StateSourceKind::SnapshotFile => StateSourceKind::DemoSimulation
  }
}

///|
fn state_source_label(source : StateSourceKind) -> String {
  match source {
    StateSourceKind::DemoSimulation => "Demo Simulation"
    StateSourceKind::SnapshotFile => "Snapshot File"
  }
}

///|
fn state_source_detail(source : StateSourceKind) -> String {
  match source {
    StateSourceKind::DemoSimulation =>
      "Live civic simulation: mayor supervision keeps services, agents, quests, and town health cycling 24/7."
    StateSourceKind::SnapshotFile =>
      "Snapshot mode shows the non-simulated bridge placeholder until the browser bundle can load `.moontown/town.json`."
  }
}

///|
fn state_source_options() -> Array[StateSourceKind] {
  [DemoSimulation, SnapshotFile]
}

///|
fn demo_state(model : Model) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(
      id="wenyu-valley",
      name="Wenyu Valley / AI Innovation Town",
      heartbeat_seconds=30,
      max_concurrent_tasks=24,
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="policy-hall",
      name="Policy Release Hall",
      purpose="Turns policy documents into quest lines, advisor answers, and application checklists.",
      workspace_root="/town/policy-hall",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["policy", "quest", "advisor"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="social-square",
      name="Social Square",
      purpose="Maintains weak-tie matching, activity initiation, and collaboration loops.",
      workspace_root="/town/social-square",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["matching", "events", "community"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="talent-avenue",
      name="Talent Star Avenue",
      purpose="Projects resident talent cards, skills heatmaps, and reception tours.",
      workspace_root="/town/talent-avenue",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["talent", "graph", "showcase"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="ai-garden",
      name="AI Science Garden",
      purpose="Runs AI learning tips, tool trials, creator workshops, and tutorial quests.",
      workspace_root="/town/ai-garden",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["learning", "tools", "workshop"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="future-harbor",
      name="Future Harbor",
      purpose="Coordinates roadshows, contest preparation, offline robot links, and digital twin signals.",
      workspace_root="/town/future-harbor",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["roadshow", "robot", "digital-twin"],
    ),
  )
  for worker in worker_sims(model) {
    state.register_worker(
      @core.WorkerRef::new(
        id=worker.id,
        name=worker.title,
        book_id=worker.book_id,
        role=worker_role_from_id(worker.id),
        capabilities=worker_capabilities(worker.id),
        status=worker.status,
      ),
    )
  }
  for task in task_specs(model) {
    state.enqueue_task(task)
  }
  for execution in execution_specs(model) {
    state.register_execution(execution)
  }
  state
}

///|
fn snapshot_placeholder_state(model : Model) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  state.register_book(
    @core.BookRef::new(
      id="snapshot",
      name="Persisted Town Snapshot",
      purpose="Browser snapshot bridge placeholder for `.moontown/town.json`.",
      workspace_root=".moontown",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["snapshot", "pending-bridge"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="snapshot-bridge",
      name="Snapshot Bridge",
      book_id="snapshot",
      role=@core.WorkerRole::Watcher,
      capabilities=["state-source", "projection"],
      status=@core.WorkerStatus::Waiting,
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="connect-snapshot-source",
      book_id="snapshot",
      title="Connect persisted town state",
      prompt="Load `.moontown/town.json` through a local endpoint or generated static JSON artifact.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Watcher),
      required_capabilities=["state-source"],
      status=@core.TownTaskStatus::Planned,
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="snapshot-source-\{model.tick}",
      kind="state-source",
      detail="Snapshot source selected; Rabbita browser bundle needs a state bridge before this reflects live town data.",
    ),
  )
  state
}

///|
fn worker_role_from_id(worker_id : String) -> @core.WorkerRole {
  match worker_id {
    "agent-policy" => @core.WorkerRole::Specialist
    "agent-social" => @core.WorkerRole::Operator
    "agent-talent" => @core.WorkerRole::MemoryKeeper
    "agent-garden" => @core.WorkerRole::Planner
    "agent-robot" => @core.WorkerRole::Watcher
    _ => @core.WorkerRole::MemoryKeeper
  }
}

///|
fn worker_capabilities(worker_id : String) -> Array[String] {
  match worker_id {
    "agent-policy" => ["policy", "rag", "checklist"]
    "agent-social" => ["matching", "event-planning", "community"]
    "agent-talent" => ["talent-graph", "projection", "reception"]
    "agent-garden" => ["tutorial", "tool-trial", "workshop"]
    "agent-robot" => ["robot", "venue", "digital-twin"]
    _ => ["reporting", "planning"]
  }
}

///|
fn worker_sims(model : Model) -> Array[WorkerSim] {
  [
    build_worker_sim(
      model,
      id="agent-policy",
      title="Policy Sprite",
      role="Policy Advisor",
      book_id="policy-hall",
      offset=0,
    ),
    build_worker_sim(
      model,
      id="agent-social",
      title="Cafe Matchmaker",
      role="Social Operator",
      book_id="social-square",
      offset=1,
    ),
    build_worker_sim(
      model,
      id="agent-talent",
      title="Talent Cartographer",
      role="Memory Keeper",
      book_id="talent-avenue",
      offset=2,
    ),
    build_worker_sim(
      model,
      id="agent-garden",
      title="AI Garden Tutor",
      role="Planner",
      book_id="ai-garden",
      offset=3,
    ),
    build_worker_sim(
      model,
      id="agent-robot",
      title="Harbor Robot Link",
      role="Watcher",
      book_id="future-harbor",
      offset=4,
    ),
  ]
}

///|
fn workers_for_model(model : Model) -> Array[WorkerSim] {
  match model.state_source {
    StateSourceKind::DemoSimulation => worker_sims(model)
    StateSourceKind::SnapshotFile => snapshot_worker_sims()
  }
}

///|
fn snapshot_worker_sims() -> Array[WorkerSim] {
  [
    {
      id: "snapshot-bridge",
      title: "Snapshot Bridge",
      role: "Watcher",
      book_id: "snapshot",
      status: @core.WorkerStatus::Waiting,
      zone_key: "worker-yard",
      energy: 100,
      load: 12,
      summary: "Waiting for a static or local endpoint bridge into `.moontown/town.json`.",
    },
  ]
}

///|
fn build_worker_sim(
  model : Model,
  id~ : String,
  title~ : String,
  role~ : String,
  book_id~ : String,
  offset~ : Int,
) -> WorkerSim {
  let status = worker_status_for(model, offset)
  let zone_key = worker_zone_key(book_id, status)
  let load = worker_load(model, offset, status)
  let idle_bonus = if status == @core.WorkerStatus::Idle { 8 } else { 0 }
  let energy = clamp_metric(model.energy - offset * 5 + idle_bonus)
  {
    id,
    title,
    role,
    book_id,
    status,
    zone_key,
    energy,
    load,
    summary: worker_summary(status, load),
  }
}

///|
fn worker_status_for(model : Model, offset : Int) -> @core.WorkerStatus {
  let cycle = (model.tick + offset) % 9
  if mayor_recovery_active(model) {
    match cycle {
      0 => @core.WorkerStatus::Running
      1 => @core.WorkerStatus::Waiting
      2 => @core.WorkerStatus::Idle
      3 => @core.WorkerStatus::Running
      4 => @core.WorkerStatus::Waiting
      5 => @core.WorkerStatus::Idle
      6 => @core.WorkerStatus::Running
      7 => @core.WorkerStatus::Waiting
      _ => @core.WorkerStatus::Idle
    }
  } else if model.stability < 30 && (cycle == 2 || cycle == 6) {
    @core.WorkerStatus::Waiting
  } else if model.pressure > 76 && (cycle == 1 || cycle == 4 || cycle == 7) {
    @core.WorkerStatus::Waiting
  } else {
    match model.strategy {
      Strategy::Balanced =>
        match cycle {
          0 => @core.WorkerStatus::Running
          1 => @core.WorkerStatus::Waiting
          2 => @core.WorkerStatus::Idle
          3 => @core.WorkerStatus::Running
          4 => @core.WorkerStatus::Waiting
          5 => @core.WorkerStatus::Idle
          6 => @core.WorkerStatus::Running
          7 => @core.WorkerStatus::Waiting
          _ => @core.WorkerStatus::Idle
        }
      Strategy::Throughput =>
        match cycle {
          0 => @core.WorkerStatus::Running
          1 => @core.WorkerStatus::Running
          2 => @core.WorkerStatus::Waiting
          3 => @core.WorkerStatus::Running
          4 => @core.WorkerStatus::Running
          5 => @core.WorkerStatus::Waiting
          6 => @core.WorkerStatus::Running
          7 => @core.WorkerStatus::Idle
          _ => @core.WorkerStatus::Running
        }
      Strategy::Recovery =>
        match cycle {
          0 => @core.WorkerStatus::Idle
          1 => @core.WorkerStatus::Waiting
          2 => @core.WorkerStatus::Running
          3 => @core.WorkerStatus::Idle
          4 => @core.WorkerStatus::Waiting
          5 => @core.WorkerStatus::Running
          6 => @core.WorkerStatus::Idle
          7 => @core.WorkerStatus::Waiting
          _ => @core.WorkerStatus::Idle
        }
    }
  }
}

///|
fn worker_zone_key(book_id : String, status : @core.WorkerStatus) -> String {
  match status {
    @core.WorkerStatus::Blocked => "anomaly-corner"
    @core.WorkerStatus::Idle => "worker-yard"
    @core.WorkerStatus::Waiting => "worker-yard"
    @core.WorkerStatus::Offline => "gate"
    @core.WorkerStatus::Running => "book-\{book_id}"
  }
}

///|
fn worker_load(model : Model, offset : Int, status : @core.WorkerStatus) -> Int {
  let baseline = model.pressure + offset * 6
  match status {
    @core.WorkerStatus::Running => clamp_metric(baseline + 16)
    @core.WorkerStatus::Waiting => clamp_metric(baseline - 8)
    @core.WorkerStatus::Idle => clamp_metric(baseline - 18)
    @core.WorkerStatus::Blocked => clamp_metric(baseline + 26)
    @core.WorkerStatus::Offline => 0
  }
}

///|
fn worker_summary(status : @core.WorkerStatus, load : Int) -> String {
  match status {
    @core.WorkerStatus::Running =>
      "Serving residents and town quests at load \{load}%."
    @core.WorkerStatus::Waiting =>
      "Waiting in the plaza for the mayor's next supervised handoff."
    @core.WorkerStatus::Idle =>
      "Resting in the yard while memory and social signals settle."
    @core.WorkerStatus::Blocked =>
      "Blocked by civic queue pressure or failed offline linkage."
    @core.WorkerStatus::Offline => "Offline and unavailable."
  }
}

///|
fn task_specs(model : Model) -> Array[@core.TownTask] {
  [
    @core.TownTask::new(
      id="task-policy-quest",
      book_id="policy-hall",
      title="Explain rental subsidy quest",
      prompt="Convert a policy into a scenario quest, checklist, and resident-facing reward path.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Specialist),
      required_capabilities=["policy", "checklist"],
      status=task_status_for(model, 0),
    ),
    @core.TownTask::new(
      id="task-cafe-match",
      book_id="social-square",
      title="Match two complementary OPCs",
      prompt="Detect business complementarity and stage a low-pressure cafe introduction.",
      domain=@core.WorkDomain::SocialExperiment,
      required_role=Some(@core.WorkerRole::Operator),
      required_capabilities=["matching", "community"],
      status=task_status_for(model, 1),
    ),
    @core.TownTask::new(
      id="task-talent-graph",
      book_id="talent-avenue",
      title="Refresh talent heatmap",
      prompt="Update resident skills, achievements, and tour-ready showcase cards.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["talent-graph", "projection"],
      status=task_status_for(model, 2),
    ),
    @core.TownTask::new(
      id="task-ai-tip",
      book_id="ai-garden",
      title="Publish daily AI tool trial",
      prompt="Turn one practical AI workflow into a five-minute resident tutorial.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["tutorial", "tool-trial"],
      status=task_status_for(model, 3),
    ),
    @core.TownTask::new(
      id="task-robot-booking",
      book_id="future-harbor",
      title="Sync robot venue booking",
      prompt="Bridge a virtual request into roadshow room availability and robot confirmation.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Watcher),
      required_capabilities=["robot", "venue"],
      status=task_status_for(model, 4),
    ),
  ]
}

///|
fn task_status_for(model : Model, offset : Int) -> @core.TownTaskStatus {
  let cycle = (model.tick + offset) % 8
  if mayor_recovery_active(model) {
    match cycle {
      0 => @core.TownTaskStatus::Assigned
      1 => @core.TownTaskStatus::Running
      2 => @core.TownTaskStatus::Running
      3 => @core.TownTaskStatus::Planned
      4 => @core.TownTaskStatus::Assigned
      5 => @core.TownTaskStatus::Running
      6 => @core.TownTaskStatus::Pending
      _ => @core.TownTaskStatus::Running
    }
  } else if model.pressure > 80 && (cycle == 3 || cycle == 6) {
    @core.TownTaskStatus::Assigned
  } else {
    match cycle {
      0 => @core.TownTaskStatus::Pending
      1 => @core.TownTaskStatus::Assigned
      2 => @core.TownTaskStatus::Running
      3 => @core.TownTaskStatus::Running
      4 => @core.TownTaskStatus::Assigned
      5 => @core.TownTaskStatus::Planned
      6 => @core.TownTaskStatus::Pending
      _ => @core.TownTaskStatus::Running
    }
  }
}

///|
fn execution_status_for(
  model : Model,
  offset : Int,
) -> @core.TaskExecutionStatus {
  if mayor_recovery_active(model) && offset == 4 {
    @core.TaskExecutionStatus::RunConfirmed
  } else if model.stability < 26 && offset == 3 {
    @core.TaskExecutionStatus::ReviewQueued
  } else {
    match (model.tick + offset) % 7 {
      0 => @core.TaskExecutionStatus::PacketReady
      1 => @core.TaskExecutionStatus::ProposalImported
      2 => @core.TaskExecutionStatus::RunConfirmed
      3 => @core.TaskExecutionStatus::Running
      4 => @core.TaskExecutionStatus::AwaitingPersistence
      5 => @core.TaskExecutionStatus::ReviewQueued
      _ => @core.TaskExecutionStatus::Completed
    }
  }
}

///|
fn execution_specs(model : Model) -> Array[@core.TaskExecutionRecord] {
  [
    execution_spec(model, "task-policy-quest", "policy-hall", 0),
    execution_spec(model, "task-cafe-match", "social-square", 1),
    execution_spec(model, "task-talent-graph", "talent-avenue", 2),
    execution_spec(model, "task-ai-tip", "ai-garden", 3),
    execution_spec(model, "task-robot-booking", "future-harbor", 4),
  ]
}

///|
fn execution_spec(
  model : Model,
  task_id : String,
  book_id : String,
  offset : Int,
) -> @core.TaskExecutionRecord {
  let status = execution_status_for(model, offset)
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id="packet-\{task_id}",
    packet_path=".moontown/packets/packet-\{task_id}.json",
    proposal_id=Some("proposal-packet-\{task_id}"),
    run_id=if status == @core.TaskExecutionStatus::PacketReady ||
      status == @core.TaskExecutionStatus::ProposalImported {
      None
    } else {
      Some("run-packet-\{task_id}")
    },
    status~,
    summary=execution_summary(status, task_id),
    output_contract="keeper.plan.packet.v1",
    context_pages=["wiki/index.md", "wiki/log.md"],
    skill_paths=["skills/wiki-maintainer/SKILL.md"],
    requires_review=status == @core.TaskExecutionStatus::AwaitingPersistence ||
      status == @core.TaskExecutionStatus::ReviewQueued,
    notify_town=true,
  )
}

///|
fn execution_summary(
  status : @core.TaskExecutionStatus,
  task_id : String,
) -> String {
  match status {
    @core.TaskExecutionStatus::PacketReady =>
      "Keeper packet prepared for \{task_id}."
    @core.TaskExecutionStatus::ProposalImported =>
      "Proposal imported and waiting for mayor confirmation."
    @core.TaskExecutionStatus::RunConfirmed =>
      "Mayor confirmed a live MoonClaw run."
    @core.TaskExecutionStatus::Running =>
      "MoonClaw run is executing book-local work."
    @core.TaskExecutionStatus::AwaitingPersistence =>
      "MoonBook persistence is waiting to absorb the result."
    @core.TaskExecutionStatus::ReviewQueued =>
      "Keeper review queued after persistence."
    @core.TaskExecutionStatus::Completed =>
      "Packet, run, and review loop completed."
    @core.TaskExecutionStatus::Stale =>
      "Mayor marked the execution stale and queued a recovery decision."
    @core.TaskExecutionStatus::Failed =>
      "Execution failed and the town should recover or retry."
  }
}

///|
fn status_chip(text : String, class_name : String) -> @rabbita.Html {
  span(class="chip \{class_name}", text)
}

///|
fn no_children() -> Array[@rabbita.Html] {
  []
}

///|
fn simulation_time_label(tick : Int) -> String {
  let total_minutes = 8 * 60 + tick * 15
  let day = total_minutes / (24 * 60) + 1
  let minute_of_day = total_minutes % (24 * 60)
  let hour = minute_of_day / 60
  let minute = minute_of_day % 60
  "Day \{day} / \{pad2(hour)}:\{pad2(minute)}"
}

///|
fn pad2(value : Int) -> String {
  if value < 10 {
    "0\{value}"
  } else {
    value.to_string()
  }
}

///|
fn day_phase_label(tick : Int) -> String {
  let minute_of_day = (8 * 60 + tick * 15) % (24 * 60)
  let hour = minute_of_day / 60
  if hour < 6 {
    "Night patrol"
  } else if hour < 11 {
    "Morning onboarding"
  } else if hour < 15 {
    "Midday service"
  } else if hour < 19 {
    "Cafe matching"
  } else {
    "Evening reflection"
  }
}

///|
fn season_label(tick : Int) -> String {
  match tick / 96 % 4 {
    0 => "Spring code festival"
    1 => "Summer river lab"
    2 => "Autumn roadshow"
    _ => "Winter build camp"
  }
}

///|
fn weather_label(tick : Int) -> String {
  match tick / 12 % 5 {
    0 => "Clear valley"
    1 => "River breeze"
    2 => "Rainy hackathon"
    3 => "Firefly night"
    _ => "Soft fog"
  }
}

///|
fn resident_count(model : Model) -> Int {
  52 + model.tick % 19
}

///|
fn valley_points_redeemed(model : Model) -> Int {
  12 + model.tick % 11
}

///|
fn robot_service_count(model : Model) -> Int {
  8 + model.tick % 7
}

///|
fn strategy_label(strategy : Strategy) -> String {
  match strategy {
    Strategy::Balanced => "Balanced"
    Strategy::Throughput => "Throughput"
    Strategy::Recovery => "Recovery"
  }
}

///|
fn render_asset(asset_path : String, title : String) -> @rabbita.Html {
  img(
    class="scene-asset",
    src=asset_path,
    alt="\{title} asset",
    loading="lazy",
    no_children(),
  )
}

///|
fn all_alerts(scene : @ui.SceneRenderModel, model : Model) -> Array[String] {
  let alerts : Array[String] = []
  if mayor_recovery_active(model) {
    alerts.push(
      "Mayor supervision is actively recovering the town loop before service collapse.",
    )
    return alerts
  }
  for alert in scene.alerts {
    alerts.push(alert)
  }
  if model.pressure > 72 {
    alerts.push("Queue pressure is above safe town thresholds.")
  }
  if model.stability < 38 {
    alerts.push("Town stability is degrading and blockers may spread.")
  }
  if model.budget < 24 {
    alerts.push("Budget reserve is thin; dispatch flexibility is shrinking.")
  }
  if alerts.is_empty() {
    alerts.push("No active alerts")
  }
  alerts
}

///|
fn render_alerts(alerts : Array[String]) -> @rabbita.Html {
  if alerts.length() == 1 && alerts[0] == "No active alerts" {
    div(class="alert-strip", [status_chip(alerts[0], "chip-calm")])
  } else if alerts.length() == 1 &&
    alerts[0] ==
    "Mayor supervision is actively recovering the town loop before service collapse." {
    div(class="alert-strip", [status_chip(alerts[0], "chip-recovery")])
  } else {
    div(
      class="alert-strip",
      alerts.map(alert => status_chip(alert, "chip-alert")),
    )
  }
}

///|
fn render_meter(label : String, value : Int, tone : String) -> @rabbita.Html {
  let fill_style = ["width: \{value}%"]
  article(class="metric-card", [
    div(class="metric-head", [
      p(class="metric-label", label),
      p(class="metric-value", "\{value}%"),
    ]),
    div(class="metric-track", [
      div(class="metric-fill \{tone}", style=fill_style, no_children()),
    ]),
  ])
}

///|
fn render_civic_context(model : Model) -> @rabbita.Html {
  section(class="civic-context", [
    status_chip("Phase: \{day_phase_label(model.tick)}", "chip-clock"),
    status_chip("Season: \{season_label(model.tick)}", "chip-book"),
    status_chip("Weather: \{weather_label(model.tick)}", "chip-neutral"),
    status_chip("Residents: \{resident_count(model)}", "chip-neutral"),
    status_chip(
      "Valley points redeemed: \{valley_points_redeemed(model)}",
      "chip-book",
    ),
    status_chip("Robot calls: \{robot_service_count(model)}", "chip-neutral"),
  ])
}

///|
fn count_workers_by_status(
  workers : Array[WorkerSim],
  status : @core.WorkerStatus,
) -> Int {
  let mut count = 0
  for worker in workers {
    if worker.status == status {
      count += 1
    }
  }
  count
}

///|
fn runtime_stat_chip(
  label : String,
  value : Int,
  class_name : String,
) -> @rabbita.Html {
  article(class="runtime-stat \{class_name}", [
    p(class="metric-label", label),
    p(class="runtime-stat-value", value.to_string()),
  ])
}

///|
fn render_runtime_bar(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let running_workers = count_workers_by_status(
    workers,
    @core.WorkerStatus::Running,
  )
  let blocked_workers = count_workers_by_status(
    workers,
    @core.WorkerStatus::Blocked,
  )
  let review_count = count_execution_status(
    executions,
    @core.TaskExecutionStatus::ReviewQueued,
  )
  let persistence_count = count_execution_status(
    executions,
    @core.TaskExecutionStatus::AwaitingPersistence,
  )
  let completed_count = count_execution_status(
    executions,
    @core.TaskExecutionStatus::Completed,
  )
  section(class="runtime-bar", [
    div(class="runtime-head", [
      div(class="runtime-copy", [
        p(class="eyebrow", "Operator Surface"),
        h2("Town traffic, keeper queue, and review flow"),
        p(class="summary", state_source_detail(model.state_source)),
      ]),
      div(class="runtime-status", [
        status_chip(
          if model.state_source == StateSourceKind::SnapshotFile {
            "Snapshot bridge"
          } else if model.paused {
            "Simulation paused"
          } else {
            "Simulation live"
          },
          if model.state_source == StateSourceKind::SnapshotFile {
            "chip-neutral"
          } else if model.paused {
            "chip-alert"
          } else {
            "chip-live"
          },
        ),
        status_chip(
          "Source: \{state_source_label(model.state_source)}",
          "chip-book",
        ),
        status_chip("Workers online: \{workers.length()}", "chip-neutral"),
      ]),
    ]),
    div(class="runtime-grid", [
      runtime_stat_chip("Running", running_workers, "runtime-running"),
      runtime_stat_chip("Blocked", blocked_workers, "runtime-blocked"),
      runtime_stat_chip("Persisting", persistence_count, "runtime-persisting"),
      runtime_stat_chip("Review", review_count, "runtime-review"),
      runtime_stat_chip("Completed", completed_count, "runtime-completed"),
    ]),
  ])
}

///|
fn render_civic_module_card(
  name : String,
  zone : String,
  detail : String,
  signal : String,
) -> @rabbita.Html {
  article(class="civic-module-card", [
    p(class="scene-node-key", zone),
    h3(name),
    p(detail),
    span(class="module-signal", signal),
  ])
}

///|
fn render_civic_modules(model : Model) -> @rabbita.Html {
  section(class="civic-modules", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Wenyu Valley Modules"),
      h2("Seven civic systems, one always-on mayor loop"),
      p(
        class="summary",
        if mayor_recovery_active(model) {
          "Recovery patrol is active: the mayor is throttling queues, restoring worker energy, and keeping services online."
        } else {
          "The town stays alive through policy quests, social matching, talent projection, AI learning, and virtual-physical service loops."
        },
      ),
    ]),
    div(class="civic-module-grid", [
      render_civic_module_card(
        "Policy Hall", "South / services", "Policy scrolls become quests, checklists, and advisor answers.",
        "Quest-ready",
      ),
      render_civic_module_card(
        "Contest Express", "Future Harbor", "Roadshow prep, mock judging, reminders, and champion parade hooks.",
        "Season live",
      ),
      render_civic_module_card(
        "Social Square", "Central / cafe", "Agents turn weak ties into introductions, events, and trial collaboration.",
        "Matchmaking",
      ),
      render_civic_module_card(
        "Talent Avenue", "Central / showcase", "Resident skills, achievements, tour cards, and talent graph projections.",
        "Graph warm",
      ),
      render_civic_module_card(
        "Vitality ECG", "Town-wide", "Settlement broadcasts, activity calendar, and verified achievement pulses.",
        "24/7 pulse",
      ),
      render_civic_module_card(
        "AI Garden", "North / eco", "Five-minute AI tips, tool trials, and creator workshop loops.",
        "Learning",
      ),
      render_civic_module_card(
        "Robot Link", "Offline bridge", "Venue booking, proxy attendance, and digital twin signals for physical space.",
        "Bridge sync",
      ),
    ]),
  ])
}

///|
fn resident_sims(model : Model) -> Array[ResidentSim] {
  [
    {
      name: "Li / Edge AI OPC",
      venture: "Low-power vision module studio",
      need: "Needs rental subsidy eligibility and contest prep.",
      mood: if model.pressure > 70 {
        "Focused"
      } else {
        "Curious"
      },
      agent_goal: "Ask Policy Sprite for subsidy checklist, then book a mock roadshow.",
      memory: "Remembered a past concern about compute vouchers and prototype demo timing.",
      plan: "09:00 policy quest, 14:00 cafe intro, 18:00 reflection note.",
      zone: "Policy Hall",
    },
    {
      name: "Chen / Design Automation OPC",
      venture: "AI UI prototyping service",
      need: "Looking for hardware founders who need interface design.",
      mood: "Open to weak-tie match",
      agent_goal: "Meet one robotics or edge-AI neighbor in Social Square.",
      memory: "Prefers low-pressure cafe intros before business collaboration.",
      plan: "Browse Talent Avenue, accept cafe match, save follow-up memory.",
      zone: "Social Square",
    },
    {
      name: "Ma / Policy Ops Visitor",
      venture: "District operator evaluating settlement conversion.",
      need: "Needs tour-ready talent graph and daily vitality summary.",
      mood: "Observing",
      agent_goal: "Generate VIP reception route and verify achievement broadcasts.",
      memory: "Asked yesterday for warm-community evidence instead of raw traffic.",
      plan: "Review talent heatmap, export visit notes, flag missing service gaps.",
      zone: "Talent Avenue",
    },
  ]
}

///|
fn render_resident_card(resident : ResidentSim) -> @rabbita.Html {
  article(class="resident-card", [
    div(class="resident-head", [
      span(class="resident-avatar", resident_initials(resident.name)),
      div(class="resident-title", [h3(resident.name), p(resident.zone)]),
    ]),
    p(resident.venture),
    p("Need: \{resident.need}"),
    p("Mood: \{resident.mood}"),
    p("Agent goal: \{resident.agent_goal}"),
    div(class="memory-strip", [span("Memory"), p(resident.memory)]),
    div(class="memory-strip", [span("Plan"), p(resident.plan)]),
  ])
}

///|
fn resident_initials(name : String) -> String {
  match name {
    "Li / Edge AI OPC" => "LI"
    "Chen / Design Automation OPC" => "CH"
    "Ma / Policy Ops Visitor" => "MA"
    _ => "AI"
  }
}

///|
fn render_resident_agents(model : Model) -> @rabbita.Html {
  section(class="resident-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Resident Agents"),
      h2("Digital twins with memory, reflection, and plans"),
      p(
        class="summary",
        "Each resident now has visible need state, remembered context, and a next plan. This is the UI contract for real Memory Stream + Reflection + Planning integration.",
      ),
    ]),
    div(
      class="resident-grid",
      resident_sims(model).map(resident => render_resident_card(resident)),
    ),
  ])
}

///|
fn civic_quests(model : Model) -> Array[CivicQuestSim] {
  [
    {
      title: "Rental subsidy walkthrough",
      area: "Policy Hall",
      stage: if model.tick % 4 < 2 {
        "Advisor interpreting"
      } else {
        "Checklist ready"
      },
      reward: "80 Valley XP + application packet",
      status: "Active",
    },
    {
      title: "OPC roadshow preparation",
      area: "Contest Express",
      stage: if model.tick % 5 < 3 {
        "Mock judge scoring"
      } else {
        "Deck gap review"
      },
      reward: "Priority roadshow slot",
      status: "Nurturing",
    },
    {
      title: "Cafe collaboration intro",
      area: "Social Square",
      stage: "Agent-mediated weak-tie match",
      reward: "Trial collaboration room",
      status: "Matching",
    },
    {
      title: "Remote venue booking",
      area: "Robot Link",
      stage: if model.tick % 3 == 0 {
        "Robot confirmation"
      } else {
        "Room availability sync"
      },
      reward: "Offline room hold",
      status: "Bridge",
    },
  ]
}

///|
fn render_quest_card(quest : CivicQuestSim) -> @rabbita.Html {
  article(class="quest-card", [
    p(class="scene-node-key", quest.area),
    h3(quest.title),
    p("Stage: \{quest.stage}"),
    p("Reward: \{quest.reward}"),
    span(class="module-signal", quest.status),
  ])
}

///|
fn render_civic_quests(model : Model) -> @rabbita.Html {
  section(class="quest-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Civic Quests"),
      h2("Policy, contest, social, and offline workflows as playable services"),
      p(
        class="summary",
        "This replaces static service text with quest-shaped state that agents can advance and the mayor can supervise.",
      ),
    ]),
    div(
      class="quest-grid",
      civic_quests(model).map(quest => render_quest_card(quest)),
    ),
  ])
}

///|
fn social_matches() -> Array[SocialMatchSim] {
  [
    {
      left: "Li / Edge AI OPC",
      right: "Chen / Design Automation OPC",
      reason: "Hardware prototype needs investor-facing UI and demo storytelling.",
      next_step: "Cafe intro at 15:30, then shared roadshow checklist.",
      confidence: 87,
    },
    {
      left: "AI Garden Tutor",
      right: "Policy Sprite",
      reason: "Daily AI tip can explain subsidy form filling with a practical demo.",
      next_step: "Publish tutorial quest after policy source review.",
      confidence: 79,
    },
  ]
}

///|
fn talent_signals(model : Model) -> Array[TalentSignalSim] {
  [
    {
      name: "Edge AI Studio",
      domain: "Robotics / edge vision",
      skills: "TinyML, camera modules, deployment",
      activity: clamp_metric(72 + model.tick % 16),
    },
    {
      name: "Design Automation Lab",
      domain: "AI design services",
      skills: "UI generation, design systems, rapid prototypes",
      activity: clamp_metric(66 + model.tick % 19),
    },
    {
      name: "Policy Ops Desk",
      domain: "District services",
      skills: "policy synthesis, reception routes, event ops",
      activity: clamp_metric(58 + model.tick % 23),
    },
  ]
}

///|
fn render_match_card(match_item : SocialMatchSim) -> @rabbita.Html {
  article(class="match-card", [
    h3("\{match_item.left} x \{match_item.right}"),
    p(match_item.reason),
    p("Next: \{match_item.next_step}"),
    span(class="module-signal", "Confidence \{match_item.confidence}%"),
  ])
}

///|
fn render_talent_card(signal : TalentSignalSim) -> @rabbita.Html {
  let fill_style = ["width: \{signal.activity}%"]
  article(class="talent-card", [
    h3(signal.name),
    p(signal.domain),
    p(signal.skills),
    div(class="metric-track", [
      div(class="metric-fill tone-energy", style=fill_style, no_children()),
    ]),
    p("Activity brightness: \{signal.activity}%"),
  ])
}

///|
fn render_social_talent(model : Model) -> @rabbita.Html {
  section(class="social-talent-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Social Capital"),
      h2("Weak ties, talent graph, and reception-ready evidence"),
      p(
        class="summary",
        "The town should prove community warmth through visible matches, skill density, and operator-friendly talent projections.",
      ),
    ]),
    div(class="social-talent-grid", [
      div(class="subpanel", [
        h3("Agent Matches"),
        div(
          class="feed-list",
          social_matches().map(item => render_match_card(item)),
        ),
      ]),
      div(class="subpanel", [
        h3("Talent Star Avenue"),
        div(
          class="feed-list",
          talent_signals(model).map(signal => render_talent_card(signal)),
        ),
      ]),
    ]),
  ])
}

///|
fn render_bridge_contract(model : Model) -> @rabbita.Html {
  section(class="bridge-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "24/7 Runtime Contract"),
      h2("From playable prototype to durable daemon town"),
      p(
        class="summary",
        "The UI now exposes the state objects the backend must keep alive: residents, memories, quests, matches, workers, health, and physical bridge events.",
      ),
    ]),
    div(class="bridge-grid", [
      runtime_stat_chip("Daemon ticks", model.tick, "runtime-running"),
      runtime_stat_chip("Residents", resident_count(model), "runtime-packets"),
      runtime_stat_chip(
        "Memory streams",
        resident_sims(model).length(),
        "runtime-imported",
      ),
      runtime_stat_chip(
        "Open quests",
        civic_quests(model).length(),
        "runtime-persisting",
      ),
      runtime_stat_chip(
        "Robot calls",
        robot_service_count(model),
        "runtime-review",
      ),
    ]),
    div(class="contract-list", [
      p(
        "Persisted town state: `.moontown/town.json` should publish the same objects shown here.",
      ),
      p(
        "MoonBook state: each civic module owns durable wiki/memory pages for its domain.",
      ),
      p(
        "MoonClaw state: worker runs emit result packets and memory candidates, never raw global memory writes.",
      ),
      p(
        "Browser bridge: Rabbita should consume a generated `town-runtime.json` or local endpoint instead of synthetic state.",
      ),
    ]),
  ])
}

///|
fn execution_stage_cards(
  executions : Array[@core.TaskExecutionRecord],
) -> Array[@rabbita.Html] {
  [
    runtime_stat_chip(
      "Packets",
      count_execution_status(executions, @core.TaskExecutionStatus::PacketReady),
      "runtime-packets",
    ),
    runtime_stat_chip(
      "Imported",
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::ProposalImported,
      ),
      "runtime-imported",
    ),
    runtime_stat_chip(
      "Running",
      count_execution_status(executions, @core.TaskExecutionStatus::Running) +
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::RunConfirmed,
      ),
      "runtime-running",
    ),
    runtime_stat_chip(
      "Persisting",
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::AwaitingPersistence,
      ),
      "runtime-persisting",
    ),
    runtime_stat_chip(
      "Review",
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::ReviewQueued,
      ),
      "runtime-review",
    ),
    runtime_stat_chip(
      "Done",
      count_execution_status(executions, @core.TaskExecutionStatus::Completed),
      "runtime-completed",
    ),
  ]
}

///|
fn render_strategy_button(
  dispatch : Dispatch[Msg],
  current : Strategy,
  strategy : Strategy,
) -> @rabbita.Html {
  let active = current == strategy
  let active_suffix = if active { " active" } else { "" }
  let class_name = "strategy-button" + active_suffix
  button(
    class=class_name,
    on_click=dispatch(SetStrategy(strategy)),
    strategy_label(strategy),
  )
}

///|
fn render_controls(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let status = if model.state_source == StateSourceKind::SnapshotFile {
    if model.paused {
      "Bridge paused"
    } else {
      "Bridge"
    }
  } else if model.paused {
    "Paused"
  } else {
    "Live"
  }
  let action_label = if model.paused { "Resume" } else { "Pause" }
  section(class="control-hub", [
    div(class="control-strip", [
      status_chip(status, if model.paused { "chip-alert" } else { "chip-live" }),
      status_chip(simulation_time_label(model.tick), "chip-clock"),
      status_chip("Tick \{model.tick}", "chip-neutral"),
      status_chip("Mode: \{strategy_label(model.strategy)}", "chip-book"),
      status_chip(
        "State sources: \{state_source_options().length()}",
        "chip-neutral",
      ),
      button(
        class="control-button",
        on_click=dispatch(ToggleStateSource),
        "Switch Source",
      ),
      button(
        class="control-button",
        on_click=dispatch(TogglePause),
        action_label,
      ),
      button(class="control-button", on_click=dispatch(Step), "Step"),
    ]),
    div(class="strategy-strip", [
      render_strategy_button(dispatch, model.strategy, Strategy::Balanced),
      render_strategy_button(dispatch, model.strategy, Strategy::Throughput),
      render_strategy_button(dispatch, model.strategy, Strategy::Recovery),
      button(
        class="action-button",
        on_click=dispatch(InjectBudget),
        "Inject Budget",
      ),
      button(
        class="action-button",
        on_click=dispatch(RelieveQueue),
        "Relieve Queue",
      ),
      button(
        class="action-button",
        on_click=dispatch(StabilityDrill),
        "Stability Drill",
      ),
    ]),
  ])
}

///|
fn render_node(
  dispatch : Dispatch[Msg],
  node : @ui.SceneRenderNode,
  selected : Bool,
) -> @rabbita.Html {
  let style = [
    "left: \{node.x}px",
    "top: \{node.y}px",
    "width: \{node.width}px",
    "height: \{node.height}px",
  ]
  let selected_suffix = if selected { " selected" } else { "" }
  let class_name = "scene-card-button" + selected_suffix
  article(class="scene-node \{node.class_name}", style~, [
    div(
      class="asset-stack",
      node.asset_paths.map(path => render_asset(path, node.title)),
    ),
    button(class=class_name, on_click=dispatch(SelectNode(node.key)), [
      h3(node.title),
      p(class="scene-node-key", node.key),
      div(class="scene-lines", node.lines.map(line => p(line))),
    ]),
  ])
}

///|
fn scene_node_by_key(
  scene : @ui.SceneRenderModel,
  key : String,
) -> @ui.SceneRenderNode {
  for node in scene.nodes {
    if node.key == key {
      return node
    }
  }
  scene.nodes[0]
}

///|
fn worker_avatar_left(zone : @ui.SceneRenderNode, index : Int) -> Int {
  zone.x + 18 + index % 2 * 62 + index / 2 * 18
}

///|
fn worker_avatar_top(zone : @ui.SceneRenderNode, index : Int) -> Int {
  zone.y + zone.height / 2 - 26 + index % 3 * 18
}

///|
fn worker_avatar_initials(title : String) -> String {
  match title {
    "Harness Hound" => "HH"
    "Review Owl" => "RO"
    "Ledger Fox" => "LF"
    "Archive Cat" => "AC"
    "Snapshot Bridge" => "SB"
    "Policy Sprite" => "PS"
    "Cafe Matchmaker" => "CM"
    "Talent Cartographer" => "TC"
    "AI Garden Tutor" => "AG"
    "Harbor Robot Link" => "HR"
    _ => "??"
  }
}

///|
fn worker_status_class(status : @core.WorkerStatus) -> String {
  match status {
    @core.WorkerStatus::Running => "worker-running"
    @core.WorkerStatus::Waiting => "worker-waiting"
    @core.WorkerStatus::Idle => "worker-idle"
    @core.WorkerStatus::Blocked => "worker-blocked"
    @core.WorkerStatus::Offline => "worker-offline"
  }
}

///|
fn render_worker_avatar(
  dispatch : Dispatch[Msg],
  scene : @ui.SceneRenderModel,
  worker : WorkerSim,
  index : Int,
  selected : Bool,
) -> @rabbita.Html {
  let zone = scene_node_by_key(scene, worker.zone_key)
  let style = [
    "left: \{worker_avatar_left(zone, index)}px",
    "top: \{worker_avatar_top(zone, index)}px",
  ]
  let selected_suffix = if selected { " selected" } else { "" }
  let class_name = "worker-avatar \{worker_status_class(worker.status)}" +
    selected_suffix
  button(class=class_name, style~, on_click=dispatch(SelectWorker(worker.id)), [
    span(class="worker-badge", worker_avatar_initials(worker.title)),
    span(class="worker-label", worker.title),
    span(class="worker-meta", "\{worker.role} / \{worker.status.to_string()}"),
  ])
}

///|
fn feed_items(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = []
  for worker in workers {
    if worker.status == @core.WorkerStatus::Blocked {
      feed.push({
        title: "\{worker.title} stalled",
        detail: "Shift attention into stability or relieve queue pressure.",
        tone: "alert",
      })
    }
  }
  for execution in executions {
    match execution.status {
      @core.TaskExecutionStatus::AwaitingPersistence =>
        feed.push({
          title: "\{execution.task_id} awaits MoonBook persistence",
          detail: "The run is done; the next town action is keeper persistence and evidence capture.",
          tone: "hot",
        })
      @core.TaskExecutionStatus::ReviewQueued =>
        feed.push({
          title: "\{execution.task_id} queued for keeper review",
          detail: "Town should keep the proposal chain visible until review sync settles.",
          tone: "alert",
        })
      @core.TaskExecutionStatus::Stale =>
        feed.push({
          title: "\{execution.task_id} went stale",
          detail: "Mayor supervision should recover the missed heartbeat or retry the lane.",
          tone: "alert",
        })
      @core.TaskExecutionStatus::Failed =>
        feed.push({
          title: "\{execution.task_id} failed",
          detail: "A proposal/run failure surfaced in the packet lifecycle.",
          tone: "alert",
        })
      _ => ()
    }
  }
  if model.strategy == Strategy::Throughput {
    feed.push({
      title: "Mayor favors throughput",
      detail: "Output is up, but queue pressure is climbing faster than recovery.",
      tone: "hot",
    })
  } else if model.strategy == Strategy::Recovery {
    feed.push({
      title: "Recovery window active",
      detail: "Books are absorbing less work while stability and energy recover.",
      tone: "calm",
    })
  } else {
    feed.push({
      title: "Balanced dispatch",
      detail: "Town is trading moderate output for smoother keeper handoffs.",
      tone: "neutral",
    })
  }
  feed.push({
    title: "Budget reserve",
    detail: "Current reserve sits at \{model.budget}%. Low reserve amplifies town fragility.",
    tone: if model.budget < 30 {
      "alert"
    } else {
      "neutral"
    },
  })
  feed
}

///|
fn render_feed(feed : Array[FeedItem]) -> @rabbita.Html {
  section(class="feed-panel", [
    h2("Activity Feed"),
    div(
      class="feed-list",
      feed.map(item => {
        article(class="feed-item tone-\{item.tone}", [
          h3(item.title),
          p(item.detail),
        ])
      }),
    ),
  ])
}

///|
fn selection_title(selection : Selection) -> String {
  match selection {
    Overview => "Town Overview"
    Node(_) => "Zone Inspector"
    Worker(_) => "Worker Inspector"
  }
}

///|
fn find_worker(workers : Array[WorkerSim], worker_id : String) -> WorkerSim? {
  for worker in workers {
    if worker.id == worker_id {
      return Some(worker)
    }
  }
  None
}

///|
fn render_worker_choice_button(
  dispatch : Dispatch[Msg],
  worker : WorkerSim,
) -> @rabbita.Html {
  button(
    class="inspector-action worker-choice",
    on_click=dispatch(SelectWorker(worker.id)),
    "\{worker.title} - \{worker.status.to_string()}",
  )
}

///|
fn render_worker_roster(
  dispatch : Dispatch[Msg],
  workers : Array[WorkerSim],
) -> @rabbita.Html {
  if workers.is_empty() {
    div(class="worker-roster", [p("No workers are visible in this scope.")])
  } else {
    let controls : Array[@rabbita.Html] = [
      p(class="worker-roster-title", "Workers"),
    ]
    for worker in workers {
      controls.push(render_worker_choice_button(dispatch, worker))
    }
    div(class="worker-roster", controls)
  }
}

///|
fn selection_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> Array[@rabbita.Html] {
  match model.selection {
    Overview =>
      [
        p(
          "Select a zone or worker to inspect live state. Use town actions to redirect the simulation.",
        ),
        p(
          "Packet-ready: \{count_execution_status(executions, @core.TaskExecutionStatus::PacketReady)}",
        ),
        p(
          "Imported proposals: \{count_execution_status(executions, @core.TaskExecutionStatus::ProposalImported)}",
        ),
        p("Active runs: \{running_execution_count(executions)}"),
        render_worker_roster(dispatch, workers),
        button(
          class="inspector-action",
          on_click=dispatch(InjectBudget),
          "Inject Budget",
        ),
        button(
          class="inspector-action",
          on_click=dispatch(RelieveQueue),
          "Relieve Queue",
        ),
        button(
          class="inspector-action",
          on_click=dispatch(StabilityDrill),
          "Stability Drill",
        ),
      ]
    Node(node_key) => {
      let node = scene_node_by_key(scene, node_key)
      let related_workers = workers.filter(fn(worker) {
        worker.zone_key == node_key
      })
      let related_executions = executions.filter(fn(execution) {
        node_matches_execution(node_key, execution.book_id, execution.status)
      })
      [
        p("Zone: \{node.title}"),
        p("Footprint: \{node.width}x\{node.height}"),
        p("Assets: \{node.asset_paths.length()}"),
        p("Workers present: \{related_workers.length()}"),
        p("Execution records: \{related_executions.length()}"),
        render_worker_roster(dispatch, related_workers),
        button(
          class="inspector-action",
          on_click=dispatch(SelectOverview),
          "Back To Overview",
        ),
      ]
    }
    Worker(worker_id) =>
      match find_worker(workers, worker_id) {
        Some(worker) => {
          let book_execution = find_book_execution(executions, worker.book_id)
          let lifecycle = match book_execution {
            Some(execution) =>
              "Book lifecycle: \{execution.status.to_string()} / \{execution.summary}"
            None => "Book lifecycle: no execution record visible."
          }
          [
            p("Role: \{worker.role}"),
            p("Status: \{worker.status.to_string()}"),
            p("Zone: \{worker.zone_key}"),
            p("Energy: \{worker.energy}%"),
            p("Load: \{worker.load}%"),
            p(worker.summary),
            p(lifecycle),
            button(
              class="inspector-action",
              on_click=dispatch(RelieveQueue),
              "Relieve Queue",
            ),
            button(
              class="inspector-action",
              on_click=dispatch(StabilityDrill),
              "Stability Drill",
            ),
            button(
              class="inspector-action",
              on_click=dispatch(SelectOverview),
              "Back To Overview",
            ),
          ]
        }
        None => [p("The selected worker is no longer visible in the scene.")]
      }
  }
}

///|
fn render_inspector(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  section(class="inspector-panel", [
    h2(selection_title(model.selection)),
    div(
      class="inspector-body",
      selection_body(dispatch, model, scene, workers, executions),
    ),
  ])
}

///|
fn render_scene(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let state = state_for_model(model)
  let scene = town_scene(model)
  let workers = workers_for_model(model)
  let executions = state.executions
  let alerts = all_alerts(scene, model)
  let scene_style = ["width: \{scene.width}px", "height: \{scene.height}px"]
  let scene_frame_style = ["--scene-width: \{scene.width}px"]
  let selected_node_key = match model.selection {
    Node(node_key) => Some(node_key)
    _ => None
  }
  let selected_worker_id = match model.selection {
    Worker(worker_id) => Some(worker_id)
    _ => None
  }
  let worker_avatars : Array[@rabbita.Html] = []
  for i in 0..<workers.length() {
    let worker = workers[i]
    worker_avatars.push(
      render_worker_avatar(
        dispatch,
        scene,
        worker,
        i,
        selected_worker_id == Some(worker.id),
      ),
    )
  }
  section(class="town-shell", [
    header(class="town-header", [
      div(class="title-block", [
        p(class="eyebrow", "Moontown"),
        h1(scene.title),
        p(
          class="summary",
          "A pixel-art always-on AI town: mayor supervision, resident agents, district services, and virtual-physical feedback loops.",
        ),
        render_controls(dispatch, model),
      ]),
      render_alerts(alerts),
    ]),
    section(class="metric-grid", [
      render_meter("Budget Reserve", model.budget, "tone-budget"),
      render_meter("Worker Energy", model.energy, "tone-energy"),
      render_meter("Queue Pressure", model.pressure, "tone-pressure"),
      render_meter("Town Stability", model.stability, "tone-stability"),
    ]),
    render_civic_context(model),
    render_runtime_bar(model, workers, executions),
    render_civic_modules(model),
    render_resident_agents(model),
    render_civic_quests(model),
    render_social_talent(model),
    render_bridge_contract(model),
    main_(class="town-main", [
      div(class="scene-column", [
        section(class="scene-frame-shell", [
          div(class="scene-stage-rail", execution_stage_cards(executions)),
          p(
            class="scene-hint",
            "Scroll the viewport on smaller screens, then select a zone or worker to inspect the live pipeline state.",
          ),
          div(class="scene-frame", style=scene_frame_style, [
            div(class="scene-stage", style=scene_style, [
              img(
                class="scene-background",
                src=scene.background_path,
                alt="\{scene.title} background",
                loading="eager",
                no_children(),
              ),
              div(class="scene-overlay", [
                div(
                  class="scene-nodes-layer",
                  scene.nodes.map(node => {
                    render_node(
                      dispatch,
                      node,
                      selected_node_key == Some(node.key),
                    )
                  }),
                ),
                div(class="scene-workers-layer", worker_avatars),
              ]),
            ]),
          ]),
        ]),
      ]),
      div(class="sidebar-column", [
        render_inspector(dispatch, model, scene, workers, executions),
        render_feed(feed_items(model, workers, executions)),
        aside(class="scene-legend", [
          h2("Legend"),
          p("City Hall is the mayor runtime and policy anchor."),
          p("Moonbook houses hold keeper-owned domain planning."),
          p(
            "Worker avatars now move between yard, hall, books, and anomaly response.",
          ),
          p(
            "Actions on the header feed directly back into queue pressure and town stability.",
          ),
        ]),
      ]),
    ]),
  ])
}

///|
fn count_execution_status(
  executions : Array[@core.TaskExecutionRecord],
  status : @core.TaskExecutionStatus,
) -> Int {
  let mut count = 0
  for execution in executions {
    if execution.status == status {
      count += 1
    }
  }
  count
}

///|
fn running_execution_count(
  executions : Array[@core.TaskExecutionRecord],
) -> Int {
  let mut count = 0
  for execution in executions {
    match execution.status {
      @core.TaskExecutionStatus::RunConfirmed
      | @core.TaskExecutionStatus::Running
      | @core.TaskExecutionStatus::AwaitingPersistence
      | @core.TaskExecutionStatus::ReviewQueued
      | @core.TaskExecutionStatus::Stale => count += 1
      _ => ()
    }
  }
  count
}

///|
fn node_matches_execution(
  node_key : String,
  book_id : String,
  status : @core.TaskExecutionStatus,
) -> Bool {
  match node_key {
    "city-hall" =>
      status == @core.TaskExecutionStatus::PacketReady ||
      status == @core.TaskExecutionStatus::ProposalImported ||
      status == @core.TaskExecutionStatus::RunConfirmed
    "anomaly-corner" =>
      status == @core.TaskExecutionStatus::Failed ||
      status == @core.TaskExecutionStatus::Stale ||
      status == @core.TaskExecutionStatus::ReviewQueued
    "book-coding" => book_id == "coding"
    "book-finance" => book_id == "finance"
    "worker-yard" =>
      status == @core.TaskExecutionStatus::AwaitingPersistence ||
      status == @core.TaskExecutionStatus::Completed
    _ => node_key == "book-\{book_id}"
  }
}

///|
fn find_book_execution(
  executions : Array[@core.TaskExecutionRecord],
  book_id : String,
) -> @core.TaskExecutionRecord? {
  for execution in executions {
    if execution.book_id == book_id {
      return Some(execution)
    }
  }
  None
}

///|
fn main {
  let (dispatch, app) = @rabbita.cell_with_dispatch(
    model=init_model(),
    update~,
    view=(dispatch, model) => render_scene(dispatch, model),
  )
  @rabbita.new(app)..with_init(schedule_tick(dispatch)).mount("app")
}
