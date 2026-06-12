///|
test "vitality dashboard copy renders explicit metric snapshot" {
  let copy = vitality_dashboard_copy_from_snapshot({
    worker_label: "Pulse Keeper / Running",
    joins_today: 6,
    active_quests: 4,
    events_today: 3,
    achievement_broadcasts: 2,
    response_minutes: 5,
    agent_actions: 19,
    return_signal: 82,
    build_stage: "verified",
  })
  assert_true(copy.contains("Pulse Keeper / Running"))
  assert_true(copy.contains("6 joins"))
  assert_true(copy.contains("4 active quests"))
  assert_true(copy.contains("3 events"))
  assert_true(copy.contains("2 achievement broadcasts"))
  assert_true(copy.contains("service response is 5 minutes"))
  assert_true(copy.contains("agent actions total 19"))
  assert_true(copy.contains("return signal is 82%"))
  assert_true(copy.contains("current patch stage is verified"))
}

///|
test "vitality dashboard queue pressure is explicit for worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=70, load=40)
  assert_eq(
    vitality_dashboard_queue_pressure_from_inputs(50, 4, Some(worker)),
    36,
  )
  assert_eq(vitality_dashboard_queue_pressure_from_inputs(50, 4, None), 60)
}

///|
test "vitality dashboard base health separates model and worker inputs" {
  let worker = civic_metric_test_worker(energy=90, load=10)
  assert_eq(
    vitality_dashboard_base_health_from_inputs(20, 60, 75, Some(worker)),
    75,
  )
  assert_eq(vitality_dashboard_base_health_from_inputs(20, 60, 75, None), 40)
}

///|
test "vitality dashboard signal uses shared phrases with recovery override" {
  let model = init_model()
  assert_eq(
    vitality_dashboard_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Sync queued",
  )
  assert_eq(
    vitality_dashboard_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Pulse syncing",
  )
  assert_eq(
    vitality_dashboard_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge",
  )
  assert_eq(
    vitality_dashboard_signal(
      { ..model, pressure: 90 },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Recovery loop",
  )
}

///|
test "vitality dashboard next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    vitality_dashboard_next_action(
      model,
      None,
      Some(
        civic_metric_test_execution(
          @core.TaskExecutionStatus::AwaitingPersistence,
        ),
      ),
    ),
    "Persist the validated vitality slice so Moontown can project it beyond demo simulation.",
  )
  assert_eq(
    vitality_dashboard_next_action(
      model,
      None,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Stale)),
    ),
    "Recover the stalled vitality run before the district pulse drifts out of sync.",
  )
}
