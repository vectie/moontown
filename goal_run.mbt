///|
pub async fn run_goal(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  run_goal_into_state(
    state,
    goal,
    book_id~,
    task_limit_per_book~,
    snapshot_path~,
    book_catalog_path~,
  )
}

///|
async fn run_goal_into_state(
  state : @core.TownState,
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mayor = demo_mayor()
  let plan = mayor.plan_goal(catalog, goal, explicit_book_id=book_id)
  let books : Array[@core.BookRef] = []
  for lane in plan.lanes {
    books.push(lane.entry.to_book_ref())
  }
  register_demo_books(state, books)
  register_demo_workers(state)
  let event_index = state.events.length()
  state.record_event(
    @core.TownEvent::new(
      id="event-goal-\{event_index}",
      kind="goal",
      detail="Accepted town goal: \{goal}",
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-goal-plan-\{event_index}",
      kind="planning",
      detail=plan.summary,
    ),
  )
  persist_town_checkpoint(state, snapshot_path)
  let limit = if task_limit_per_book < 1 { 1 } else { task_limit_per_book }
  let launches : Array[GoalBookLaunch] = []
  for lane in plan.lanes {
    match prepare_goal_book_launch(state, lane.entry, lane.objective, limit) {
      Some(launch) => launches.push(launch)
      None => ()
    }
  }
  for launch in launches {
    launch_goal_book(state, mayor, launch)
    persist_town_checkpoint(state, snapshot_path)
  }
  wait_for_goal_settle(state, mayor, catalog, snapshot_path)
  write_town_goal_synthesis(state, goal, plan, snapshot_path)
  persist_town_checkpoint(state, snapshot_path)
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  state
}

///|
pub async fn render_goal_run(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let state = run_goal(
    goal,
    book_id~,
    task_limit_per_book~,
    snapshot_path~,
    book_catalog_path~,
  )
  render_state_dashboard(state)
}

///|
pub async fn supervise_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let snapshot = @storage.load_snapshot_file(snapshot_path)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mayor = demo_mayor()
  match snapshot {
    Some(saved) => {
      let state = saved.town
      run_supervision_cycle(state, mayor, catalog)
      persist_town_checkpoint(state, snapshot_path)
      render_state_dashboard(state)
    }
    None => "No saved town snapshot exists at \{snapshot_path}."
  }
}
