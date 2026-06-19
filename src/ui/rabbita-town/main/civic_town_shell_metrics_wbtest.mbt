///|
test "town shell copy renders explicit snapshot fields" {
  let copy = town_shell_copy_from_snapshot({
    worker_label: "Town Shell Foreman / Running",
    queue_pressure: 42,
    runtime_feed: "Projection live",
    build_stage: "Code patch running",
  })
  assert_true(copy.contains("Town Shell Foreman / Running"))
  assert_true(copy.contains("operator surface"))
  assert_true(copy.contains("queue pressure sits at 42%"))
  assert_true(copy.contains("runtime feed is Projection live"))
  assert_true(copy.contains("current build stage is Code patch running"))
}

///|
test "town shell queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=70, load=30)
  assert_eq(town_shell_queue_pressure_from_inputs(50, Some(worker)), 40)
  assert_eq(town_shell_queue_pressure_from_inputs(50, None), 50)
}

///|
test "town shell base health centralizes worker energy policy" {
  let worker = civic_metric_test_worker(energy=70, load=20)
  assert_eq(town_shell_base_health(Some(worker)), 83)
  assert_eq(town_shell_base_health(None), 48)
}

///|
test "town shell build stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    town_shell_build_stage(
      model,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Patch packet prepared",
  )
  assert_eq(
    town_shell_build_stage(
      model,
      Some(civic_metric_test_execution(Running)),
    ),
    "Code patch running",
  )
  assert_eq(
    town_shell_build_stage(
      model,
      Some(civic_metric_test_execution(Completed)),
    ),
    "District card updated",
  )
}

///|
test "town shell next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    town_shell_next_action(
      model,
      None,
      Some(
        civic_metric_test_execution(
          AwaitingPersistence,
        ),
      ),
    ),
    "Persist the validated patch and refresh the book's code-patch record.",
  )
  assert_eq(
    town_shell_next_action(
      model,
      None,
      Some(civic_metric_test_execution(Stale)),
    ),
    "Recover the stalled build run before the shell drifts back to placeholder state.",
  )
}

///|
test "town shell signal uses shared execution signal groups" {
  let model = init_model()
  assert_eq(
    town_shell_signal(
      model,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Build dispatch",
  )
  assert_eq(
    town_shell_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Projection bridge",
  )
}
