///|
test "ai garden copy renders explicit snapshot fields" {
  let copy = ai_garden_copy_from_snapshot({
    worker_label: "AI Garden Tutor / Running",
    stage: "Tutorial quest running",
    scenario_count: 4,
    tool_trial: "Email draft comparison live",
    workshop: "Creator workshop live",
    queue_pressure: 61,
  })
  assert_true(copy.contains("AI Garden Tutor / Running"))
  assert_true(copy.contains("Tutorial quest running"))
  assert_true(copy.contains("4 scenario lanes"))
  assert_true(copy.contains("Email draft comparison live is on deck"))
  assert_true(copy.contains("Creator workshop live is active"))
  assert_true(copy.contains("queue pressure sits at 61%"))
}

///|
test "ai garden queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=80, load=30)
  assert_eq(ai_garden_queue_pressure_from_inputs(45, 4, Some(worker)), 33)
  assert_eq(ai_garden_queue_pressure_from_inputs(45, 4, None), 65)
}

///|
test "ai garden base health uses scenario bonus and queue pressure" {
  let worker = civic_metric_test_worker(energy=80, load=30)
  assert_eq(ai_garden_base_health_from_inputs(45, 4, Some(worker)), 92)
  assert_eq(ai_garden_base_health_from_inputs(45, 4, None), 70)
}

///|
test "ai garden signal uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    ai_garden_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Dispatching",
  )
  assert_eq(
    ai_garden_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Tool trial live",
  )
  assert_eq(
    ai_garden_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge",
  )
}

///|
test "ai garden next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    ai_garden_next_action(
      model,
      None,
      Some(civic_metric_test_execution(
        @core.TaskExecutionStatus::AwaitingPersistence,
      )),
    ),
    "Persist the reviewed tutorial page and refresh the district-facing learning snapshot.",
  )
  assert_eq(
    ai_garden_next_action(
      model,
      None,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Stale)),
    ),
    "Recover the stalled tutorial run before the daily learning loop drifts.",
  )
}

///|
test "ai garden stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    ai_garden_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Tool trial packet prepared",
  )
  assert_eq(
    ai_garden_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Tutorial quest running",
  )
  assert_eq(
    ai_garden_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Daily lesson published",
  )
}

///|
test "ai garden tool trial label uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    ai_garden_tool_trial_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Scenario packet staged",
  )
  assert_eq(
    ai_garden_tool_trial_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Email draft comparison live",
  )
  assert_eq(
    ai_garden_tool_trial_label(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      None,
    ),
    "Projection lesson pending",
  )
}

///|
test "ai garden comparison label uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    ai_garden_comparison_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Comparison prompt staged",
  )
  assert_eq(
    ai_garden_comparison_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Comparison proof published",
  )
  assert_eq(
    ai_garden_comparison_label(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      None,
    ),
    "Projection proof pending",
  )
}
