///|
fn visual_building_projection(
  state : @core.TownState,
  book : @core.BookRef,
) -> VisualBuildingProjection {
  let activity = VisualBuildingActivity::for_book(state, book.id)
  {
    book_id: book.id,
    title: book.name,
    zone_key: "book-\{book.id}",
    running_count: activity.running_count,
    waiting_count: activity.waiting_count,
    review_count: activity.review_count,
    blocked_count: activity.blocked_count,
    completed_count: activity.completed_count,
    effect: activity.effect(),
    message: activity.message(book),
  }
}

///|
fn visual_module_projection(
  building : VisualBuildingProjection,
  agents : Array[VisualAgentProjection],
) -> VisualModuleProjection {
  let activity : VisualBuildingActivity = {
    running_count: building.running_count,
    waiting_count: building.waiting_count,
    review_count: building.review_count,
    blocked_count: building.blocked_count,
    completed_count: building.completed_count,
  }
  {
    module_id: visual_module_id_from_book_id(building.book_id),
    book_id: building.book_id,
    title: building.title,
    status: activity.module_status(),
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
fn visual_count_book_phases(
  state : @core.TownState,
  book_id : String,
  predicate : (String) -> Bool,
) -> Int {
  let mut count = 0
  for worker in state.workers {
    if worker.book_id == book_id {
      let phase = visual_agent_phase(
        worker,
        visual_latest_execution_for_worker(state, worker),
      )
      if predicate(phase) {
        count += 1
      }
    }
  }
  count
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
