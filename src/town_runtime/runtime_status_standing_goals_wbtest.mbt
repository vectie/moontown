///|
test "runtime status includes due standing goal actions" {
  let state = runtime_status_test_state()
  let goal = runtime_status_standing_goal(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Research OPC.",
    book_id="research-opc",
    next_due_tick=1,
  )
  let status = @runtime_status.runtime_status_from_state(
    state,
    "/tmp/town.json",
    standing_goals=[goal],
    daemon_tick=0,
  )
  assert_eq(status.standing_goal_count, 1)
  assert_eq(status.due_standing_goal_count, 1)
  assert_true(
    status.daemon_actions.any(fn(action) {
      action.kind == @scheduler.standing_goal_due_action_kind()
    }),
  )
}

///|
async test "budget deferred standing goals stay due and are not marked run" {
  let root = cleaned_runtime_status_test_root(
    "/tmp/moontown-standing-budget-deferral-check",
  )
  let state = runtime_status_test_state()
  let launched = runtime_status_standing_goal(
    id="watch-first",
    title="First due watch",
    prompt="first",
    book_id="missing-first",
    next_due_tick=10,
  )
  let launched_second = runtime_status_standing_goal(
    id="watch-second",
    title="Second due watch",
    prompt="second",
    book_id="missing-second",
    next_due_tick=10,
  )
  let launched_third = runtime_status_standing_goal(
    id="watch-third",
    title="Third due watch",
    prompt="third",
    book_id="missing-third",
    next_due_tick=10,
  )
  let deferred = runtime_status_standing_goal(
    id="watch-fourth",
    title="Fourth due watch",
    prompt="fourth",
    book_id="missing-fourth",
    next_due_tick=10,
  )
  let updated = dispatch_due_standing_goals(
    state,
    @roles.Mayor::new(),
    [],
    [launched, launched_second, launched_third, deferred],
    10,
    "\{root}/town.json",
  )
  let first = @core.standing_goal_registry_find(updated, "watch-first").unwrap()
  let second = @core.standing_goal_registry_find(updated, "watch-second").unwrap()
  let third = @core.standing_goal_registry_find(updated, "watch-third").unwrap()
  let fourth = @core.standing_goal_registry_find(updated, "watch-fourth").unwrap()
  assert_true(first.last_run_tick is Some(10))
  assert_eq(first.next_due_tick, 25)
  assert_true(second.last_run_tick is None)
  assert_eq(second.next_due_tick, 10)
  assert_true(third.last_run_tick is Some(10))
  assert_eq(third.next_due_tick, 25)
  assert_true(fourth.last_run_tick is Some(10))
  assert_eq(fourth.next_due_tick, 25)
  assert_true(
    state.events.any(fn(event) {
      event.id == "event-standing-goal-10-watch-second-deferred-budget"
    }),
  )
}

///|
async test "budget deferred standing goal state self repairs without watcher record" {
  let root = cleaned_runtime_status_test_root(
    "/tmp/moontown-standing-budget-repair-check",
  )
  let state = runtime_status_test_state()
  state.record_event(
    @core.TownEvent::new(
      id="event-standing-goal-10-watch-second-deferred-budget",
      kind="standing-goal",
      detail="budget deferred",
    ),
  )
  let corrupted = runtime_status_standing_goal(
    id="watch-second",
    title="Second due watch",
    prompt="second",
    book_id="missing-second",
    next_due_tick=70,
    last_run_tick=Some(10),
  )
  let repaired = reconcile_budget_deferred_standing_goal_state(
    state,
    [corrupted],
    "\{root}/town.json",
  )
  let goal = @core.standing_goal_registry_find(repaired, "watch-second").unwrap()
  assert_true(goal.last_run_tick is None)
  assert_eq(goal.next_due_tick, 10)
  assert_true(
    state.events.any(fn(event) {
      event.id == "event-standing-goal-10-watch-second-budget-state-repaired"
    }),
  )
}

///|
async test "cap deferred standing goals stay due and are not marked run" {
  let root = cleaned_runtime_status_test_root(
    "/tmp/moontown-standing-cap-deferral-check",
  )
  let state = runtime_status_test_state()
  for index in 0..<@core.max_live_external_executions() {
    state.register_execution(
      runtime_status_test_execution(
        "live-external-\{index}",
        "research-opc",
        "packet-\{index}",
        @core.TaskExecutionStatus::Running,
        "running",
        run_id=Some("run-\{index}"),
      ),
    )
  }
  let goal = runtime_status_standing_goal(
    id="watch-cap",
    title="Cap due watch",
    prompt="cap",
    book_id="research-opc",
    next_due_tick=10,
  )
  let updated = dispatch_due_standing_goals(
    state,
    @roles.Mayor::new(),
    [],
    [goal],
    10,
    "\{root}/town.json",
  )
  let kept = @core.standing_goal_registry_find(updated, "watch-cap").unwrap()
  assert_true(kept.last_run_tick is None)
  assert_eq(kept.next_due_tick, 10)
  assert_true(
    state.events.any(fn(event) {
      event.id == "event-standing-goal-10-watch-cap-deferred-cap"
    }),
  )
}

///|
test "standing goal save merge preserves externally added repair goals" {
  let existing = runtime_status_standing_goal(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch",
    book_id="research-opc",
    next_due_tick=10,
  )
  let external_repair = runtime_status_standing_goal(
    id="book-quality-repair-research-opc",
    title="Repair OPC",
    prompt="repair",
    book_id="research-opc",
    next_due_tick=11,
  )
  let updated_existing = runtime_status_standing_goal(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch",
    book_id="research-opc",
    next_due_tick=70,
    last_run_tick=Some(10),
  )
  let merged = merge_standing_goal_updates([existing, external_repair], [
    updated_existing,
  ])
  assert_eq(merged.length(), 2)
  assert_eq(merged[0].id, "watch-opc-news")
  assert_eq(merged[0].next_due_tick, 70)
  assert_eq(merged[1].id, "book-quality-repair-research-opc")
  assert_eq(merged[1].next_due_tick, 11)
}

///|
test "standing goal dispatch budget is intentionally bounded" {
  assert_eq(max_standing_goal_dispatches_per_tick(), 3)
  assert_eq(standing_goal_dispatch_index(0, 4, 5), 1)
  assert_eq(standing_goal_dispatch_index(3, 4, 5), 0)
  let goal = runtime_status_standing_goal(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch",
    book_id="research-opc",
    next_due_tick=10,
  )
  let deferred = goal.mark_watcher_decision(
    100,
    @core.WatcherDecisionKind::Deferred,
  )
  assert_true(deferred.next_due_tick > 100)
  assert_eq(deferred.next_due_tick, 160)
}
