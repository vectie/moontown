///|
fn policy_hall_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  ignore(worker)
  ignore(execution)
  "昌平政策材料梳理 · \{civic_surface_evidence(model, "policy-hall")}。任务完成不等于政策结论已核实。"
}

///|
fn policy_hall_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Policy Sprite")
}

///|
fn policy_hall_queue_pressure(model : Model, worker : WorkerSim?) -> Int32 {
  policy_hall_queue_pressure_from_inputs(model.pressure, worker)
}

///|
fn policy_hall_queue_pressure_from_inputs(
  pressure : Int32,
  worker : WorkerSim?,
) -> Int32 {
  civic_queue_pressure_from_policy(
    policy_hall_queue_pressure_policy(pressure),
    worker,
  )
}

///|
fn policy_hall_queue_pressure_policy(
  pressure : Int32,
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
) -> Int32 {
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
  { fallback: 42, load_divisor: 3, energy_bonus: 0, }
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
