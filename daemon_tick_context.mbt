///|
priv struct DaemonTickPaths {
  daemon_path : String
  log_path : String
  goal_path : String
}

///|
priv struct DaemonPlanbookPhaseResult {
  planbook_summary : String
  repair_summary : String
}

///|
priv struct DaemonTickContext {
  catalog : Array[@moonbook.BookCatalogEntry]
  paths : DaemonTickPaths
  standing_goals : Array[@core.StandingGoal]
  state : @core.TownState
  daemon : @scheduler.DaemonState
  mayor : @roles.Mayor
  next_tick_sequence : Int
}

///|
async fn prepare_daemon_tick_context(
  snapshot_path : String,
  book_catalog_path : String,
) -> DaemonTickContext {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let paths = daemon_tick_paths(snapshot_path)
  let standing_goals = @storage.load_or_create_standing_goals(
    path=paths.goal_path,
  )
  let watcher_records_for_floor = load_watcher_records_for_goals(
    snapshot_path, standing_goals,
  )
  let state = load_or_create_demo_state(path=snapshot_path, book_catalog_path~)
  let loaded_daemon = load_daemon_state(paths.daemon_path)
  let tick_floor = daemon_tick_floor(
    snapshot_path,
    paths.log_path,
    loaded_daemon,
    standing_goals,
    watcher_records_for_floor,
    state,
  )
  let daemon = daemon_rebased_to_tick_floor(loaded_daemon, tick_floor)
  if daemon.tick_sequence > loaded_daemon.tick_sequence {
    save_daemon_state(paths.daemon_path, daemon)
  }
  {
    catalog,
    paths,
    standing_goals,
    state,
    daemon,
    mayor: demo_mayor(),
    next_tick_sequence: daemon.tick_sequence + 1,
  }
}

///|
fn daemon_tick_paths(snapshot_path : String) -> DaemonTickPaths {
  {
    daemon_path: default_daemon_state_path(snapshot_path),
    log_path: default_daemon_log_path(snapshot_path~),
    goal_path: default_standing_goal_state_path(snapshot_path),
  }
}
