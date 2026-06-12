///|
async fn run_supervision_cycle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goals? : Array[@core.StandingGoal] = [],
  tick? : Int? = None,
) -> Unit {
  let cycle_tick = resolved_supervision_tick(state, tick)
  run_supervision_reconciliation_passes(
    state,
    catalog,
    snapshot_path,
    standing_goals,
    tick=cycle_tick,
  )
  release_orphaned_blocked_workers(state)
  let packet = mayor.supervise(state, cycle_tick)
  apply_mayor_supervision_packet(
    state, mayor, catalog, packet, snapshot_path, standing_goals,
  )
}

///|
async fn wait_for_goal_settle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  max_cycles? : Int = 120,
  sleep_ms? : Int = 5_000,
) -> Unit {
  let cycles = if max_cycles < 1 { 1 } else { max_cycles }
  for cycle = 0; cycle < cycles; cycle = cycle + 1 {
    run_supervision_cycle(state, mayor, catalog, snapshot_path~)
    persist_town_checkpoint(state, snapshot_path)
    if !@core.has_live_executions(state) &&
      !@core.has_retry_pending_executions(state, supervision_tick(state)) {
      return
    }
    @async.sleep(sleep_ms)
  }
  if @core.has_live_executions(state) {
    state.record_event(
      @core.TownEvent::new(
        id="event-settle-timeout-\{supervision_tick(state)}",
        kind="supervision",
        detail="Mayor supervision timed out while waiting for live executions to settle.",
      ),
    )
  }
}
