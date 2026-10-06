///|
async fn material_watch_unconfirmed_fixture() -> (
  String,
  @moonbook.BookCatalogEntry,
  @core.StandingGoal,
  @core.TownState,
) {
  let (root, entry, goal) = material_watch_fixture()
  let state = goal_supervision_test_state()
  let snapshot = root + "/town.json"
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      1,
      snapshot,
    ),
  )
  @support.write_text_file(
    root + "/book/sources/customer.txt",
    "Customer rollout: November\n",
  )
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      11,
      snapshot,
      execute=async fn(_, _, _, _, _, _) {
        fail("Dispatch acknowledgement lost")
      },
    ),
  )
  (root, entry, goal, state)
}

///|
async test "material watch late detached receipt resumes the original reserved run" {
  let (root, entry, goal, state) = material_watch_unconfirmed_fixture()
  let snapshot = root + "/town.json"
  // Give this offline fixture an isolated packet location. It is the same
  // task/packet ID reserved before dispatch, not a replacement attempt.
  let packet_path = root + "/packets/original.json"
  let original = copy_execution_with(state.executions[0], packet_path~)
  remember_material_watch_execution(
    material_watch_directory(snapshot, goal.id),
    original,
  )
  state.replace_execution(original)
  run_supervision_cycle(
    state,
    @roles.Mayor::new(),
    [],
    snapshot_path=snapshot,
    standing_goals=[goal],
    tick=Some(1000),
  )
  assert_true(@core.unconfirmed_standing_watch_dispatch(state.executions[0]))
  assert_eq(@roles.Mayor::new().supervise(state, 1000).directives.length(), 0)
  @support.write_text_file(
    packet_path + ".import.json",
    "{\"proposal_id\":\"proposal-original\",\"run_id\":\"run-original\",\"status\":\"Succeeded\"}",
  )
  run_supervision_cycle(
    state,
    @roles.Mayor::new(),
    [],
    snapshot_path=snapshot,
    standing_goals=[goal],
    tick=Some(1001),
  )
  assert_eq(state.executions.length(), 1)
  assert_eq(state.executions[0].task_id, original.task_id)
  assert_eq(state.executions[0].packet_id, original.packet_id)
  assert_eq(state.executions[0].run_id, Some("run-original"))
  assert_eq(state.executions[0].attempt, original.attempt)
  assert_false(@core.unconfirmed_standing_watch_dispatch(state.executions[0]))
  assert_eq(@roles.Mayor::new().supervise(state, 1001).directives.length(), 0)
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      1011,
      snapshot,
    ),
  )
  assert_eq(
    load_material_watch_journal(material_watch_directory(snapshot, goal.id)).unwrap().changes[0].execution.unwrap().run_id,
    Some("run-original"),
  )
}

///|
async test "material watch ignores a retry directive computed before reconciliation" {
  let (root, entry, goal, state) = material_watch_unconfirmed_fixture()
  let original = state.executions[0]
  let before_reconciliation = goal_supervision_test_state()
  before_reconciliation.replace_execution(
    copy_execution_with(
      original,
      status=Failed,
      result_decision="deferred",
      next_retry_tick=None,
    ),
  )
  let directives = @roles.Mayor::new().supervise(before_reconciliation, 1000).directives
  assert_eq(directives.length(), 1)
  assert_true(
    @roles.supervision_directive_retries_execution(directives[0].kind),
  )
  let calls = Ref(0)
  apply_supervision_directive(
    state,
    @roles.Mayor::new(),
    [entry],
    directives[0],
    root + "/town.json",
    [goal],
    retry=async fn(_, _, _, _, _, _, _) { calls.val += 1 },
  )
  assert_eq(calls.val, 0)
  assert_eq(state.executions[0], original)
}

///|
async test "material watch receipt inbox survives contention crash and duplicate writers" {
  let (root, entry, goal, state) = reviewer_material_reservation(
    persisted=false,
  )
  let original = state.executions[0]
  let directory = material_watch_directory(root + "/town.json", goal.id)
  let receipt = material_watch_test_persist(state, entry, original).unwrap()
  let held = @fs.open(
    directory + "/watch.lock",
    mode=ReadWrite,
    create_mode=OpenExisting,
  )
  assert_true(held.try_lock(Exclusive))
  @async.with_task_group(group => {
    for _ in 0..<4 {
      group.spawn_bg(() => retain_material_watch_book_receipt(original, receipt))
    }
  })
  assert_eq(
    load_material_watch_journal(directory).unwrap().changes[0].book_receipt,
    None,
  )
  assert_eq(
    @fs.readdir(directory)
    .filter(name => name.has_prefix("receipt-") && name.has_suffix(".json"))
    .length(),
    1,
  )
  held.close()
  // Simulate loss of all caller memory before it could copy the successful
  // receiver outcome into the town snapshot.
  let restarted = goal_supervision_test_state()
  restore_material_watch_executions(restarted, root + "/town.json", [goal])
  assert_eq(restarted.executions.length(), 1)
  assert_eq(restarted.executions[0].status, ReviewQueued)
  assert_eq(restarted.executions[0].run_id, original.run_id)
  assert_eq(
    load_material_watch_journal(directory).unwrap().changes[0].book_receipt,
    Some(receipt),
  )
  let again = goal_supervision_test_state()
  restore_material_watch_executions(again, root + "/town.json", [goal])
  assert_eq(again.executions[0], restarted.executions[0])
}

///|
async test "material watch preserves unsaved output against a late failed observation" {
  let (root, _, goal, state) = reviewer_material_reservation(persisted=false)
  let original = state.executions[0]
  assert_eq(original.status, AwaitingPersistence)
  let late = copy_execution_with(
    original,
    status=Failed,
    summary="late failed poll",
  )
  let selected = retain_material_watch_observation(
    goal,
    root + "/town.json",
    late,
  )
  assert_eq(selected.status, AwaitingPersistence)
  assert_eq(selected.run_id, original.run_id)
  assert_eq(
    load_material_watch_journal(
      material_watch_directory(root + "/town.json", goal.id),
    ).unwrap().changes[0].execution.unwrap().status,
    AwaitingPersistence,
  )
}

///|
async test "legacy watch cycle keeps its unchanged-input dispatch behavior" {
  let (root, entry, _) = material_watch_fixture()
  let goal = @core.StandingGoal::new(
    id="watch-legacy",
    title="Legacy watch",
    prompt="Existing policy",
    target_book_id=Some(entry.id),
    source_policy="web-first",
  )
  let state = goal_supervision_test_state()
  let snapshot = root + "/town.json"
  for tick in [1, 61] {
    ignore(
      run_standing_goal_watch_cycle(
        state,
        @roles.Mayor::new(),
        [entry],
        goal,
        tick,
        snapshot,
        execute=material_watch_test_execute,
        persist=material_watch_test_persist,
      ),
    )
  }
  assert_eq(state.executions.length(), 2)
  assert_true(state.executions[0].task_id != state.executions[1].task_id)
  assert_true(
    state.executions.all(execution => {
      !@core.unconfirmed_standing_watch_dispatch(execution)
    }),
  )
  assert_false(@fs.exists(material_watch_directory(snapshot, goal.id)))
}

///|
async test "material watch transient deferred completion adopts a genuine late running receipt" {
  let (root, entry, goal) = material_watch_fixture()
  let state = goal_supervision_test_state()
  let snapshot = root + "/town.json"
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      1,
      snapshot,
    ),
  )
  @support.write_text_file(
    root + "/book/sources/customer.txt",
    "Customer rollout: November\n",
  )
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      11,
      snapshot,
      execute=async fn(_, book, task, _, worker, tick) {
        transient_deferred_standing_watch_execution_record(
          book,
          task,
          "Standing watch execution failed: timed out while importing MoonClaw proposal",
          assigned_worker_id=worker,
          tick~,
        )
      },
      persist=async fn(_, _, _) { None },
    ),
  )
  let directory = material_watch_directory(snapshot, goal.id)
  let before = load_material_watch_journal(directory).unwrap().changes[0].execution.unwrap()
  assert_eq(before.run_id, None)
  assert_true(@core.unconfirmed_standing_watch_dispatch(before))
  let packet_path = root + "/packets/transient-original.json"
  let original = copy_execution_with(before, packet_path~)
  remember_material_watch_execution(directory, original)
  state.replace_execution(original)
  @support.write_text_file(
    packet_path + ".import.json",
    "{\"proposal_id\":\"proposal-original\",\"run_id\":\"run-original\",\"status\":\"Running\"}",
  )
  reconcile_no_run_id_live_execution(
    state,
    original,
    21,
    launch_confirmed_run=false,
  )
  assert_eq(state.executions[0].run_id, Some("run-original"))
  assert_eq(state.executions[0].status, RunConfirmed)
  // Deterministic polling boundary, after the real import-receipt decoder has
  // recovered the original run. No launch/provider is invoked by this fixture.
  let running = copy_execution_with(state.executions[0], status=Running)
  let retained = retain_material_watch_observation(goal, snapshot, running)
  assert_eq(retained.run_id, Some("run-original"))
  assert_eq(retained.status, Running)
  let restarted = goal_supervision_test_state()
  restore_material_watch_executions(restarted, snapshot, [goal])
  assert_eq(restarted.executions[0].run_id, Some("run-original"))
  assert_eq(restarted.executions[0].status, Running)
  assert_eq(restarted.executions[0].attempt, original.attempt)
}
