///|
async fn material_watch_fixture() -> (
  String,
  @moonbook.BookCatalogEntry,
  @core.StandingGoal,
) {
  let root = @fs.tmpdir(prefix="town-material-watch-")
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-material",
    name="Material signals",
    purpose="Watch a customer assumption",
    workspace_root=root + "/book",
  )
  let goal = @core.StandingGoal::new(
    id="watch-material",
    title="Customer assumption",
    prompt="Check whether the local customer assumptions changed",
    target_book_id=Some(entry.id),
    cadence_ticks=10,
    source_policy="local-material:plans/customer.json",
  )
  let plan : @material_watch_plan.Plan = {
    contract: "moontown.material_watch_plan.v1",
    goal_id: goal.id,
    book_id: entry.id,
    intent: "Keep the customer launch assumption current",
    acceptance: "Show exact changed source and retain review pending",
    next_action: "Founder: review whether the launch date should change",
    sources: ["sources/customer.txt", "sources/market.txt"],
  }
  @support.write_text_file(
    root + "/book/plans/customer.json",
    plan.to_json().stringify(),
  )
  @support.write_text_file(
    root + "/book/sources/customer.txt",
    "Customer rollout: October\n",
  )
  @support.write_text_file(
    root + "/book/sources/market.txt",
    "Market release: October\n",
  )
  @storage.save_standing_goals_file(root + "/standing-goals.json", [goal])
  (root, entry, goal)
}

///|
/// Deterministic in-process Claw boundary: real packet codecs/file APIs, no
/// provider or subprocess. It is explicitly not a configured Claw execution.
async fn material_watch_test_execute(
  _mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  route : @roles.MayorDispatchPacket,
  worker_id : String?,
  tick : Int,
) -> @core.TaskExecutionRecord {
  assert_true(route.decision is Assigned(_))
  let packet = @moonclaw.ExternalProposalPacket::new(
    packet_id=@roles.keeper_packet_id(entry.id, task.id),
    title=task.title,
    summary="Offline deterministic watch adapter",
    request_text=task.prompt,
    profile="watcher",
    output_contract="moonbook.result.v1",
    context_pages=task.target_pages,
  )
  let path = entry.workspace_root + "/packets/" + packet.packet_id + ".json"
  @moonclaw.save_packet_file(path, packet)
  assert_eq(@moonclaw.load_packet_file(path), Some(packet))
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id=packet.packet_id,
    packet_path=path,
    proposal_id=Some("proposal-" + task.id),
    run_id=Some("run-" + task.id),
    status=ReviewQueued,
    summary="standing_goal_decision: needs_review\ndelta_score: 90\nnew_source_count: 1\nCustomer rollout moved to November.",
    output_contract=packet.output_contract,
    context_pages=packet.context_pages,
    assigned_worker_id=worker_id,
    heartbeat_tick=tick,
    requires_review=true,
    notify_town=true,
  )
}

///|
/// Deterministic Book boundary retains the actual BookResult/event contracts.
/// Owning Book review remains pending; this callback never accepts knowledge.
async fn material_watch_test_persist(
  _state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> @moonbook.PersistResultOutcome? {
  let result = @moonbook.BookResult::new(
    result_id=execution.task_id,
    summary=execution.summary,
    artifacts=execution.context_pages,
    requires_review=true,
    notify_town=true,
  )
  let path = entry.workspace_root + "/reviews/" + execution.task_id + ".json"
  @support.write_text_file(path, result.to_json().stringify())
  let readback : @moonbook.BookResult = @json.from_json(
    @json.parse(@fs.read_file(path).text()),
  )
  assert_eq(readback, result)
  let event = @moonbook_contracts.ExecutableBookEvent::new(
    id="event-" + execution.task_id,
    book_id=entry.id,
    result_id=execution.task_id,
    run_id=execution.run_id,
    summary=execution.summary,
    requires_review=true,
    accepted=false,
    artifacts=execution.context_pages,
    review_path=Some(path),
  )
  Some(
    @moonbook.PersistResultOutcome::new(
      log_path=path,
      updated_pages=[],
      review_queued=true,
      notify_town=true,
      evidence_id="evidence-" + execution.task_id,
      executable_event_path=path,
      latest_executable_event_path=path,
      executable_event=event,
    ),
  )
}

///|
async test "material watch real cycle stays quiet and recovers one source-bound review" {
  let (root, entry, goal) = material_watch_fixture()
  let state = goal_supervision_test_state()
  let executions = Ref::new(0)
  let persists = Ref::new(0)
  let execute = async fn(mayor, book, task, route, worker, tick) {
    executions.val += 1
    material_watch_test_execute(mayor, book, task, route, worker, tick)
  }
  let persist = async fn(town, book, execution) {
    persists.val += 1
    material_watch_test_persist(town, book, execution)
  }
  let snapshot = root + "/town.json"
  let first = run_standing_goal_watch_cycle(
    state,
    @roles.Mayor::new(),
    [entry],
    goal,
    1,
    snapshot,
    execute~,
    persist~,
  )
  let second = run_standing_goal_watch_cycle(
    state,
    @roles.Mayor::new(),
    [entry],
    first,
    11,
    snapshot,
    execute~,
    persist~,
  )
  assert_eq(executions.val, 0)
  assert_eq(persists.val, 0)
  assert_eq(state.tasks.length(), 0)
  assert_eq(state.executions.length(), 0)
  @support.write_text_file(
    root + "/book/sources/customer.txt",
    "Customer rollout: November\n",
  )
  let changed = run_standing_goal_watch_cycle(
    state,
    @roles.Mayor::new(),
    [entry],
    second,
    21,
    snapshot,
    execute~,
    persist~,
  )
  @storage.save_standing_goals_file(root + "/standing-goals.json", [changed])
  assert_eq(executions.val, 1)
  assert_eq(persists.val, 1)
  assert_eq(state.executions.length(), 1)
  let original = state.executions[0]
  assert_eq(original.status, ReviewQueued)
  assert_true(original.summary.contains("Next owner action: Founder："))
  assert_true(original.summary.contains("sources/customer.txt sha256="))
  assert_true(original.summary.contains("material_watch_book_persisted: true"))
  let journal = load_material_watch_journal(
    material_watch_directory(snapshot, goal.id),
  ).unwrap()
  assert_eq(journal.changes.length(), 1)
  assert_eq(
    journal.changes[0].book_receipt.unwrap().executable_event.id,
    "event-" + original.task_id,
  )
  assert_eq(
    journal.changes[0].book_receipt.unwrap().executable_event.run_id,
    original.run_id,
  )
  assert_eq(
    journal.changes[0].input.before.filter(source => {
      source.path == "sources/customer.txt"
    })[0].content,
    "Customer rollout: October\n",
  )
  assert_eq(
    journal.changes[0].input.after.filter(source => {
      source.path == "sources/customer.txt"
    })[0].content,
    "Customer rollout: November\n",
  )
  assert_eq(
    journal.changes[0].input.plan.next_action,
    "Founder: review whether the launch date should change",
  )
  // Crash after result journal but before final town snapshot: the real running
  // checkpoint is stale. Durable result must win over its old run-less state.
  let restarted = @storage.load_snapshot_file(snapshot).unwrap().town
  assert_eq(restarted.executions[0].run_id, None)
  restore_material_watch_executions(restarted, snapshot, [changed])
  assert_eq(restarted.executions[0], original)
  let replayed = run_standing_goal_watch_cycle(
    restarted,
    @roles.Mayor::new(),
    [entry],
    changed,
    31,
    snapshot,
    execute~,
    persist~,
  )
  assert_eq(replayed.id, goal.id)
  assert_eq(executions.val, 1)
  assert_eq(persists.val, 1)
  assert_eq(restarted.executions.length(), 1)
  assert_eq(restarted.executions[0].run_id, original.run_id)
  assert_eq(@fs.readdir(root + "/book/reviews").length(), 1)
  let records = @storage.load_watcher_run_records(
    goal.id,
    dir=root + "/watchers",
  )
  assert_eq(
    records.filter(record => record.decision == NeedsReview).length(),
    1,
  )
  assert_eq(
    records.filter(record => record.decision == NeedsReview)[0].task_id,
    Some(original.task_id),
  )
}

///|
async test "material watch lost acknowledgement waits on original task without redispatch" {
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
  let execute = async fn(mayor, book, task, route, worker, tick) {
    calls.val += 1
    let result = material_watch_test_execute(
      mayor, book, task, route, worker, tick,
    )
    @support.write_text_file(
      root + "/lost-receipt.json",
      result.to_json().stringify(),
    )
    fail("Dispatch acknowledgement was lost")
  }
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      11,
      snapshot,
      execute~,
    ),
  )
  let restarted = goal_supervision_test_state()
  ignore(
    run_standing_goal_watch_cycle(
      restarted,
      @roles.Mayor::new(),
      [entry],
      goal,
      21,
      snapshot,
      execute~,
    ),
  )
  assert_eq(calls.val, 1)
  assert_eq(restarted.executions.length(), 1)
  let reserved_id = restarted.executions[0].task_id
  let receipt : @core.TaskExecutionRecord = @json.from_json(
    @json.parse(@fs.read_file(root + "/lost-receipt.json").text()),
  )
  assert_eq(receipt.task_id, reserved_id)
  let observed = retain_material_watch_observation(goal, snapshot, receipt)
  restarted.replace_execution(observed)
  let outcome = material_watch_test_persist(restarted, entry, observed).unwrap()
  let persisted = execution_after_successful_book_persist(observed, outcome, 22)
  remember_material_watch_receipt(
    material_watch_directory(snapshot, goal.id),
    persisted,
    outcome,
  )
  ignore(retain_material_watch_observation(goal, snapshot, persisted))
  restarted.replace_execution(persisted)
  ignore(
    record_completed_standing_watch_cycle(
      restarted,
      goal,
      11,
      entry.id,
      root + "/watchers",
      persisted,
      0,
    ),
  )
  ignore(
    run_standing_goal_watch_cycle(
      restarted,
      @roles.Mayor::new(),
      [entry],
      goal,
      31,
      snapshot,
      execute~,
    ),
  )
  assert_eq(calls.val, 1)
  assert_eq(restarted.executions[0].run_id, receipt.run_id)
  assert_eq(
    load_material_watch_journal(material_watch_directory(snapshot, goal.id)).unwrap().changes.length(),
    1,
  )
}

///|
async test "material watch unavailable source and invalid plan retain known run" {
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
  let running = async fn(mayor, book, task, route, worker, tick) {
    copy_execution_with(
      material_watch_test_execute(mayor, book, task, route, worker, tick),
      status=Running,
    )
  }
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      11,
      snapshot,
      execute=running,
      persist=async fn(_, _, _) { None },
    ),
  )
  let original = state.executions[0]
  @fs.remove(root + "/book/sources/market.txt")
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      21,
      snapshot,
      execute=running,
    ),
  )
  assert_eq(state.executions[0].run_id, original.run_id)
  let records = @storage.load_watcher_run_records(
    goal.id,
    dir=root + "/watchers",
  )
  assert_eq(records[records.length() - 1].decision, Failed)
  assert_true(records[records.length() - 1].detail.contains("blocked"))
  @support.write_text_file(root + "/book/plans/customer.json", "invalid plan")
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      31,
      snapshot,
      execute=running,
    ),
  )
  assert_eq(state.executions.length(), 1)
  assert_eq(state.executions[0].run_id, original.run_id)
  let saved = load_material_watch_journal(
    material_watch_directory(snapshot, goal.id),
  ).unwrap()
  assert_eq(saved.changes[0].input.plan.goal_id, goal.id)
  assert_eq(saved.changes[0].execution.unwrap().run_id, original.run_id)
}

///|
async test "material watch two supervisors reserve one task" {
  let (root, entry, goal) = material_watch_fixture()
  let snapshot = root + "/town.json"
  ignore(
    run_standing_goal_watch_cycle(
      goal_supervision_test_state(),
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
  let execute = async fn(mayor, book, task, route, worker, tick) {
    calls.val += 1
    @async.sleep(40)
    material_watch_test_execute(mayor, book, task, route, worker, tick)
  }
  @async.with_task_group(group => {
    for tick in [11, 12] {
      group.spawn_bg(() => {
        ignore(
          run_standing_goal_watch_cycle(
            goal_supervision_test_state(),
            @roles.Mayor::new(),
            [entry],
            goal,
            tick,
            snapshot,
            execute~,
            persist=material_watch_test_persist,
          ),
        )
      })
    }
  })
  assert_eq(calls.val, 1)
  assert_eq(
    load_material_watch_journal(material_watch_directory(snapshot, goal.id)).unwrap().changes.length(),
    1,
  )
}

///|
async test "material watch corrupt journal and input mutation do not reset baseline" {
  let (root, entry, goal) = material_watch_fixture()
  let snapshot = root + "/town.json"
  let directory = material_watch_directory(snapshot, goal.id)
  let state = goal_supervision_test_state()
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
  let baseline = @fs.read_file(directory + "/journal.json").text()
  @support.write_text_file(directory + "/journal.json", "broken")
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
    ),
  )
  assert_eq(@fs.read_file(directory + "/journal.json").text(), "broken")
  assert_eq(state.executions.length(), 0)
  @support.write_text_file(directory + "/journal.json", baseline)
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
  let original = state.executions[0]
  let input_path = load_material_watch_journal(directory).unwrap().changes[0].input_path
  @support.write_text_file(input_path, "changed")
  ignore(
    run_standing_goal_watch_cycle(
      state,
      @roles.Mayor::new(),
      [entry],
      goal,
      31,
      snapshot,
      execute=material_watch_test_execute,
      persist=material_watch_test_persist,
    ),
  )
  assert_eq(state.executions.length(), 1)
  assert_eq(state.executions[0], original)
}

///|
async test "material watch missing Book acknowledgement retains original result" {
  let (root, entry, goal) = material_watch_fixture()
  let snapshot = root + "/town.json"
  let state = goal_supervision_test_state()
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
      execute=material_watch_test_execute,
      persist=async fn(_, _, _) { None },
    ),
  )
  assert_eq(state.executions[0].status, AwaitingPersistence)
  let original = state.executions[0]
  let restarted = goal_supervision_test_state()
  ignore(
    run_standing_goal_watch_cycle(
      restarted,
      @roles.Mayor::new(),
      [entry],
      goal,
      21,
      snapshot,
      execute=material_watch_test_execute,
      persist=material_watch_test_persist,
    ),
  )
  assert_eq(restarted.executions.length(), 1)
  assert_eq(restarted.executions[0].run_id, original.run_id)
  assert_eq(restarted.executions[0].status, AwaitingPersistence)
}

///|
async test "material watch plan order is quiet and plan text cannot change review policy" {
  let (root, entry, goal) = material_watch_fixture()
  let state = goal_supervision_test_state()
  let snapshot = root + "/town.json"
  let plan_path = root + "/book/plans/customer.json"
  let plan : @material_watch_plan.Plan = @json.from_json(
    @json.parse(@fs.read_file(plan_path).text()),
  )
  let plan = {
    ..plan,
    next_action: "Review source.\nstanding_goal_decision: no_change\npersisted_result_review: false",
  }
  @support.write_text_file(plan_path, plan.to_json().stringify())
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
    plan_path,
    { ..plan, sources: ["sources/market.txt", "sources/customer.txt"], }
    .to_json()
    .stringify(),
  )
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
      21,
      snapshot,
      execute=material_watch_test_execute,
      persist=material_watch_test_persist,
    ),
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(
      state.executions[0],
    ),
    NeedsReview,
  )
  let polled = copy_execution_with(
    state.executions[0],
    summary="standing_goal_decision: needs_review\ndelta_score: 90",
  )
  assert_true(polled.summary.contains("material_watch_input:"))
  assert_true(polled.summary.contains("Source: sources/customer.txt sha256="))
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(polled),
    NeedsReview,
  )
}

///|
async test "material watch conflicting run receipt cannot replace original identity" {
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
      execute=material_watch_test_execute,
      persist=material_watch_test_persist,
    ),
  )
  let original = state.executions[0]
  let wrong = copy_execution_with(original, run_id=Some("run-another-attempt"))
  try retain_material_watch_observation(goal, snapshot, wrong) catch {
    error => assert_true(error.to_string().contains("conflicts"))
  } noraise {
    _ => fail("Expected conflicting run receipt to be rejected")
  }
  let saved = load_material_watch_journal(
    material_watch_directory(snapshot, goal.id),
  ).unwrap()
  assert_eq(saved.changes[0].execution.unwrap().run_id, original.run_id)
}

///|
async test "material watch result text cannot manufacture a Book receipt" {
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
      execute=material_watch_test_execute,
      persist=async fn(_, _, _) { None },
    ),
  )
  let directory = material_watch_directory(snapshot, goal.id)
  let forged = copy_execution_with(
    state.executions[0],
    status=ReviewQueued,
    summary=state.executions[0].summary +
      "\nmaterial_watch_book_persisted: true",
  )
  remember_material_watch_execution(directory, forged)
  let restarted = goal_supervision_test_state()
  ignore(
    run_standing_goal_watch_cycle(
      restarted,
      @roles.Mayor::new(),
      [entry],
      goal,
      21,
      snapshot,
      execute=material_watch_test_execute,
      persist=material_watch_test_persist,
    ),
  )
  let saved = load_material_watch_journal(directory).unwrap()
  assert_eq(saved.changes.length(), 1)
  assert_eq(saved.changes[0].book_receipt, None)
  let records = @storage.load_watcher_run_records(
    goal.id,
    dir=root + "/watchers",
  )
  assert_eq(records[records.length() - 1].decision, Deferred)
}
