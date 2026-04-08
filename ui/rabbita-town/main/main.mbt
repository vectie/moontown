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
priv struct Model {
  tick : Int
  paused : Bool
}

///|
priv enum Msg {
  Tick
  TogglePause
  Step
}

///|
fn init_model() -> Model {
  { tick: 0, paused: false }
}

///|
fn schedule_tick(dispatch : Dispatch[Msg]) -> Cmd {
  @rabbita.delay(dispatch(Tick), 1400)
}

///|
fn update(dispatch : Dispatch[Msg], msg : Msg, model : Model) -> (Cmd, Model) {
  match msg {
    Tick => {
      let next = { ..model, tick: model.tick + 1 }
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
        (@rabbita.none, { ..model, tick: model.tick + 1 })
      } else {
        (@rabbita.none, model)
      }
  }
}

///|
fn town_scene(model : Model) -> @ui.SceneRenderModel {
  let state = demo_state(model.tick)
  let report = @health.inspect_town(state)
  @ui.build_scene_render(@ui.build_dashboard(state, report))
}

///|
fn demo_state(tick : Int) -> @core.TownState {
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
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-harness",
      name="Harness Hound",
      book_id="coding",
      role=@core.WorkerRole::Harness,
      capabilities=["moonbit", "git", "testing"],
      status=worker_status_for(tick, 0),
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-review",
      name="Review Owl",
      book_id="coding",
      role=@core.WorkerRole::Reviewer,
      capabilities=["review", "moonbit"],
      status=worker_status_for(tick, 1),
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-ledger",
      name="Ledger Fox",
      book_id="finance",
      role=@core.WorkerRole::Specialist,
      capabilities=["ledgers", "reporting"],
      status=worker_status_for(tick, 2),
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-memory",
      name="Archive Cat",
      book_id="finance",
      role=@core.WorkerRole::MemoryKeeper,
      capabilities=["reporting", "planning"],
      status=worker_status_for(tick, 3),
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-town-layer",
      book_id="coding",
      title="Implement town orchestration layer",
      prompt="Host multiple moonbooks and route coding work to the right claw worker.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Harness),
      required_capabilities=["moonbit", "git"],
      status=task_status_for(tick, 0),
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-review-contract",
      book_id="coding",
      title="Review delegation contract",
      prompt="Check that the worker protocol is still safe for multi-book orchestration.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Reviewer),
      required_capabilities=["review", "moonbit"],
      status=task_status_for(tick, 1),
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-ledger-close",
      book_id="finance",
      title="Close daily finance loop",
      prompt="Summarize transactions, update balances, and prepare the next-day brief.",
      domain=@core.WorkDomain::Finance,
      required_role=Some(@core.WorkerRole::Specialist),
      required_capabilities=["ledgers", "reporting"],
      status=task_status_for(tick, 2),
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-finance-memory",
      book_id="finance",
      title="Capture durable finance memories",
      prompt="Store daily finance findings without leaking into the coding moonbook.",
      domain=@core.WorkDomain::Finance,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["planning", "reporting"],
      status=task_status_for(tick, 3),
    ),
  )
  state
}

///|
fn worker_status_for(tick : Int, offset : Int) -> @core.WorkerStatus {
  match (tick + offset) % 8 {
    0 => @core.WorkerStatus::Running
    1 => @core.WorkerStatus::Waiting
    2 => @core.WorkerStatus::Idle
    3 => @core.WorkerStatus::Running
    4 => @core.WorkerStatus::Blocked
    5 => @core.WorkerStatus::Waiting
    6 => @core.WorkerStatus::Idle
    _ => @core.WorkerStatus::Running
  }
}

///|
fn task_status_for(tick : Int, offset : Int) -> @core.TownTaskStatus {
  match (tick + offset) % 7 {
    0 => @core.TownTaskStatus::Pending
    1 => @core.TownTaskStatus::Assigned
    2 => @core.TownTaskStatus::Running
    3 => @core.TownTaskStatus::Running
    4 => @core.TownTaskStatus::Blocked
    5 => @core.TownTaskStatus::Assigned
    _ => @core.TownTaskStatus::Planned
  }
}

///|
fn status_chip(text : String, class_name : String) -> @rabbita.Html {
  span(class="chip \{class_name}", text)
}

///|
fn render_alerts(alerts : Array[String]) -> @rabbita.Html {
  if alerts.is_empty() {
    div(class="alert-strip", [status_chip("No active alerts", "chip-calm")])
  } else {
    div(
      class="alert-strip",
      alerts.map(alert => status_chip(alert, "chip-alert")),
    )
  }
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
fn render_node(node : @ui.SceneRenderNode) -> @rabbita.Html {
  let style = [
    "left: \{node.x}px",
    "top: \{node.y}px",
    "width: \{node.width}px",
    "height: \{node.height}px",
  ]
  article(class="scene-node \{node.class_name}", style~, [
    div(
      class="asset-stack",
      node.asset_paths.map(path => render_asset(path, node.title)),
    ),
    div(class="scene-card", [
      h3(node.title),
      p(class="scene-node-key", node.key),
      div(class="scene-lines", node.lines.map(line => p(line))),
    ]),
  ])
}

///|
fn render_controls(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let status = if model.paused { "Paused" } else { "Live" }
  let action_label = if model.paused { "Resume" } else { "Pause" }
  div(class="control-strip", [
    status_chip(status, if model.paused { "chip-alert" } else { "chip-live" }),
    status_chip(simulation_time_label(model.tick), "chip-clock"),
    status_chip("Tick \{model.tick}", "chip-neutral"),
    button(class="control-button", on_click=dispatch(TogglePause), action_label),
    button(class="control-button", on_click=dispatch(Step), "Step"),
  ])
}

///|
fn render_scene(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let scene = town_scene(model)
  let scene_style = ["width: \{scene.width}px", "height: \{scene.height}px"]
  section(class="town-shell", [
    header(class="town-header", [
      div(class="title-block", [
        p(class="eyebrow", "Moontown"),
        h1(scene.title),
        p(
          class="summary",
          "Mayor hall, moonbook houses, worker yard, and anomaly corner rendered through Rabbita.",
        ),
        render_controls(dispatch, model),
      ]),
      render_alerts(scene.alerts),
    ]),
    main_(class="town-main", [
      div(class="scene-frame", style=scene_style, [
        img(
          class="scene-background",
          src=scene.background_path,
          alt="\{scene.title} background",
          loading="eager",
          no_children(),
        ),
        div(class="scene-overlay", scene.nodes.map(render_node)),
      ]),
      aside(class="scene-legend", [
        h2("Legend"),
        p("City hall is the mayor runtime."),
        p("Each moonbook house is a domain keeper surface."),
        p("The worker yard is where execution claws idle before dispatch."),
        p("The anomaly corner surfaces drift, faults, and recovery signals."),
      ]),
    ]),
  ])
}

///|
pub fn mount_app(target? : String = "app") -> Unit {
  let (dispatch, app) = @rabbita.cell_with_dispatch(
    model=init_model(),
    update~,
    view=(dispatch, model) => render_scene(dispatch, model),
  )
  @rabbita.new(app)..with_init(schedule_tick(dispatch)).mount(target)
}
