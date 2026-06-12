///|
fn merge_final_integration_standing_goals(
  existing : Array[@core.StandingGoal],
  specs : Array[FinalIntegrationWatchSpec],
  current_tick : Int,
) -> Array[@core.StandingGoal] {
  let mut merged = existing.copy()
  for spec in specs {
    let next_due_tick = current_tick +
      @support.max_int(0, spec.initial_stagger_ticks)
    let replacement = @core.StandingGoal::new(
      id=spec.id,
      title=spec.title,
      prompt=spec.prompt,
      target_book_id=Some(spec.target_book_id),
      cadence_ticks=@support.max_int(1, spec.cadence_ticks),
      next_due_tick~,
      last_run_tick=match find_standing_goal_by_id(merged, spec.id) {
        Some(goal) => goal.last_run_tick
        None => None
      },
      enabled=true,
      source_policy=final_integration_source_policy(spec),
      quality_threshold=@support.min_int(
        100,
        @support.max_int(1, spec.quality_threshold),
      ),
    )
    merged = @core.standing_goal_registry_replace_or_append(merged, replacement)
  }
  merged
}

///|
fn find_standing_goal_by_id(
  goals : Array[@core.StandingGoal],
  id : String,
) -> @core.StandingGoal? {
  @core.standing_goal_registry_find(goals, id)
}

///|
fn final_integration_watch_coverage(
  manifest : FinalIntegrationManifest,
  goals : Array[@core.StandingGoal],
) -> String {
  let mut installed = 0
  for spec in manifest.domain_watches {
    match find_standing_goal_by_id(goals, spec.id) {
      Some(_) => installed += 1
      None => ()
    }
  }
  "\{installed}/\{manifest.domain_watches.length()}"
}

///|
fn final_integration_source_policy(spec : FinalIntegrationWatchSpec) -> String {
  if spec.source_policy.trim().is_empty() {
    "web-first"
  } else {
    spec.source_policy
  }
}
