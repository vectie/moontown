///|
fn material_watch_snapshot_fixture() -> MaterialWatchSnapshot {
  {
    sources: ["sources/customer.txt", "sources/market.txt"],
    intent: "Keep the customer launch assumption current",
    acceptance: "Show exact changed source and retain review pending",
    next_action: "Founder: review whether the launch date should change",
    plan_path: "plans/customer-watch.json",
    baseline_status: Some("pending_first_check"),
  }
}

///|
fn material_watch_record_fixture(
  tick : Int,
  decision : String,
  detail : String,
) -> WatcherRunRecordSnapshot {
  {
    goal_id: "goal-material",
    tick,
    target_book_id: "research-material",
    decision,
    detail,
    next_due_tick: tick + 10,
    delta_score: 0,
    new_source_count: 0,
    checked_sources_count: None,
    new_sources_found: None,
    accepted_facts_count: None,
    rejected_facts_count: None,
    wiki_pages_changed_count: None,
    book_changed: None,
    task_id: None,
    run_id: None,
  }
}

///|
test "material watch historical snapshots and legacy responses decode without new fields" {
  let requests = parse_operator_requests_json(
    (
      #|[{"id":"old","status":"accepted","created_at":"2026-01-01T00:00:00Z","title":"Old watch","prompt":"Keep watching","target_book_id":"book","cadence_ticks":60,"source_policy":"web-first","quality_threshold":85,"standing_goal_id":"old-goal"}]
    ),
  )
  assert_eq(requests.length(), 1)
  assert_true(requests[0].material_watch is None)
  let response = parse_request_submit_result(
    "{\"ok\":true,\"request_id\":\"old\",\"standing_goal_id\":\"old-goal\"}",
  )
  assert_true(response.ok)
  assert_true(response.material_watch is None)
}

///|
test "material watch saved response shows plan before refresh without claiming a baseline" {
  let pending = operator_request_submitting_model(material_watch_form_fixture())
  let raw =
    #|{"ok":true,"request_id":"request-material","standing_goal_id":"goal-material","material_watch":{"sources":["sources/customer.txt","sources/market.txt"],"intent":"Keep the customer launch assumption current","acceptance":"Show exact changed source and retain review pending","next_action":"Founder: review whether the launch date should change","plan_path":"plans/customer-watch.json","baseline_status":"pending_first_check"}}
  let (_, saved) = operator_request_result_update(
    pending.request_submission_id,
    raw,
    pending,
  )
  assert_false(saved.request_submitting)
  assert_true(saved.request_material_receipt is Some(_))
  assert_true(saved.request_status.contains("first due check"))
  let rendered = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_material_watch_saved_requests({
        ..saved,
        standing_goals: [],
        operator_requests: [],
        watcher_records: [],
      }),
    ),
  )
  assert_true(rendered.contains("sources/customer.txt"))
  assert_true(rendered.contains("sources/market.txt"))
  assert_true(rendered.contains("plans/customer-watch.json"))
  assert_true(
    rendered.contains("Founder: review whether the launch date should change"),
  )
  assert_true(rendered.contains("No check recorded yet"))
  assert_false(rendered.contains("First baseline: saved"))
  let (_, incomplete) = operator_request_result_update(
    pending.request_submission_id,
    "{\"ok\":true,\"request_id\":\"old\",\"standing_goal_id\":\"old-goal\"}",
    pending,
  )
  assert_true(
    incomplete.request_status.contains(
      "did not confirm the saved local-material plan",
    ),
  )
  assert_eq(
    incomplete.request_material_sources,
    pending.request_material_sources,
  )
}

///|
test "material watch reload restores saved sources intent acceptance and next owner action" {
  let requests = parse_operator_requests_json(
    (
      #|[{"id":"request-material","status":"accepted","created_at":"2026-10-04T20:00:00Z","title":"Customer assumption","prompt":"Keep the customer launch assumption current","target_book_id":"research-material","cadence_ticks":10,"source_policy":"local-material:plans/customer-watch.json","quality_threshold":85,"standing_goal_id":"goal-material","material_watch":{"sources":["sources/customer.txt","sources/market.txt"],"intent":"Keep the customer launch assumption current","acceptance":"Show exact changed source and retain review pending","next_action":"Founder: review whether the launch date should change","plan_path":"plans/customer-watch.json","baseline_status":"pending_first_check"}}]
    ),
  )
  assert_eq(requests.length(), 1)
  assert_true(requests[0].material_watch is Some(_))
  let goals = parse_standing_goals_json(
    (
      #|[{"id":"goal-material","title":"Customer assumption","prompt":"Keep the customer launch assumption current","target_book_id":"research-material","cadence_ticks":10,"next_due_tick":31,"last_run_tick":21,"enabled":true,"source_policy":"local-material:plans/customer-watch.json","quality_threshold":85}]
    ),
  )
  let baseline = material_watch_record_fixture(
    11, "NoChange", "Material watch baseline saved for 2 sources; no review requested.",
  )
  let quiet = material_watch_record_fixture(
    21, "NoChange", "Material watch unchanged: 2 exact sources; no new task or review.",
  )
  let model = {
    ..init_model(),
    operator_requests: requests,
    standing_goals: goals,
    watcher_records: [quiet, baseline],
    request_material_receipt: None,
  }
  let rendered = @rabbita.render_to_string(
    @rabbita.static_cell(render_material_watch_saved_requests(model)),
  )
  assert_true(rendered.contains("Customer assumption"))
  assert_true(rendered.contains("sources/customer.txt"))
  assert_true(
    rendered.contains(
      "Acceptance: Show exact changed source and retain review pending",
    ),
  )
  assert_true(rendered.contains("First baseline: saved at tick 11"))
  assert_true(rendered.contains("Next check: tick 31"))
  assert_true(rendered.contains("Latest check at tick 21: Quiet"))
  assert_eq(
    material_watch_latest_record(model, "goal-material").unwrap().tick,
    21,
  )
  let deduplicated = {
    ..model,
    request_material_receipt: Some(
      (
        "request-material",
        "goal-material",
        "research-material",
        material_watch_snapshot_fixture(),
      ),
    ),
  }
  let rendered = @rabbita.render_to_string(
    @rabbita.static_cell(render_material_watch_saved_requests(deduplicated)),
  )
  assert_eq(rendered.split("material-watch-saved").to_array().length(), 2)
  assert_true(rendered.contains("Target Book: research-material"))
}

///|
test "material watch quiet change blocked and retained review are distinct and goal scoped" {
  let baseline = material_watch_record_fixture(
    11, "NoChange", "Material watch baseline saved for 2 sources; no review requested.",
  )
  let quiet = material_watch_record_fixture(
    21, "NoChange", "Material watch unchanged: 2 exact sources; no new task or review.",
  )
  assert_true(
    material_watch_decision_status(baseline).contains("Baseline saved quietly"),
  )
  assert_true(
    material_watch_decision_status(quiet).contains(
      "Quiet: sources and plan unchanged",
    ),
  )
  let changed = {
    ..material_watch_record_fixture(31, "NeedsReview", "Retained review"),
    task_id: Some("task-original"),
    run_id: Some("run-original"),
  }
  assert_true(
    material_watch_decision_status(changed).contains(
      "Change awaits Book review",
    ),
  )
  let blocked = material_watch_record_fixture(
    41, "Failed", "Material watch blocked; source missing",
  )
  assert_true(material_watch_decision_status(blocked).contains("Blocked"))
  assert_false(material_watch_decision_status(blocked).contains("Quiet:"))
  let model = {
    ..init_model(),
    watcher_records: [
      baseline,
      quiet,
      changed,
      { ..blocked, goal_id: "other-goal", },
    ],
  }
  assert_eq(
    material_watch_latest_record(model, "goal-material").unwrap().tick,
    31,
  )
  assert_true(
    material_watch_baseline_status(model, "other-goal").contains(
      "awaiting a confirmed baseline",
    ),
  )
  let rendered = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_material_watch_saved_card(
        model,
        "Customer assumption",
        "goal-material",
        material_watch_snapshot_fixture(),
      ),
    ),
  )
  assert_true(rendered.contains("Change awaits Book review"))
  assert_true(rendered.contains("Retained task: task-original"))
  assert_false(rendered.contains("Latest check at tick 41"))
}

///|
test "material watch truncated history infers baseline only from actual later cycle evidence" {
  let quiet = material_watch_record_fixture(
    21, "NoChange", "Material watch unchanged: 2 exact sources; no new task or review.",
  )
  let source_bound = {
    ..material_watch_record_fixture(
      31, "NeedsReview", "Review pending\nmaterial_watch_input: retained/input.json\nmaterial_watch_input_sha256: hash",
    ),
    task_id: Some("task-original"),
  }
  for record in [quiet, source_bound, { ..source_bound, decision: "NoChange", }] {
    let model = {
      ..init_model(),
      watcher_records: [record],
      standing_goals: [],
    }
    assert_true(
      material_watch_baseline_status(model, "goal-material").contains(
        "established; its original tick is outside",
      ),
    )
    assert_true(
      material_watch_next_check_status(model, "goal-material").contains(
        "Latest ledger next due tick: \{record.next_due_tick}",
      ),
    )
  }
  for
    record in [
      material_watch_record_fixture(1, "Failed", "Source missing"),
      material_watch_record_fixture(2, "Deferred", "No eligible worker"),
    ] {
    let model = { ..init_model(), watcher_records: [record], }
    assert_true(
      material_watch_baseline_status(model, "goal-material").contains(
        "awaiting a confirmed baseline",
      ),
    )
  }
  assert_true(
    material_watch_decision_status({ ..source_bound, decision: "NoChange", }).contains(
      "Source change reviewed",
    ),
  )
}
