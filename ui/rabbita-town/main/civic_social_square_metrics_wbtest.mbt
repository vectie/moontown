///|
test "social square copy renders explicit snapshot fields" {
  let copy = social_square_copy_from_snapshot({
    worker_label: "Cafe Matchmaker / Running",
    match_count: 5,
    queue_pressure: 72,
    lead_confidence: 88,
    stage: "RSVP plan in flight",
  })
  assert_true(copy.contains("Cafe Matchmaker / Running"))
  assert_true(copy.contains("5 reasoned introductions"))
  assert_true(copy.contains("queue pressure sits at 72%"))
  assert_true(copy.contains("strongest current confidence is 88%"))
  assert_true(copy.contains("active social step is RSVP plan in flight"))
}

///|
test "social square queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=80, load=30)
  assert_eq(
    social_square_queue_pressure_from_inputs(40, 2, Some(worker)),
    43,
  )
  assert_eq(
    social_square_queue_pressure_from_inputs(40, 2, None),
    48,
  )
}

///|
test "social square base health centralizes worker energy policy" {
  let worker = civic_metric_test_worker(energy=70, load=20)
  assert_eq(social_square_base_health(Some(worker)), 88)
  assert_eq(social_square_base_health(None), 54)
}

///|
test "social square signal uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    social_square_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Match queued",
  )
  assert_eq(
    social_square_signal(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "Match live",
  )
  assert_eq(
    social_square_signal(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge",
  )
}

///|
test "social square next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    social_square_next_action(
      model,
      None,
      Some(civic_metric_test_execution(
        @core.TaskExecutionStatus::AwaitingPersistence,
      )),
    ),
    "Persist the reviewed intro outcome and follow-up note into MoonBook social records.",
  )
  assert_eq(
    social_square_next_action(
      model,
      None,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Stale)),
    ),
    "Recover the stalled introduction run before the context for this weak tie goes cold.",
  )
}

///|
test "social square stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    social_square_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::PacketReady)),
    ),
    "Match dispatch",
  )
  assert_eq(
    social_square_stage(
      model,
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Running)),
    ),
    "RSVP plan in flight",
  )
  assert_eq(
    social_square_stage(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
    ),
    "Projection bridge pending",
  )
}
