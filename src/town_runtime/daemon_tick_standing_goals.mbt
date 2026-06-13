///|
async fn run_daemon_standing_goal_phase(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  paths : @daemon_runtime.DaemonTickPaths,
  snapshot_path : String,
  tick : Int,
) -> Array[@core.StandingGoal] {
  let after_supervision = reconcile_and_save_standing_goals_after_supervision(
    state,
    paths.goal_path,
    snapshot_path,
  )
  let updated_goals = dispatch_due_standing_goals(
    state, mayor, catalog, after_supervision, tick, snapshot_path,
  )
  let merged_goals = merge_standing_goal_updates(
    @storage.load_or_create_standing_goals(path=paths.goal_path),
    updated_goals,
  )
  @storage.save_standing_goals_file(paths.goal_path, merged_goals)
  reconcile_review_queued_standing_watch_outputs(
    state, catalog, snapshot_path, merged_goals,
  )
  reconcile_persisted_non_review_outputs(state, snapshot_path)
  reconcile_transient_dependency_failures(state)
  @storage.load_or_create_standing_goals(path=paths.goal_path)
}

///|
async fn reconcile_and_save_standing_goals_after_supervision(
  state : @core.TownState,
  goal_path : String,
  snapshot_path : String,
) -> Array[@core.StandingGoal] {
  let goals = reconcile_budget_deferred_standing_goal_state(
    state,
    @storage.load_or_create_standing_goals(path=goal_path),
    snapshot_path,
  )
  @storage.save_standing_goals_file(goal_path, goals)
  goals
}
