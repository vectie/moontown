///|
using @html {
  article,
  aside,
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
fn town_scene() -> @ui.SceneRenderModel {
  let state = demo_state()
  let report = @health.inspect_town(state)
  @ui.build_scene_render(@ui.build_dashboard(state, report))
}

///|
fn demo_state() -> @core.TownState {
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
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-review",
      name="Review Owl",
      book_id="coding",
      role=@core.WorkerRole::Reviewer,
      capabilities=["review", "moonbit"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-ledger",
      name="Ledger Fox",
      book_id="finance",
      role=@core.WorkerRole::Specialist,
      capabilities=["ledgers", "reporting"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-memory",
      name="Archive Cat",
      book_id="finance",
      role=@core.WorkerRole::MemoryKeeper,
      capabilities=["reporting", "planning"],
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
    ),
  )
  state
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
fn render_scene(scene : @ui.SceneRenderModel) -> @rabbita.Html {
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
  let app = @rabbita.static_cell(render_scene(town_scene()))
  @rabbita.new(app).mount(target)
}
