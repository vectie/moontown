///|
async fn reconcile_failed_standing_watch_outputs(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if !standing_watch_failed_or_stale(execution) {
      continue
    }
    let context = match
      standing_watch_recovery_context(catalog, standing_goals, execution) {
      Some(context) => context
      None => continue
    }
    if recover_legacy_tick_domain_standing_watch(state, execution) {
      continue
    }
    let observed = standing_watch_observed_for_auto_triage(
      context.entry,
      execution,
      snapshot_path,
    )
    let decision = @standing_watch_policy.standing_watch_recovery_decision_from_execution(
      observed,
    )
    if !@standing_watch_policy.standing_watch_recovery_allowed(
        context.goal,
        observed,
        decision,
      ) {
      if observed != execution {
        state.replace_execution(observed)
      }
      continue
    }
    recover_observed_standing_watch_output(
      state, context, observed, decision, standing_goals, snapshot_path,
    )
  }
}
