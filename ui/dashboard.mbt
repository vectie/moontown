///|
pub struct AlertBanner {
  level : String
  text : String
} derive(Show, Eq)

///|
pub struct DashboardSection {
  title : String
  lines : Array[String]
} derive(Show, Eq)

///|
pub struct TownMapPlace {
  key : String
  title : String
  kind : SceneAreaKind
  subtitle : String
  x : Int
  y : Int
  width : Int
  height : Int
  asset_paths : Array[String]
  lines : Array[String]
} derive(Show, Eq)

///|
pub struct DashboardModel {
  title : String
  alerts : Array[AlertBanner]
  scene_layout : TownSceneLayout
  town_map : Array[TownMapPlace]
  sections : Array[DashboardSection]
} derive(Show, Eq)

///|
pub fn build_dashboard(
  town : @core.TownState,
  report : @health.HealthReport,
) -> DashboardModel {
  let alerts : Array[AlertBanner] = []
  for anomaly in report.anomalies {
    alerts.push({ level: "warning", text: anomaly.detail })
  }
  let scene_layout = default_town_scene_layout()
  let town_map = build_town_map(scene_layout, town, report)
  let sections = [
    {
      title: "Books",
      lines: town.books.map(book => "\{book.id}: \{book.workspace_root}"),
    },
    {
      title: "Workers",
      lines: town.workers.map(worker => {
        "\{worker.id}: \{worker.status.to_string()}"
      }),
    },
    {
      title: "Tasks",
      lines: town.tasks.map(task => "\{task.id}: \{task.status.to_string()}"),
    },
    {
      title: "Executions",
      lines: town.executions.map(execution => {
        let proposal = execution.proposal_id.unwrap_or("draft")
        let run = execution.run_id.unwrap_or("not-started")
        "\{execution.task_id}: \{execution.status.to_string()} / proposal=\{proposal} / run=\{run}"
      }),
    },
  ]
  { title: town.config.name, alerts, scene_layout, town_map, sections }
}

///|
pub fn render_dashboard(model : DashboardModel) -> String {
  let builder = StringBuilder::new()
  builder.write_string("Dashboard / \{model.title}\n")
  for alert in model.alerts {
    builder.write_string("! [\{alert.level}] \{alert.text}\n")
  }
  builder.write_string("\n## Town Map\n")
  builder.write_string(
    "- scene: \{model.scene_layout.width}x\{model.scene_layout.height} / \{model.scene_layout.background.path}\n",
  )
  for place in model.town_map {
    builder.write_string("- \{place.title}: \{place.subtitle}\n")
    builder.write_string(
      "  frame: \{place.x},\{place.y} \{place.width}x\{place.height} / kind=\{place.kind.to_string()}\n",
    )
    if !place.asset_paths.is_empty() {
      let assets_line = join_with_comma(place.asset_paths)
      builder.write_string("  assets: \{assets_line}\n")
    }
    for line in place.lines {
      builder.write_string("  \{line}\n")
    }
  }
  for section in model.sections {
    builder.write_string("\n## \{section.title}\n")
    for line in section.lines {
      builder.write_string("- \{line}\n")
    }
  }
  builder.to_string()
}

///|
fn build_town_map(
  layout : TownSceneLayout,
  town : @core.TownState,
  report : @health.HealthReport,
) -> Array[TownMapPlace] {
  let places : Array[TownMapPlace] = []
  places.push(build_gate(layout, town))
  places.push(build_city_hall(layout, town, report))
  for book in town.books {
    places.push(build_book_house(layout, town, book))
  }
  places.push(build_worker_yard(layout, town))
  places.push(build_anomaly_corner(layout, report))
  places
}

///|
fn build_gate(layout : TownSceneLayout, town : @core.TownState) -> TownMapPlace {
  let area = require_area(layout, "gate")
  {
    key: area.key,
    title: area.title,
    kind: area.kind,
    subtitle: "Entry marker for the current town scene",
    x: area.x,
    y: area.y,
    width: area.width,
    height: area.height,
    asset_paths: resolve_asset_paths(layout, area.asset_keys),
    lines: ["town: \{town.config.name}", "books online: \{town.books.length()}"],
  }
}

///|
fn build_city_hall(
  layout : TownSceneLayout,
  town : @core.TownState,
  report : @health.HealthReport,
) -> TownMapPlace {
  let area = require_area(layout, "city-hall")
  let health_line = if report.anomalies.is_empty() {
    "status: calm routes and clean patrol"
  } else {
    "status: \{report.anomalies.length()} anomaly signals on the board"
  }
  {
    key: area.key,
    title: area.title,
    kind: area.kind,
    subtitle: "Mayor claw runs strategic routing, patrol, and keeper handoffs",
    x: area.x,
    y: area.y,
    width: area.width,
    height: area.height,
    asset_paths: resolve_asset_paths(layout, area.asset_keys),
    lines: [
      "role: mayor / planner-only / limited tools",
      "memory: town-global strategic scope",
      health_line,
      "packets: \{count_execution_status(town, @core.TaskExecutionStatus::PacketReady)} ready",
      "imports: \{count_execution_status(town, @core.TaskExecutionStatus::ProposalImported)} imported",
      "runs: \{running_like_count(town)} active lifecycle records",
    ],
  }
}

///|
fn build_book_house(
  layout : TownSceneLayout,
  town : @core.TownState,
  book : @core.BookRef,
) -> TownMapPlace {
  let area = require_area(layout, book_area_key(book.id))
  let worker_count = count_book_workers(town, book.id)
  let task_count = count_book_tasks(town, book.id)
  {
    key: area.key,
    title: book.name,
    kind: area.kind,
    subtitle: "keeper-planned domain house at \{book.workspace_root}",
    x: area.x,
    y: area.y,
    width: area.width,
    height: area.height,
    asset_paths: resolve_asset_paths(layout, area.asset_keys),
    lines: [
      "memory: \{book.memory_scope.to_string()}",
      "workers: \{worker_count}",
      "tasks: \{task_count}",
      "executions: \{count_book_executions(town, book.id)}",
      "purpose: \{book.purpose}",
    ],
  }
}

///|
fn build_worker_yard(
  layout : TownSceneLayout,
  town : @core.TownState,
) -> TownMapPlace {
  let area = require_area(layout, "worker-yard")
  let lines : Array[String] = []
  for worker in town.workers {
    lines.push(
      "\{worker.id} -> \{worker.book_id} / \{worker.role.to_string()} / \{worker.status.to_string()}",
    )
  }
  for execution in town.executions {
    let proposal = execution.proposal_id.unwrap_or("draft")
    lines.push(
      "packet \{execution.packet_id} / \{execution.status.to_string()} / proposal=\{proposal}",
    )
  }
  {
    key: area.key,
    title: area.title,
    kind: area.kind,
    subtitle: "execution claws wait here before keeper-directed work",
    x: area.x,
    y: area.y,
    width: area.width,
    height: area.height,
    asset_paths: resolve_asset_paths(layout, area.asset_keys),
    lines,
  }
}

///|
fn build_anomaly_corner(
  layout : TownSceneLayout,
  report : @health.HealthReport,
) -> TownMapPlace {
  let area = require_area(layout, "anomaly-corner")
  let lines : Array[String] = []
  if report.anomalies.is_empty() {
    lines.push("quiet: no worker alarms in the town")
  } else {
    for anomaly in report.anomalies {
      lines.push("\{anomaly.title}: \{anomaly.detail}")
    }
  }
  {
    key: area.key,
    title: area.title,
    kind: area.kind,
    subtitle: "visible trouble signals and recovery prompts",
    x: area.x,
    y: area.y,
    width: area.width,
    height: area.height,
    asset_paths: resolve_asset_paths(layout, area.asset_keys),
    lines,
  }
}

///|
fn book_area_key(book_id : String) -> String {
  match book_id {
    "coding" => "book-coding"
    "finance" => "book-finance"
    _ => "worker-yard"
  }
}

///|
fn require_area(layout : TownSceneLayout, key : String) -> SceneArea {
  for area in layout.areas {
    if area.key == key {
      return area
    }
  }
  panic()
}

///|
fn resolve_asset_paths(
  layout : TownSceneLayout,
  asset_keys : Array[String],
) -> Array[String] {
  let paths : Array[String] = []
  for asset_key in asset_keys {
    for asset in layout.assets {
      if asset.key == asset_key {
        paths.push(asset.path)
      }
    }
  }
  paths
}

///|
fn join_with_comma(parts : Array[String]) -> String {
  let builder = StringBuilder::new()
  let mut index = 0
  for part in parts {
    if index > 0 {
      builder.write_string(", ")
    }
    builder.write_string(part)
    index += 1
  }
  builder.to_string()
}

///|
fn count_book_workers(town : @core.TownState, book_id : String) -> Int {
  let mut count = 0
  for worker in town.workers {
    if worker.book_id == book_id {
      count += 1
    }
  }
  count
}

///|
fn count_book_tasks(town : @core.TownState, book_id : String) -> Int {
  let mut count = 0
  for task in town.tasks {
    if task.book_id == book_id {
      count += 1
    }
  }
  count
}

///|
fn count_book_executions(town : @core.TownState, book_id : String) -> Int {
  let mut count = 0
  for execution in town.executions {
    if execution.book_id == book_id {
      count += 1
    }
  }
  count
}

///|
fn count_execution_status(
  town : @core.TownState,
  status : @core.TaskExecutionStatus,
) -> Int {
  let mut count = 0
  for execution in town.executions {
    if execution.status == status {
      count += 1
    }
  }
  count
}

///|
fn running_like_count(town : @core.TownState) -> Int {
  let mut count = 0
  for execution in town.executions {
    match execution.status {
      @core.TaskExecutionStatus::RunConfirmed
      | @core.TaskExecutionStatus::Running
      | @core.TaskExecutionStatus::AwaitingPersistence
      | @core.TaskExecutionStatus::ReviewQueued => count += 1
      _ => ()
    }
  }
  count
}
