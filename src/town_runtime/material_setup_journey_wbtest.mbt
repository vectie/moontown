///|
async test "material setup actual form body persists exact plan and drives existing cycle after restart" {
  let (root, entry, _old_goal) = material_watch_fixture()
  @moonbook.save_catalog_file(root + "/moonbooks.json", [entry])
  @storage.save_standing_goals_file(root + "/standing-goals.json", [])
  let app = @town_application.request_application(
    root,
    root + "/unused-policy.json",
  )
  let body = match @sys.get_env_var("MOONTOWN_MATERIAL_FORM_BODY") {
    Some(path) => @fs.read_file(path).text()
    None => {
      let request : Json = {
        "watch_mode": "local-material",
        "title": "Customer assumption",
        "prompt": "Keep the customer launch assumption current",
        "target_book_id": "research-material",
        "cadence_ticks": "10",
        "quality_threshold": "85",
        "material_sources": "sources/customer.txt\nsources/market.txt",
        "material_acceptance": "Show exact changed source and retain review pending",
        "material_next_action": "Founder: review whether the launch date should change",
      }
      request.stringify()
    }
  }
  let result = app.submit_standing_watch(body)
  assert_eq(@support.json_string_field(result, "status"), Some("accepted"))
  let goals = @storage.load_standing_goals_file(root + "/standing-goals.json").unwrap()
  assert_eq(goals.length(), 1)
  let goal = goals[0]
  assert_eq(goal.title, "Customer assumption")
  let plan = @material_watch_plan.read_plan(
    entry,
    goal,
    material_watch_plan_path(goal).unwrap(),
  )
  assert_eq(plan.sources.length(), 2)
  assert_true(plan.sources.contains("sources/customer.txt"))
  assert_true(plan.sources.contains("sources/market.txt"))
  assert_eq(
    plan.acceptance,
    "Show exact changed source and retain review pending",
  )
  assert_eq(
    plan.next_action,
    "Founder: review whether the launch date should change",
  )
  assert_eq(plan.intent, goal.prompt)
  // Saving never fabricates a baseline or dispatch.
  let snapshot = root + "/town.json"
  assert_true(
    load_material_watch_journal(material_watch_directory(snapshot, goal.id))
    is None,
  )
  let state = goal_supervision_test_state()
  let first = run_standing_goal_watch_cycle(
    state,
    @roles.Mayor::new(),
    [entry],
    goal,
    1,
    snapshot,
    execute=material_watch_test_execute,
    persist=material_watch_test_persist,
  )
  assert_eq(state.executions.length(), 0)
  let quiet = run_standing_goal_watch_cycle(
    state,
    @roles.Mayor::new(),
    [entry],
    first,
    11,
    snapshot,
    execute=material_watch_test_execute,
    persist=material_watch_test_persist,
  )
  assert_eq(state.executions.length(), 0)
  @storage.save_standing_goals_file(root + "/standing-goals.json", [quiet])
  let restarted_app = @town_application.request_application(
    root,
    root + "/unused-policy.json",
  )
  assert_eq(restarted_app.submit_standing_watch(body), result)
  assert_eq(
    @storage.load_standing_goals_file(root + "/standing-goals.json").unwrap(),
    [quiet],
  )
  let ledger = @support.read_text_or_empty(
    root + "/operator-requests/requests.jsonl",
  )
  assert_eq(ledger.split("\n").filter(line => !line.is_empty()).length(), 1)
  @support.write_text_file(
    root + "/book/sources/customer.txt",
    "Customer rollout: November\n",
  )
  let changed = run_standing_goal_watch_cycle(
    state,
    @roles.Mayor::new(),
    [entry],
    quiet,
    21,
    snapshot,
    execute=material_watch_test_execute,
    persist=material_watch_test_persist,
  )
  assert_eq(state.executions.length(), 1)
  let journal = load_material_watch_journal(
    material_watch_directory(snapshot, goal.id),
  ).unwrap()
  assert_eq(journal.changes.length(), 1)
  assert_true(journal.changes[0].input.plan == plan)
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
  assert_true(journal.changes[0].book_receipt is Some(_))
  let restarted = goal_supervision_test_state()
  restore_material_watch_executions(restarted, snapshot, [changed])
  assert_eq(restarted.executions.length(), 1)
  assert_eq(restarted.executions[0].task_id, state.executions[0].task_id)
  let records = @storage.load_watcher_run_records(
    goal.id,
    dir=root + "/watchers",
  )
  assert_eq(records.length(), 3)
  assert_true(records[0].detail.contains("baseline saved"))
  assert_eq(records[0].decision, NoChange)
  assert_eq(records[0].next_due_tick, 11)
  assert_true(records[1].detail.contains("unchanged"))
  assert_eq(records[1].decision, NoChange)
  assert_eq(records[1].next_due_tick, 21)
  assert_eq(records[2].decision, NeedsReview)
  assert_true(records[2].detail.contains("sources/customer.txt"))
  assert_eq(records[2].task_id, Some(restarted.executions[0].task_id))
  assert_eq(records[2].next_due_tick, changed.next_due_tick)
}
