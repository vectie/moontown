///|
test "resident twins copy renders explicit snapshot fields" {
  let copy = resident_twins_copy_from_snapshot({
    worker_label: "Twin Keeper / Running",
    active_twin_label: "Li / Founder Studio",
    private_scope_count: 2,
    review_queue_count: 3,
    build_stage: "Reflection loop running",
  })
  assert_true(copy.contains("居民需求与计划示例"))
  assert_true(copy.contains("未接入真实个人资料"))
  assert_false(copy.contains("runs as a supervised"))
}

///|
test "resident twins queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=80, load=30)
  assert_eq(resident_twins_queue_pressure_from_inputs(40, 2, Some(worker)), 34)
  assert_eq(resident_twins_queue_pressure_from_inputs(40, 2, None), 72)
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
    resident_twins_signal(model, Some(civic_metric_test_execution(PacketReady))),
    "Twin dispatch",
  )
  assert_eq(
    resident_twins_signal(model, Some(civic_metric_test_execution(Running))),
    "Reflection running",
  )
  assert_eq(
    resident_twins_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile, },
      Some(civic_metric_test_execution(Completed)),
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
      Some(civic_metric_test_execution(AwaitingPersistence)),
    ),
    "Persist the reviewed resident summary and refresh the projection-safe handoff.",
  )
  assert_eq(
    resident_twins_next_action(
      model,
      None,
      Some(civic_metric_test_execution(Stale)),
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
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Patch packet prepared",
  )
  assert_eq(
    resident_twins_build_stage(
      model,
      Some(civic_metric_test_execution(Running)),
    ),
    "Reflection loop running",
  )
  assert_eq(
    resident_twins_build_stage(
      model,
      Some(civic_metric_test_execution(Completed)),
    ),
    "Projection updated",
  )
}
