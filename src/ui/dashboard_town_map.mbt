///|
fn build_town_map(
  layout : TownSceneLayout,
  town : @core.TownState,
  report : @health.HealthReport,
) -> Array[TownMapPlace] {
  let places : Array[TownMapPlace] = []
  places.push(build_gate(layout, town))
  places.push(build_city_hall(layout, town, report))
  let book_count = visible_book_count(town.books)
  let mut visible_index = 0
  for book in town.books {
    if !is_mayor_book(book) {
      places.push(
        build_book_house(layout, town, book, visible_index, book_count),
      )
      visible_index += 1
    }
  }
  places.push(build_worker_yard(layout, town))
  places.push(build_anomaly_corner(layout, report))
  places
}

///|
fn is_mayor_book(book : @core.BookRef) -> Bool {
  book.id == "town" || book.id == "moontown" || book.id == "mayor"
}

///|
fn visible_book_count(books : Array[@core.BookRef]) -> Int {
  let mut count = 0
  for book in books {
    if !is_mayor_book(book) {
      count = count + 1
    }
  }
  count
}

///|
fn build_gate(layout : TownSceneLayout, town : @core.TownState) -> TownMapPlace {
  let area = require_area(layout, "gate")
  town_map_place_from_area(
    layout,
    area,
    "Entry marker for the current town scene",
    ["town: \{town.config.name}", "books online: \{town.books.length()}"],
  )
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
  town_map_place_from_area(
    layout,
    area,
    "Mayor claw runs strategic routing, patrol, and keeper handoffs",
    [
      "role: mayor / planner-only / limited tools",
      "memory: town-global strategic scope",
      health_line,
      "packets: \{count_execution_status(town, PacketReady)} ready",
      "imports: \{count_execution_status(town, ProposalImported)} imported",
      "runs: \{running_like_count(town)} active lifecycle records",
    ],
  )
}

///|
fn build_book_house(
  layout : TownSceneLayout,
  town : @core.TownState,
  book : @core.BookRef,
  index : Int,
  total_books : Int,
) -> TownMapPlace {
  let area = area_for_book(layout, book, index, total_books)
  let activity = inspect_book_house_activity(town, book.id)
  town_map_place_from_area(
    layout,
    { ..area, title: book.name },
    "keeper-planned domain house at \{book.workspace_root}",
    [
      "memory: \{book.memory_scope.to_string()}",
      "workers: \{activity.worker_count}",
      "tasks: \{activity.task_count}",
      "executions: \{activity.execution_count}",
      "active stage: \{activity.active_stage}",
      "purpose: \{book.purpose}",
    ],
  )
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
    let stage = execution_stage_label(town, execution)
    lines.push(
      "packet \{execution.packet_id} / \{execution.status.to_string()} / stage=\{stage} / proposal=\{proposal}",
    )
  }
  town_map_place_from_area(
    layout, area, "execution claws wait here before keeper-directed work", lines,
  )
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
  town_map_place_from_area(
    layout, area, "visible trouble signals and recovery prompts", lines,
  )
}
