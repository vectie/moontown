///|
test "contest express queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=70, load=30)
  assert_eq(contest_express_queue_pressure_from_inputs(50, Some(worker)), 30)
  assert_eq(contest_express_queue_pressure_from_inputs(50, None), 58)
}

///|
test "contest express health keeps existing worker energy policy" {
  let worker = civic_metric_test_worker(energy=70, load=20)
  assert_eq(contest_express_health(Some(worker), None), 69)
  assert_eq(contest_express_health(None, None), 46)
}

///|
test "contest express stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    contest_express_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Readiness packet prepared",
  )
  assert_eq(
    contest_express_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Mock judge scoring",
  )
  assert_eq(
    contest_express_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Champion-wall ready",
  )
}

///|
test "contest express next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    contest_express_next_action(
      model,
      None,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Finish mock judging and turn weak sections into a revision packet.",
  )
  assert_eq(
    contest_express_next_action(
      model,
      None,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Publish the champion-wall summary, then schedule the next countdown checkpoint.",
  )
}

///|
test "contest express signal uses shared execution signal groups" {
  let model = init_model()
  assert_eq(
    contest_express_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Roadshow ready",
  )
  assert_eq(
    contest_express_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge",
  )
}

///|
test "contest express champion label uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    contest_express_champion_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Champion wall draft",
  )
  assert_eq(
    contest_express_champion_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Waiting on judge notes",
  )
  assert_eq(
    contest_express_champion_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Replay queued",
  )
  assert_eq(
    contest_express_champion_label(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      None,
    ),
    "Projection pending",
  )
}

///|
test "contest express readiness label uses shared execution score policy" {
  let model = init_model()
  assert_eq(
    contest_express_readiness_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "67% ready",
  )
  assert_eq(
    contest_express_readiness_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "96% ready",
  )
  assert_eq(
    contest_express_readiness_label(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      None,
    ),
    "46% ready",
  )
}
