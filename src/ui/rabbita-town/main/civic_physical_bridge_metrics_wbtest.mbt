///|
test "physical bridge copy renders explicit snapshot fields" {
  let copy = physical_bridge_copy_from_snapshot({
    worker_label: "Physical Bridge Link / Running",
    stage: "Room and robot sync running",
    robot_calls: 9,
    telemetry_signals: 4,
  })
  assert_true(copy.contains("Physical Bridge Link / Running"))
  assert_true(copy.contains("Room and robot sync running"))
  assert_true(copy.contains("9 robot or venue calls"))
  assert_true(copy.contains("4 live telemetry signals"))
  assert_true(copy.contains("projection-safe town view"))
}

///|
test "physical bridge queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=75, load=30)
  assert_eq(
    physical_bridge_queue_pressure_from_inputs(40, 8, 3, Some(worker)),
    45,
  )
  assert_eq(physical_bridge_queue_pressure_from_inputs(40, 8, 3, None), 60)
}

///|
test "physical bridge base health uses telemetry and queue pressure" {
  let worker = civic_metric_test_worker(energy=75, load=30)
  assert_eq(physical_bridge_base_health_from_inputs(40, 8, 3, Some(worker)), 79)
  assert_eq(physical_bridge_base_health_from_inputs(40, 8, 3, None), 63)
}

///|
test "physical bridge signal uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    physical_bridge_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Sync dispatch",
  )
  assert_eq(
    physical_bridge_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Bridge sync live",
  )
  assert_eq(
    physical_bridge_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge",
  )
}

///|
test "physical bridge next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    physical_bridge_next_action(
      model,
      None,
      Some(
        civic_metric_test_execution(
          @core.TaskExecutionStatus::AwaitingPersistence,
        ),
      ),
    ),
    "Persist the reviewed telemetry and booking slice so Moontown can project a trustworthy district state.",
  )
  assert_eq(
    physical_bridge_next_action(
      model,
      None,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Stale)),
    ),
    "Recover the stalled bridge run before offline status drifts away from the visible town.",
  )
}

///|
test "physical bridge stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    physical_bridge_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Bridge packet prepared",
  )
  assert_eq(
    physical_bridge_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Room and robot sync running",
  )
  assert_eq(
    physical_bridge_stage(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge pending",
  )
}

///|
test "physical bridge handoff label uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    physical_bridge_handoff_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Mayor dispatch opened for bridge run",
  )
  assert_eq(
    physical_bridge_handoff_label(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Room, robot, and proxy counters ready",
  )
  assert_eq(
    physical_bridge_handoff_label(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Failed)),
    ),
    "Projection-safe room and robot feed",
  )
}
