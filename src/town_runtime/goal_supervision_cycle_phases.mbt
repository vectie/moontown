///|
async fn run_supervision_reconciliation_passes(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  tick? : Int = supervision_tick(state),
) -> Unit {
  reconcile_live_executions(
    state,
    catalog,
    snapshot_path,
    standing_goals,
    tick~,
  )
  reconcile_standing_watch_imports_and_ledgers(
    state, catalog, snapshot_path, standing_goals, tick,
  )
  reconcile_standing_watch_outputs(
    state, catalog, snapshot_path, standing_goals,
  )
  reconcile_book_persistence_outputs(
    state, catalog, snapshot_path, standing_goals,
  )
  reconcile_repaired_context_import_failures(state)
  reconcile_transient_dependency_failures(
    state,
    catalog~,
    snapshot_path~,
    standing_goals~,
  )
}

///|
async fn reconcile_standing_watch_imports_and_ledgers(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  tick : Int,
) -> Unit {
  rehydrate_orphaned_deferred_watcher_records(
    state, snapshot_path, standing_goals, tick,
  )
  reconcile_late_detached_import_receipts(
    state,
    tick,
    catalog~,
    snapshot_path~,
    standing_goals~,
  )
  reconcile_terminal_detached_watcher_ledgers(
    state, catalog, snapshot_path, standing_goals,
  )
}

///|
async fn reconcile_standing_watch_outputs(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  reconcile_persisted_standing_watch_records(
    state, snapshot_path, standing_goals,
  )
  reconcile_review_queued_standing_watch_outputs(
    state, catalog, snapshot_path, standing_goals,
  )
  reconcile_failed_standing_watch_outputs(
    state, catalog, snapshot_path, standing_goals,
  )
}

///|
async fn reconcile_book_persistence_outputs(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  reconcile_persisted_non_review_outputs(state, snapshot_path)
  reconcile_transient_dependency_failures(
    state,
    catalog~,
    snapshot_path~,
    standing_goals~,
  )
  reconcile_persisted_terminal_outputs(state, snapshot_path)
  reconcile_transient_dependency_failures(
    state,
    catalog~,
    snapshot_path~,
    standing_goals~,
  )
  reconcile_persisted_non_review_outputs(state, snapshot_path)
}

///|
async fn apply_mayor_supervision_packet(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  packet : @roles.MayorSupervisionPacket,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  if packet.directives.is_empty() {
    return
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-supervise-\{packet.tick}",
      kind="supervision",
      detail=packet.summary,
    ),
  )
  for directive in packet.directives {
    apply_mayor_supervision_directive_with_cap(
      state, mayor, catalog, directive, snapshot_path, standing_goals,
    )
  }
}

///|
async fn apply_mayor_supervision_directive_with_cap(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  directive : @roles.MayorSupervisionDirective,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  if directive.kind == "retry-execution" &&
    @core.live_external_execution_count(state) >=
    @core.max_live_external_executions() {
    state.record_event(
      @core.TownEvent::new(
        id="event-supervise-\{directive.task_id}-retry-deferred-cap",
        kind="supervision",
        detail="Mayor deferred retry for \{directive.task_id} because live external execution count reached \{@core.max_live_external_executions()}.",
        related_task_id=Some(directive.task_id),
      ),
    )
    return
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-supervise-\{directive.task_id}-\{directive.kind}",
      kind="supervision",
      detail=directive.detail,
      related_task_id=Some(directive.task_id),
    ),
  )
  apply_supervision_directive(
    state, mayor, catalog, directive, snapshot_path, standing_goals,
  )
}
