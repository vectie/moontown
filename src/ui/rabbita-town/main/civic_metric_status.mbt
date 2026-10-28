///|
priv struct CivicHealthExecutionPolicy {
  awaiting_delta : Int32
  review_delta : Int32
  failed_delta : Int32
  completed_delta : Int32
}

///|
fn civic_health_after_execution(
  base : Int32,
  execution : @core.TaskExecutionRecord?,
  policy : CivicHealthExecutionPolicy,
) -> Int32 {
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
  base : Int32,
  stage : @ui.ExecutionViewStage,
  policy : CivicHealthExecutionPolicy,
) -> Int32 {
  match stage {
    @ui.Persisting => clamp_metric(base + policy.awaiting_delta)
    @ui.Review => clamp_metric(base + policy.review_delta)
    @ui.Recovery => clamp_metric(base + policy.failed_delta)
    @ui.Completed => clamp_metric(base + policy.completed_delta)
    @ui.Packet | @ui.Running | @ui.Acceptance => base
  }
}

///|
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
  fallback : Int32
  load_divisor : Int32
  energy_bonus : Int32
}

///|
fn civic_worker_energy_health_base(
  worker : WorkerSim?,
  policy : CivicWorkerEnergyHealthPolicy,
) -> Int32 {
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
  worker_base : Int32
  worker_bonus : Int32
  worker_divisor : Int32
  fallback_base : Int32
  fallback_bonus : Int32
  fallback_divisor : Int32
}

///|
fn civic_queue_pressure_from_policy(
  policy : CivicQueuePressurePolicy,
  worker : WorkerSim?,
) -> Int32 {
  match worker {
    Some(worker) => civic_worker_queue_pressure(policy, worker)
    None => civic_fallback_queue_pressure(policy)
  }
}

///|
fn civic_worker_queue_pressure(
  policy : CivicQueuePressurePolicy,
  worker : WorkerSim,
) -> Int32 {
  clamp_metric(
    (worker.load + policy.worker_base + policy.worker_bonus) /
    civic_metric_divisor(policy.worker_divisor),
  )
}

///|
fn civic_fallback_queue_pressure(policy : CivicQueuePressurePolicy) -> Int32 {
  clamp_metric(
    (policy.fallback_base + policy.fallback_bonus) /
    civic_metric_divisor(policy.fallback_divisor),
  )
}

///|
fn civic_metric_divisor(value : Int32) -> Int32 {
  if value <= 0 {
    1
  } else {
    value
  }
}
