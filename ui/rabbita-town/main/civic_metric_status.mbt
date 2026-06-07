priv struct CivicHealthExecutionPolicy {
  awaiting_delta : Int
  review_delta : Int
  failed_delta : Int
  completed_delta : Int
}

///|
fn civic_health_after_execution(
  base : Int,
  execution : @core.TaskExecutionRecord?,
  policy : CivicHealthExecutionPolicy,
) -> Int {
  match execution {
    Some(execution) =>
      civic_health_after_execution_stage(
        base,
        civic_execution_stage(execution.status),
        policy,
      )
    None => base
  }
}

///|
fn civic_health_after_execution_stage(
  base : Int,
  stage : CivicExecutionStage,
  policy : CivicHealthExecutionPolicy,
) -> Int {
  match stage {
    Persisting => clamp_metric(base + policy.awaiting_delta)
    Review => clamp_metric(base + policy.review_delta)
    Recovery => clamp_metric(base + policy.failed_delta)
    Completed => clamp_metric(base + policy.completed_delta)
    Packet | Running => base
  }
}

fn civic_worker_status_label(
  worker : WorkerSim?,
  fallback_title~ : String,
) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "\{fallback_title} / pending"
  }
}

///|
priv struct CivicWorkerEnergyHealthPolicy {
  fallback : Int
  load_divisor : Int
  energy_bonus : Int
}

///|
fn civic_worker_energy_health_base(
  worker : WorkerSim?,
  policy : CivicWorkerEnergyHealthPolicy,
) -> Int {
  match worker {
    Some(worker) =>
      clamp_metric(
        worker.energy -
        worker.load / civic_metric_divisor(policy.load_divisor) +
        policy.energy_bonus,
      )
    None => policy.fallback
  }
}

///|
priv struct CivicQueuePressurePolicy {
  worker_base : Int
  worker_bonus : Int
  worker_divisor : Int
  fallback_base : Int
  fallback_bonus : Int
  fallback_divisor : Int
}

///|
fn civic_queue_pressure_from_policy(
  policy : CivicQueuePressurePolicy,
  worker : WorkerSim?,
) -> Int {
  match worker {
    Some(worker) => civic_worker_queue_pressure(policy, worker)
    None => civic_fallback_queue_pressure(policy)
  }
}

///|
fn civic_worker_queue_pressure(
  policy : CivicQueuePressurePolicy,
  worker : WorkerSim,
) -> Int {
  clamp_metric(
    (worker.load + policy.worker_base + policy.worker_bonus) /
    civic_metric_divisor(policy.worker_divisor),
  )
}

///|
fn civic_fallback_queue_pressure(policy : CivicQueuePressurePolicy) -> Int {
  clamp_metric(
    (policy.fallback_base + policy.fallback_bonus) /
    civic_metric_divisor(policy.fallback_divisor),
  )
}

///|
fn civic_metric_divisor(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}
