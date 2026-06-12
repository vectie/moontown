///|
fn contest_express_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let queue_pressure = contest_express_queue_pressure(model, worker)
  let stage = contest_express_stage(model, execution)
  let worker_text = contest_express_worker_label(worker)
  "Contest coaching stays visible in the mayor loop: \{worker_text} is advancing \{stage}, queue pressure sits at \{queue_pressure}%, and the next resident-facing handoff stays reviewable."
}

///|
fn contest_express_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Contest Conductor")
}

///|
fn contest_express_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  contest_express_queue_pressure_from_inputs(model.pressure, worker)
}

///|
fn contest_express_queue_pressure_from_inputs(
  pressure : Int,
  worker : WorkerSim?,
) -> Int {
  civic_queue_pressure_from_policy(
    contest_express_queue_pressure_policy(pressure),
    worker,
  )
}

///|
fn contest_express_queue_pressure_policy(
  pressure : Int,
) -> CivicQueuePressurePolicy {
  {
    worker_base: 0,
    worker_bonus: 0,
    worker_divisor: 1,
    fallback_base: pressure,
    fallback_bonus: 8,
    fallback_divisor: 1,
  }
}

///|
fn contest_express_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = civic_worker_energy_health_base(
    worker,
    contest_express_worker_health_policy(),
  )
  civic_health_after_execution(
    base,
    execution,
    contest_express_health_execution_policy(),
  )
}

///|
fn contest_express_worker_health_policy() -> CivicWorkerEnergyHealthPolicy {
  { fallback: 46, load_divisor: 4, energy_bonus: 4 }
}

///|
fn contest_express_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -10,
    review_delta: -20,
    failed_delta: -30,
    completed_delta: 10,
  }
}
