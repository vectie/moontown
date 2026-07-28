///|
priv struct ModuleWorkStation {
  key : String
  label : String
  detail : String
  count : Int
  state : String
  tasks : Array[EnergyValleyRuntimeWorkItem]
}

///|
priv enum ModuleWorkStage {
  Intake
  Discovery
  Synthesis
  Review
  Delivery
  Recovery
} derive(Eq)

///|
fn module_work_optional_count_is_positive(value : Int?) -> Bool {
  match value {
    Some(count) => count > 0
    None => false
  }
}

///|
fn module_work_task_has_synthesis_evidence(
  task : EnergyValleyRuntimeWorkItem,
) -> Bool {
  if !task.artifacts.is_empty() || !task.resultLinks.unwrap_or([]).is_empty() {
    return true
  }
  match task.progress {
    Some(progress) =>
      module_work_optional_count_is_positive(progress.acceptedFacts) ||
      module_work_optional_count_is_positive(progress.pagesChanged) ||
      progress.bookChanged.unwrap_or(false)
    None => false
  }
}

///|
fn module_work_stage_for_task(
  task : EnergyValleyRuntimeWorkItem,
) -> ModuleWorkStage {
  match task.status {
    "queued" => Intake
    "assigned" => Discovery
    "running" =>
      if module_work_task_has_synthesis_evidence(task) {
        Synthesis
      } else {
        Discovery
      }
    "waiting_review" => Review
    "completed" => Delivery
    "blocked" | "failed" => Recovery
    _ => Recovery
  }
}

///|
fn module_work_station(
  key : String,
  label : String,
  detail : String,
  tasks : Array[EnergyValleyRuntimeWorkItem],
  active_state : String,
) -> ModuleWorkStation {
  {
    key,
    label,
    detail,
    count: tasks.length(),
    state: if !tasks.is_empty() {
      active_state
    } else {
      "quiet"
    },
    tasks,
  }
}

///|
fn module_work_tasks_for_stage(
  tasks : Array[EnergyValleyRuntimeWorkItem],
  stage : ModuleWorkStage,
) -> Array[EnergyValleyRuntimeWorkItem] {
  tasks.filter(task => module_work_stage_for_task(task) == stage)
}

///|
fn module_work_stations(
  runtime : EnergyValleyRuntimeState,
  civic : WenyuTownModule,
) -> Array[ModuleWorkStation] {
  let tasks = energy_valley_runtime_live_tasks_for_module(runtime, civic)
  [
    module_work_station(
      "intake",
      "Intake",
      "Durable requests and queued work enter here.",
      module_work_tasks_for_stage(tasks, Intake),
      "waiting",
    ),
    module_work_station(
      "discovery",
      "Discovery",
      "Agents gather sources, context, and tool results.",
      module_work_tasks_for_stage(tasks, Discovery),
      "running",
    ),
    module_work_station(
      "synthesis",
      "Synthesis",
      "Working evidence becomes a reviewable result.",
      module_work_tasks_for_stage(tasks, Synthesis),
      "running",
    ),
    module_work_station(
      "review",
      "Review",
      "Human or keeper decisions remain visible here.",
      module_work_tasks_for_stage(tasks, Review),
      "review",
    ),
    module_work_station(
      "delivery",
      "Delivery",
      "Recorded results and artifacts leave the building.",
      module_work_tasks_for_stage(tasks, Delivery),
      "complete",
    ),
    module_work_station(
      "recovery",
      "Recovery",
      "Blocked or failed work receives explicit attention.",
      module_work_tasks_for_stage(tasks, Recovery),
      "blocked",
    ),
  ]
}

///|
fn module_interior_seed(civic : WenyuTownModule) -> Int {
  let mut seed = civic.grid_x * 17 +
    civic.grid_y * 31 +
    civic.footprint_w * 7 +
    civic.footprint_h * 11
  for char in civic.id {
    seed = (seed * 31 + char.to_int()) % 1009
  }
  if seed < 0 {
    -seed
  } else {
    seed
  }
}

///|
fn module_work_station_slot(civic : WenyuTownModule, index : Int) -> Int {
  (module_interior_seed(civic) + index) % 6
}

///|
fn module_work_station_state_label(station : ModuleWorkStation) -> String {
  match station.state {
    "waiting" => "Queued \{station.count}"
    "running" => "Active \{station.count}"
    "review" => "Review \{station.count}"
    "complete" => "Ready \{station.count}"
    "blocked" => "Blocked \{station.count}"
    _ => "Quiet"
  }
}

///|
fn render_module_work_station(
  civic : WenyuTownModule,
  station : ModuleWorkStation,
  index : Int,
) -> @rabbita.Html {
  article(
    class="module-work-station station-\{station.key} station-\{station.state}",
    style=["order: \{module_work_station_slot(civic, index)}"],
    [
      span(class="module-work-station-mark", no_children()),
      div(class="module-work-station-copy", [
        h3(station.label),
        p(station.detail),
      ]),
      span(
        class="module-work-station-state",
        module_work_station_state_label(station),
      ),
    ],
  )
}

///|
fn render_module_work_floor(
  civic : WenyuTownModule,
  runtime : EnergyValleyRuntimeState,
) -> @rabbita.Html {
  let stations = module_work_stations(runtime, civic)
  let rows : Array[@rabbita.Html] = []
  for index in 0..<stations.length() {
    rows.push(render_module_work_station(civic, stations[index], index))
  }
  section(class="module-work-floor", [
    header(class="module-work-floor-header", [
      div([
        p(class="eyebrow", "Procedural work floor"),
        h2("Real work stations"),
      ]),
      span(
        class="module-work-floor-seed",
        "Layout \{module_interior_seed(civic)}",
      ),
    ]),
    p(
      class="module-work-floor-intro",
      energy_valley_runtime_phase_detail(runtime),
    ),
    div(class="module-work-station-grid", rows),
    render_energy_valley_module_work_lens(runtime, civic),
    @html.details(class="module-room-fixtures", [
      @html.summary("Room fixtures"),
      div(class="interior-floor", module_interior_furniture(civic)),
    ]),
  ])
}
