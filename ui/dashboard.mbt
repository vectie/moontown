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
  title : String
  subtitle : String
  lines : Array[String]
} derive(Show, Eq)

///|
pub struct DashboardModel {
  title : String
  alerts : Array[AlertBanner]
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
  let town_map = build_town_map(town, report)
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
  ]
  { title: town.config.name, alerts, town_map, sections }
}

///|
pub fn render_dashboard(model : DashboardModel) -> String {
  let builder = StringBuilder::new()
  builder.write_string("Dashboard / \{model.title}\n")
  for alert in model.alerts {
    builder.write_string("! [\{alert.level}] \{alert.text}\n")
  }
  builder.write_string("\n## Town Map\n")
  for place in model.town_map {
    builder.write_string("- \{place.title}: \{place.subtitle}\n")
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
  town : @core.TownState,
  report : @health.HealthReport,
) -> Array[TownMapPlace] {
  let places : Array[TownMapPlace] = []
  places.push(build_city_hall(report))
  for book in town.books {
    places.push(build_book_house(town, book))
  }
  places.push(build_worker_yard(town))
  places.push(build_anomaly_corner(report))
  places
}

///|
fn build_city_hall(report : @health.HealthReport) -> TownMapPlace {
  let health_line = if report.anomalies.is_empty() {
    "status: calm routes and clean patrol"
  } else {
    "status: \{report.anomalies.length()} anomaly signals on the board"
  }
  {
    title: "City Hall",
    subtitle: "Mayor claw runs strategic routing, patrol, and keeper handoffs",
    lines: [
      "role: mayor / planner-only / limited tools", "memory: town-global strategic scope",
      health_line,
    ],
  }
}

///|
fn build_book_house(
  town : @core.TownState,
  book : @core.BookRef,
) -> TownMapPlace {
  let worker_count = count_book_workers(town, book.id)
  let task_count = count_book_tasks(town, book.id)
  {
    title: "\{book.name}",
    subtitle: "keeper-planned domain house at \{book.workspace_root}",
    lines: [
      "memory: \{book.memory_scope.to_string()}",
      "workers: \{worker_count}",
      "tasks: \{task_count}",
      "purpose: \{book.purpose}",
    ],
  }
}

///|
fn build_worker_yard(town : @core.TownState) -> TownMapPlace {
  let lines : Array[String] = []
  for worker in town.workers {
    lines.push(
      "\{worker.id} -> \{worker.book_id} / \{worker.role.to_string()} / \{worker.status.to_string()}",
    )
  }
  {
    title: "Worker Yard",
    subtitle: "execution claws wait here before keeper-directed work",
    lines,
  }
}

///|
fn build_anomaly_corner(report : @health.HealthReport) -> TownMapPlace {
  let lines : Array[String] = []
  if report.anomalies.is_empty() {
    lines.push("quiet: no worker alarms in the town")
  } else {
    for anomaly in report.anomalies {
      lines.push("\{anomaly.title}: \{anomaly.detail}")
    }
  }
  {
    title: "Anomaly Corner",
    subtitle: "visible trouble signals and recovery prompts",
    lines,
  }
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
