///|
fn policy_hall_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let queue_pressure = policy_hall_queue_pressure(model, worker)
  let quest_stage = policy_hall_quest_stage(model, execution)
  let worker_text = policy_hall_worker_label(worker)
  let confidence = policy_hall_confidence(model, execution)
  "Policy guidance stays inside the town loop: \{worker_text} is advancing the quest, queue pressure sits at \{queue_pressure}%, confidence is \{confidence}%, and the current resident-facing stage is \{quest_stage}."
}

///|
fn policy_hall_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Policy Sprite")
}

///|
fn policy_hall_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  policy_hall_queue_pressure_from_inputs(model.pressure, worker)
}

///|
fn policy_hall_queue_pressure_from_inputs(
  pressure : Int,
  worker : WorkerSim?,
) -> Int {
  civic_queue_pressure_from_policy(
    policy_hall_queue_pressure_policy(pressure),
    worker,
  )
}

///|
fn policy_hall_queue_pressure_policy(
  pressure : Int,
) -> CivicQueuePressurePolicy {
  {
    worker_base: 0,
    worker_bonus: 0,
    worker_divisor: 1,
    fallback_base: pressure,
    fallback_bonus: 0,
    fallback_divisor: 1,
  }
}

///|
fn policy_hall_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = civic_worker_energy_health_base(
    worker,
    policy_hall_worker_health_policy(),
  )
  civic_health_after_execution(
    base,
    execution,
    policy_hall_health_execution_policy(),
  )
}

///|
fn policy_hall_worker_health_policy() -> CivicWorkerEnergyHealthPolicy {
  { fallback: 42, load_divisor: 3, energy_bonus: 0 }
}

///|
fn policy_hall_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -8,
    review_delta: -18,
    failed_delta: -28,
    completed_delta: 12,
  }
}

///|
fn policy_hall_confidence(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  civic_execution_score(
    execution,
    policy_hall_confidence_policy(),
    fallback=policy_hall_confidence_fallback(model),
  )
}

///|
fn policy_hall_confidence_policy() -> CivicExecutionScorePolicy {
  {
    packet: 69,
    running: 74,
    persisting: 82,
    review: 56,
    completed: 94,
    recovery: 28,
  }
}

///|
fn policy_hall_confidence_fallback(model : Model) -> Int {
  if model.state_source == StateSourceKind::SnapshotFile {
    41
  } else {
    78
  }
}
