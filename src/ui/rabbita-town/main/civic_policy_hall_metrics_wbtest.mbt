///|
test "policy hall queue pressure separates worker and fallback modes" {
  let worker = civic_metric_test_worker(energy=70, load=30)
  assert_eq(policy_hall_queue_pressure_from_inputs(50, Some(worker)), 30)
  assert_eq(policy_hall_queue_pressure_from_inputs(50, None), 50)
}

///|
test "policy hall health keeps existing worker energy policy" {
  let worker = civic_metric_test_worker(energy=70, load=21)
  assert_eq(policy_hall_health(Some(worker), None), 63)
  assert_eq(
    policy_hall_health(
      Some(worker),
      Some(
        civic_metric_test_execution(
          AwaitingPersistence,
        ),
      ),
    ),
    55,
  )
  assert_eq(
    policy_hall_health(
      Some(worker),
      Some(civic_metric_test_execution(Completed)),
    ),
    75,
  )
  assert_eq(policy_hall_health(None, None), 42)
}

///|
test "policy hall quest stage uses shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    policy_hall_quest_stage(
      model,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Packet prepared",
  )
  assert_eq(
    policy_hall_quest_stage(
      model,
      Some(civic_metric_test_execution(Running)),
    ),
    "Advisor interpreting",
  )
  assert_eq(
    policy_hall_quest_stage(
      model,
      Some(civic_metric_test_execution(Completed)),
    ),
    "Checklist ready",
  )
}

///|
test "policy hall next action uses shared execution action groups" {
  let model = init_model()
  assert_eq(
    policy_hall_next_action(
      model,
      None,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Confirm dispatch and open the first policy quest step.",
  )
  assert_eq(
    policy_hall_next_action(
      model,
      None,
      Some(civic_metric_test_execution(ReviewQueued)),
    ),
    "Escalate the low-confidence answer for keeper review before publishing.",
  )
}

///|
test "policy hall signal uses shared execution signal groups" {
  let model = init_model()
  assert_eq(
    policy_hall_signal(
      model,
      Some(civic_metric_test_execution(Running)),
    ),
    "Quest live",
  )
  assert_eq(
    policy_hall_signal(
      model,
      Some(civic_metric_test_execution(ReviewQueued)),
    ),
    "Escalated",
  )
}

///|
test "policy hall secondary labels use shared execution phrase groups" {
  let model = init_model()
  assert_eq(
    policy_hall_checklist_label(
      model,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    "Packet staged",
  )
  assert_eq(
    policy_hall_checklist_label(
      model,
      Some(civic_metric_test_execution(Completed)),
    ),
    "Ready for resident handoff",
  )
  assert_eq(
    policy_hall_evidence_label(
      model,
      Some(civic_metric_test_execution(Running)),
    ),
    "Clause scan in flight",
  )
  assert_eq(
    policy_hall_evidence_label(
      model,
      Some(civic_metric_test_execution(Failed)),
    ),
    "Evidence needs recovery",
  )
}

///|
test "policy hall confidence uses shared execution score policy" {
  let model = init_model()
  assert_eq(
    policy_hall_confidence(
      model,
      Some(civic_metric_test_execution(PacketReady)),
    ),
    69,
  )
  assert_eq(
    policy_hall_confidence(
      model,
      Some(civic_metric_test_execution(Completed)),
    ),
    94,
  )
  assert_eq(
    policy_hall_confidence(
      model,
      Some(civic_metric_test_execution(Failed)),
    ),
    28,
  )
  assert_eq(
    policy_hall_confidence(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      None,
    ),
    41,
  )
}
