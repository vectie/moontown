///|
async fn reviewer_material_reservation(
  persisted~ : Bool,
) -> (String, @moonbook.BookCatalogEntry, @core.StandingGoal, @core.TownState) {
  let (root, entry, goal) = material_watch_fixture()
  let state = goal_supervision_test_state()
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      1,
      root + "/town.json",
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
      root + "/town.json",
      execute=material_watch_test_execute,
      persist=async fn(town, book, execution) {
        if persisted {
          material_watch_test_persist(town, book, execution)
        } else {
          None
        }
      },
    ),
  )
  (root, entry, goal, state)
}

///|
async test "reviewer uncertain dispatch must remain non-retriable through real supervision" {
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
  let calls = Ref::new(0)
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      11,
      snapshot,
      execute=async fn(mayor, book, task, route, worker, tick) {
        calls.val += 1
        ignore(
          material_watch_test_execute(mayor, book, task, route, worker, tick),
        )
        fail("Dispatch acknowledgement lost after worker received task")
      },
    ),
  )
  assert_eq(calls.val, 1)
  assert_eq(state.executions[0].run_id, None)
  let restarted = @storage.load_snapshot_file(snapshot).unwrap().town
  // Read/reconciliation and scheduling only; no directive is executed and no
  // configured Claw, Book process, provider or listener is invoked.
  run_supervision_reconciliation_passes(
    restarted,
    [],
    snapshot,
    [goal],
    tick=1000,
  )
  let packet = @roles.Mayor::new().supervise(restarted, 1000)
  let retry = packet.directives.filter(d => {
    @roles.supervision_directive_retries_execution(d.kind)
  })
  assert_eq(retry.length(), 0)
}

///|
async test "reviewer receipt cannot bind a different run than the durable reservation" {
  let (root, entry, goal, state) = reviewer_material_reservation(
    persisted=false,
  )
  let original = state.executions[0]
  let wrong = copy_execution_with(original, run_id=Some("different-run"))
  let outcome = material_watch_test_persist(state, entry, wrong).unwrap()
  let directory = material_watch_directory(root + "/town.json", goal.id)
  let rejected = try {
    remember_material_watch_receipt(directory, wrong, outcome)
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  assert_eq(
    load_material_watch_journal(directory).unwrap().changes[0].book_receipt,
    None,
  )
}

///|
async test "reviewer late stale observation cannot erase a durable terminal result" {
  let (root, _, goal, state) = reviewer_material_reservation(persisted=true)
  let original = state.executions[0]
  let stale = copy_execution_with(
    original,
    status=Failed,
    summary="late failed poll",
    heartbeat_tick=10,
  )
  ignore(retain_material_watch_observation(goal, root + "/town.json", stale))
  let journal = load_material_watch_journal(
    material_watch_directory(root + "/town.json", goal.id),
  ).unwrap()
  assert_eq(journal.changes[0].execution.unwrap().status, original.status)
  let restarted = goal_supervision_test_state()
  restore_material_watch_executions(restarted, root + "/town.json", [goal])
  assert_eq(restarted.executions[0].status, original.status)
}

///|
async test "reviewer typed receipt retention must not silently drop on lock contention" {
  let (root, entry, goal, state) = reviewer_material_reservation(
    persisted=false,
  )
  let original = state.executions[0]
  let directory = material_watch_directory(root + "/town.json", goal.id)
  let outcome = material_watch_test_persist(state, entry, original).unwrap()
  let held = @fs.open(
    directory + "/watch.lock",
    mode=ReadWrite,
    create_mode=OpenExisting,
  )
  assert_true(held.try_lock(Exclusive))
  retain_material_watch_book_receipt(original, outcome)
  held.close()
  // The successful persistence caller is allowed to leave AwaitingPersistence.
  // A subsequent observation/cycle must retain the receipt or keep that retry.
  let confirmed = execution_after_successful_book_persist(original, outcome, 12)
  state.replace_execution(confirmed)
  ignore(
    retain_material_watch_observation(goal, root + "/town.json", confirmed),
  )
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      21,
      root + "/town.json",
      execute=material_watch_test_execute,
      persist=material_watch_test_persist,
    ),
  )
  let journal = load_material_watch_journal(directory).unwrap()
  assert_true(
    journal.changes[0].book_receipt is Some(_) ||
    state.executions[0].status == AwaitingPersistence,
  )
}

///|
async test "reviewer source changes during dispatch are retained as a second exact delta" {
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
      execute=async fn(mayor, book, task, route, worker, tick) {
        @support.write_text_file(
          root + "/book/sources/customer.txt",
          "Customer rollout: December\n",
        )
        material_watch_test_execute(mayor, book, task, route, worker, tick)
      },
      persist=material_watch_test_persist,
    ),
  )
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      21,
      snapshot,
      execute=material_watch_test_execute,
      persist=material_watch_test_persist,
    ),
  )
  let journal = load_material_watch_journal(
    material_watch_directory(snapshot, goal.id),
  ).unwrap()
  assert_eq(journal.changes.length(), 2)
  assert_eq(
    journal.changes[1].input.before.filter(source => {
      source.path == "sources/customer.txt"
    })[0].content,
    "Customer rollout: November\n",
  )
  assert_eq(
    journal.changes[1].input.after.filter(source => {
      source.path == "sources/customer.txt"
    })[0].content,
    "Customer rollout: December\n",
  )
  assert_true(
    journal.changes[0].execution.unwrap().run_id !=
    journal.changes[1].execution.unwrap().run_id,
  )
}

///|
async test "reviewer duplicate and traversal plans do not replace baseline" {
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
  let directory = material_watch_directory(snapshot, goal.id)
  let baseline = @fs.read_file(directory + "/journal.json").text()
  let path = root + "/book/plans/customer.json"
  let plan : @material_watch_plan.Plan = @json.from_json(
    @json.parse(@fs.read_file(path).text()),
  )
  for
    sources in [
      ["../secret"],
      ["sources/customer.txt", "sources/customer.txt"],
      ["/absolute"],
      ["sources/./customer.txt"],
    ] {
    @support.write_text_file(path, { ..plan, sources, }.to_json().stringify())
    ignore(
      run_standing_goal_watch_cycle(
        state,
        @roles.Mayor::new(),
        [entry],
        goal,
        11,
        snapshot,
      ),
    )
    assert_eq(state.executions.length(), 0)
    assert_eq(@fs.read_file(directory + "/journal.json").text(), baseline)
  }
}
