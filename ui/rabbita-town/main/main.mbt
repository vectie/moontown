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
} derive(Show, Eq)

///|
priv enum Selection {
  Overview
  Node(String)
  Worker(String)
} derive(Show, Eq)

///|
priv struct Model {
  tick : Int
  paused : Bool
  strategy : Strategy
  selection : Selection
  budget : Int
  energy : Int
  pressure : Int
  stability : Int
} derive(Show, Eq)

///|
priv enum Msg {
  Tick
  TogglePause
  Step
  SelectWorker(String)
  SelectNode(String)
  SelectOverview
  SetStrategy(Strategy)
  InjectBudget
  RelieveQueue
  StabilityDrill
} derive(Show, Eq)

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
} derive(Show, Eq)

///|
priv struct FeedItem {
  title : String
  detail : String
  tone : String
} derive(Show, Eq)

///|
fn init_model() -> Model {
  {
    tick: 0,
    paused: false,
    strategy: Strategy::Balanced,
    selection: Selection::Overview,
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
  let next_budget = clamp_metric(model.budget + budget_delta + budget_bonus)
  let next_energy = clamp_metric(
    model.energy + energy_delta - overload_penalty + energy_bonus,
  )
  let next_pressure = clamp_metric(
    model.pressure +
    pressure_delta +
    brittle_penalty +
    energy_penalty -
    pressure_relief,
  )
  let next_stability = clamp_metric(
    model.stability +
    stability_delta -
    overload_penalty -
    budget_penalty +
    stability_bonus,
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
  let state = demo_state(model)
  let report = @health.inspect_town(state)
  @ui.build_scene_render(@ui.build_dashboard(state, report))
}

///|
fn demo_state(model : Model) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  state.register_book(
    @core.BookRef::new(
      id="coding",
      name="Moonbook / Coding",
      purpose="Harness engineering for source work, repo memory, and execution policy.",
      workspace_root="/workspace/coding",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["moonbit", "repo", "harness"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="finance",
      name="Moonbook / Finance",
      purpose="Private daily finance operations with isolated memory and task artifacts.",
      workspace_root="/workspace/finance",
      memory_scope=@core.MemoryScope::TaskEphemeral,
      tags=["ledger", "private", "daily"],
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
  state
}

///|
fn worker_role_from_id(worker_id : String) -> @core.WorkerRole {
  match worker_id {
    "claw-harness" => @core.WorkerRole::Harness
    "claw-review" => @core.WorkerRole::Reviewer
    "claw-ledger" => @core.WorkerRole::Specialist
    _ => @core.WorkerRole::MemoryKeeper
  }
}

///|
fn worker_capabilities(worker_id : String) -> Array[String] {
  match worker_id {
    "claw-harness" => ["moonbit", "git", "testing"]
    "claw-review" => ["review", "moonbit"]
    "claw-ledger" => ["ledgers", "reporting"]
    _ => ["reporting", "planning"]
  }
}

///|
fn worker_sims(model : Model) -> Array[WorkerSim] {
  [
    build_worker_sim(
      model,
      id="claw-harness",
      title="Harness Hound",
      role="Harness",
      book_id="coding",
      offset=0,
    ),
    build_worker_sim(
      model,
      id="claw-review",
      title="Review Owl",
      role="Reviewer",
      book_id="coding",
      offset=1,
    ),
    build_worker_sim(
      model,
      id="claw-ledger",
      title="Ledger Fox",
      role="Specialist",
      book_id="finance",
      offset=2,
    ),
    build_worker_sim(
      model,
      id="claw-memory",
      title="Archive Cat",
      role="Memory Keeper",
      book_id="finance",
      offset=3,
    ),
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
  if model.stability < 30 && (cycle == 2 || cycle == 6) {
    @core.WorkerStatus::Blocked
  } else if model.pressure > 76 && (cycle == 1 || cycle == 4 || cycle == 7) {
    @core.WorkerStatus::Blocked
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
    @core.WorkerStatus::Waiting => "city-hall"
    @core.WorkerStatus::Offline => "gate"
    @core.WorkerStatus::Running =>
      if book_id == "finance" {
        "book-finance"
      } else {
        "book-coding"
      }
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
      "Executing keeper-issued work at load \{load}%."
    @core.WorkerStatus::Waiting => "Waiting for dispatch and context hydration."
    @core.WorkerStatus::Idle => "Cooling in the yard and recovering attention."
    @core.WorkerStatus::Blocked => "Blocked by queue pressure or town drift."
    @core.WorkerStatus::Offline => "Offline and unavailable."
  }
}

///|
fn task_specs(model : Model) -> Array[@core.TownTask] {
  [
    @core.TownTask::new(
      id="task-town-layer",
      book_id="coding",
      title="Implement town orchestration layer",
      prompt="Host multiple moonbooks and route coding work to the right claw worker.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Harness),
      required_capabilities=["moonbit", "git"],
      status=task_status_for(model, 0),
    ),
    @core.TownTask::new(
      id="task-review-contract",
      book_id="coding",
      title="Review delegation contract",
      prompt="Check that the worker protocol is still safe for multi-book orchestration.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Reviewer),
      required_capabilities=["review", "moonbit"],
      status=task_status_for(model, 1),
    ),
    @core.TownTask::new(
      id="task-ledger-close",
      book_id="finance",
      title="Close daily finance loop",
      prompt="Summarize transactions, update balances, and prepare the next-day brief.",
      domain=@core.WorkDomain::Finance,
      required_role=Some(@core.WorkerRole::Specialist),
      required_capabilities=["ledgers", "reporting"],
      status=task_status_for(model, 2),
    ),
    @core.TownTask::new(
      id="task-finance-memory",
      book_id="finance",
      title="Capture durable finance memories",
      prompt="Store daily finance findings without leaking into the coding moonbook.",
      domain=@core.WorkDomain::Finance,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["planning", "reporting"],
      status=task_status_for(model, 3),
    ),
  ]
}

///|
fn task_status_for(model : Model, offset : Int) -> @core.TownTaskStatus {
  let cycle = (model.tick + offset) % 8
  if model.pressure > 80 && (cycle == 3 || cycle == 6) {
    @core.TownTaskStatus::Blocked
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
  let status = if model.paused { "Paused" } else { "Live" }
  let action_label = if model.paused { "Resume" } else { "Pause" }
  section(class="control-hub", [
    div(class="control-strip", [
      status_chip(status, if model.paused { "chip-alert" } else { "chip-live" }),
      status_chip(simulation_time_label(model.tick), "chip-clock"),
      status_chip("Tick \{model.tick}", "chip-neutral"),
      status_chip("Mode: \{strategy_label(model.strategy)}", "chip-book"),
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
fn feed_items(model : Model, workers : Array[WorkerSim]) -> Array[FeedItem] {
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
fn selection_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
) -> Array[@rabbita.Html] {
  match model.selection {
    Overview =>
      [
        p(
          "Select a zone or worker to inspect live state. Use town actions to redirect the simulation.",
        ),
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
      [
        p("Zone: \{node.title}"),
        p("Footprint: \{node.width}x\{node.height}"),
        p("Assets: \{node.asset_paths.length()}"),
        p("Workers present: \{related_workers.length()}"),
        button(
          class="inspector-action",
          on_click=dispatch(SelectOverview),
          "Back To Overview",
        ),
      ]
    }
    Worker(worker_id) =>
      match find_worker(workers, worker_id) {
        Some(worker) =>
          [
            p("Role: \{worker.role}"),
            p("Status: \{worker.status.to_string()}"),
            p("Zone: \{worker.zone_key}"),
            p("Energy: \{worker.energy}%"),
            p("Load: \{worker.load}%"),
            p(worker.summary),
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
) -> @rabbita.Html {
  section(class="inspector-panel", [
    h2(selection_title(model.selection)),
    div(class="inspector-body", selection_body(dispatch, model, scene, workers)),
  ])
}

///|
fn render_scene(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let scene = town_scene(model)
  let workers = worker_sims(model)
  let alerts = all_alerts(scene, model)
  let scene_style = ["width: \{scene.width}px", "height: \{scene.height}px"]
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
          "A live mayor-and-keeper simulation dashboard with command actions, worker traffic, and pressure-driven feedback loops.",
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
    main_(class="town-main", [
      div(class="scene-column", [
        div(class="scene-frame", style=scene_style, [
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
                render_node(dispatch, node, selected_node_key == Some(node.key))
              }),
            ),
            div(class="scene-workers-layer", worker_avatars),
          ]),
        ]),
      ]),
      div(class="sidebar-column", [
        render_inspector(dispatch, model, scene, workers),
        render_feed(feed_items(model, workers)),
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
fn main {
  let (dispatch, app) = @rabbita.cell_with_dispatch(
    model=init_model(),
    update~,
    view=(dispatch, model) => render_scene(dispatch, model),
  )
  @rabbita.new(app)..with_init(schedule_tick(dispatch)).mount("app")
}
