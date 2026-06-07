///|
fn civic_metric_test_execution(
  status : @core.TaskExecutionStatus,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id="task",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status~,
    summary="test",
    output_contract="contract",
  )
}

///|
fn civic_metric_test_worker(
  energy~ : Int,
  load~ : Int,
  status? : @core.WorkerStatus = @core.WorkerStatus::Running,
) -> WorkerSim {
  {
    id: "worker",
    title: "Policy Worker",
    role: "policy",
    book_id: "policy-hall",
    status,
    zone_key: "policy-hall",
    energy,
    load,
    summary: "test worker",
  }
}

test "civic worker status label centralizes fallback and worker display" {
  assert_eq(
    civic_worker_status_label(None, fallback_title="Policy Sprite"),
    "Policy Sprite / pending",
  )
  assert_eq(
    civic_worker_status_label(
      Some(civic_metric_test_worker(energy=70, load=20)),
      fallback_title="Policy Sprite",
    ),
    "Policy Worker / Running",
  )
}

///|
test "civic worker energy health base centralizes common health math" {
  let policy : CivicWorkerEnergyHealthPolicy = {
    fallback: 42,
    load_divisor: 4,
    energy_bonus: 5,
  }
  assert_eq(
    civic_worker_energy_health_base(
      Some(civic_metric_test_worker(energy=70, load=20)),
      policy,
    ),
    70,
  )
  assert_eq(civic_worker_energy_health_base(None, policy), 42)
  assert_eq(
    civic_worker_energy_health_base(
      Some(civic_metric_test_worker(energy=98, load=0)),
      {
        fallback: 42,
        load_divisor: 4,
        energy_bonus: 20,
      },
    ),
    100,
  )
  assert_eq(
    civic_worker_energy_health_base(
      Some(civic_metric_test_worker(energy=70, load=20)),
      {
        fallback: 42,
        load_divisor: 0,
        energy_bonus: 5,
      },
    ),
    55,
  )
}

///|
test "civic queue pressure policy centralizes worker and fallback math" {
  let worker = civic_metric_test_worker(energy=70, load=30)
  let policy : CivicQueuePressurePolicy = {
    worker_base: 40,
    worker_bonus: 20,
    worker_divisor: 3,
    fallback_base: 40,
    fallback_bonus: 10,
    fallback_divisor: 2,
  }
  assert_eq(civic_queue_pressure_from_policy(policy, Some(worker)), 30)
  assert_eq(civic_queue_pressure_from_policy(policy, None), 25)
  assert_eq(civic_worker_queue_pressure(policy, worker), 30)
  assert_eq(civic_fallback_queue_pressure(policy), 25)
}

///|
test "civic queue pressure policy guards invalid divisors" {
  let worker = civic_metric_test_worker(energy=70, load=30)
  let policy : CivicQueuePressurePolicy = {
    worker_base: 40,
    worker_bonus: 20,
    worker_divisor: 0,
    fallback_base: 40,
    fallback_bonus: 10,
    fallback_divisor: -1,
  }
  assert_eq(civic_queue_pressure_from_policy(policy, Some(worker)), 90)
  assert_eq(civic_queue_pressure_from_policy(policy, None), 50)
}

///|
test "civic health execution adjustment centralizes status deltas" {
  let running = civic_metric_test_execution(@core.TaskExecutionStatus::Running)
  let awaiting = civic_metric_test_execution(
    @core.TaskExecutionStatus::AwaitingPersistence,
  )
  let review = civic_metric_test_execution(
    @core.TaskExecutionStatus::ReviewQueued,
  )
  let failed = civic_metric_test_execution(@core.TaskExecutionStatus::Failed)
  let completed = civic_metric_test_execution(
    @core.TaskExecutionStatus::Completed,
  )
  let policy : CivicHealthExecutionPolicy = {
    awaiting_delta: -5,
    review_delta: -10,
    failed_delta: -20,
    completed_delta: 7,
  }
  assert_eq(
    civic_health_after_execution(
      50,
      Some(running),
      policy,
    ),
    50,
  )
  assert_eq(
    civic_health_after_execution(
      50,
      Some(awaiting),
      policy,
    ),
    45,
  )
  assert_eq(
    civic_health_after_execution(
      50,
      Some(review),
      policy,
    ),
    40,
  )
  assert_eq(
    civic_health_after_execution(
      50,
      Some(failed),
      policy,
    ),
    30,
  )
  assert_eq(
    civic_health_after_execution(
      98,
      Some(completed),
      policy,
    ),
    100,
  )
  assert_eq(
    civic_health_after_execution(
      50,
      None,
      policy,
    ),
    50,
  )
}

///|
test "civic health execution adjustment uses shared execution stage policy" {
  let policy : CivicHealthExecutionPolicy = {
    awaiting_delta: -5,
    review_delta: -10,
    failed_delta: -20,
    completed_delta: 7,
  }
  assert_eq(civic_health_after_execution_stage(50, Packet, policy), 50)
  assert_eq(civic_health_after_execution_stage(50, Running, policy), 50)
  assert_eq(civic_health_after_execution_stage(50, Persisting, policy), 45)
  assert_eq(civic_health_after_execution_stage(50, Review, policy), 40)
  assert_eq(civic_health_after_execution_stage(50, Recovery, policy), 30)
  assert_eq(civic_health_after_execution_stage(98, Completed, policy), 100)
}

test "civic module signal class separates snapshot wrapper from status mapping" {
  let model = init_model()
  assert_eq(
    civic_module_signal_class(
      { ..model, state_source: StateSourceKind::SnapshotFile },
      Some(civic_metric_test_execution(@core.TaskExecutionStatus::Completed)),
      running_is_live=true,
    ),
    "module-signal-neutral",
  )
  assert_eq(
    civic_module_signal_class(model, None, running_is_live=true),
    "module-signal-book",
  )
  assert_eq(
    civic_module_signal_class_for_source(
      StateSourceKind::SnapshotFile,
      None,
      running_is_live=true,
    ),
    "module-signal-neutral",
  )
  assert_eq(
    civic_module_signal_class_for_source(
      StateSourceKind::DemoSimulation,
      None,
      running_is_live=true,
    ),
    "module-signal-book",
  )
  assert_eq(
    civic_module_signal_class_for_status(
      @core.TaskExecutionStatus::ReviewQueued,
      running_is_live=true,
    ),
    "module-signal-alert",
  )
  assert_eq(
    civic_module_signal_class_for_status(
      @core.TaskExecutionStatus::AwaitingPersistence,
      running_is_live=true,
    ),
    "module-signal-review",
  )
  assert_eq(
    civic_module_signal_class_for_status(
      @core.TaskExecutionStatus::Running,
      running_is_live=true,
    ),
    "module-signal-live",
  )
  assert_eq(
    civic_module_signal_class_for_status(
      @core.TaskExecutionStatus::Running,
      running_is_live=false,
    ),
    "module-signal-book",
  )
  assert_eq(civic_module_active_run_signal_class(true), "module-signal-live")
  assert_eq(civic_module_active_run_signal_class(false), "module-signal-book")
  assert_eq(
    civic_module_signal_class_for_status(
      @core.TaskExecutionStatus::Completed,
      running_is_live=false,
    ),
    "module-signal-live",
  )
}
