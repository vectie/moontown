///|
test "talent avenue copy renders explicit snapshot fields" {
  let copy = talent_avenue_copy_from_snapshot({
    worker_label: "Talent Cartographer / Running",
    stage: "Talent heatmap refresh",
    graph_entities: 6,
    verified_cards: 4,
  })
  assert_true(copy.contains("Talent Cartographer / Running"))
  assert_true(copy.contains("Talent heatmap refresh"))
  assert_true(copy.contains("6 public-safe cards"))
  assert_true(copy.contains("4 cards already carry reviewable evidence"))
}

///|
test "talent avenue queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=80, load=30)
  assert_eq(talent_avenue_queue_pressure_from_inputs(50, 70, Some(worker)), 50)
  assert_eq(talent_avenue_queue_pressure_from_inputs(50, 70, None), 60)
}

///|
test "talent avenue base health uses verified-card bonus and queue pressure" {
  let worker = civic_metric_test_worker(energy=80, load=30)
  assert_eq(talent_avenue_base_health_from_inputs(50, 70, 2, Some(worker)), 84)
  assert_eq(talent_avenue_base_health_from_inputs(50, 70, 2, None), 44)
}

///|
test "talent avenue signal uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    talent_avenue_signal(
      model,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Dispatching",
  )
  assert_eq(
    talent_avenue_signal(
      model,
      Some(civic_metric_test_execution(Running)),
    ),
    "Heatmap refreshing",
  )
  assert_eq(
    talent_avenue_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(Completed)),
    ),
    "Projection bridge",
  )
}

///|
test "talent avenue next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    talent_avenue_next_action(
      model,
      None,
      Some(
        civic_metric_test_execution(
          AwaitingPersistence,
        ),
      ),
    ),
    "Keep the VIP route note visible while MoonBook persists the reviewed reception summary.",
  )
  assert_eq(
    talent_avenue_next_action(
      model,
      None,
      Some(civic_metric_test_execution(Stale)),
    ),
    "Recover the stalled talent graph before the reception route goes stale.",
  )
}

///|
test "talent avenue stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    talent_avenue_stage(
      model,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Showcase packet prepared",
  )
  assert_eq(
    talent_avenue_stage(
      model,
      Some(civic_metric_test_execution(Running)),
    ),
    "Talent heatmap refresh",
  )
  assert_eq(
    talent_avenue_stage(
      model,
      Some(civic_metric_test_execution(Completed)),
    ),
    "Tour cards ready",
  )
}
