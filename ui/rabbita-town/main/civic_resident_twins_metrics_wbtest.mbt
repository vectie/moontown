///|
test "resident twins copy renders explicit snapshot fields" {
  let copy = resident_twins_copy_from_snapshot({
    worker_label: "Twin Keeper / Running",
    active_twin_label: "Li / Founder Studio",
    private_scope_count: 2,
    review_queue_count: 3,
    build_stage: "Reflection loop running",
  })
  assert_true(copy.contains("Twin Keeper / Running"))
  assert_true(copy.contains("memory-reflection-plan loop"))
  assert_true(copy.contains("Li / Founder Studio is the active twin"))
  assert_true(copy.contains("2 private scopes"))
  assert_true(copy.contains("3 records need keeper attention"))
  assert_true(copy.contains("current stage is Reflection loop running"))
}

///|
test "resident twins queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=80, load=30)
  assert_eq(
    resident_twins_queue_pressure_from_inputs(40, 2, Some(worker)),
    34,
  )
  assert_eq(
    resident_twins_queue_pressure_from_inputs(40, 2, None),
    72,
  )
}

///|
test "resident twins base health centralizes worker energy policy" {
  let worker = civic_metric_test_worker(energy=70, load=20)
  assert_eq(resident_twins_base_health(Some(worker)), 87)
  assert_eq(resident_twins_base_health(None), 54)
}

///|
test "resident twins signal uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    resident_twins_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Twin dispatch",
  )
  assert_eq(
    resident_twins_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Reflection running",
  )
  assert_eq(
    resident_twins_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge",
  )
}

///|
test "resident twins next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    resident_twins_next_action(
      model,
      None,
      Some(civic_metric_test_execution(
        @core.TaskExecutionStatus::AwaitingPersistence,
      )),
    ),
    "Persist the reviewed resident summary and refresh the projection-safe handoff.",
  )
  assert_eq(
    resident_twins_next_action(
      model,
      None,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Stale)),
    ),
    "Recover the stalled resident lane before memory and plan cards drift.",
  )
}

///|
test "resident twins build stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    resident_twins_build_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Patch packet prepared",
  )
  assert_eq(
    resident_twins_build_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Reflection loop running",
  )
  assert_eq(
    resident_twins_build_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection updated",
  )
}
