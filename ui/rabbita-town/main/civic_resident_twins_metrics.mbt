///|
fn resident_twins_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  resident_twins_copy_from_snapshot(
    resident_twins_snapshot(model, worker, execution),
  )
}

///|
fn resident_twins_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Twin Keeper")
}

///|
priv struct ResidentTwinsSnapshot {
  worker_label : String
  active_twin_label : String
  private_scope_count : Int
  review_queue_count : Int
  build_stage : String
}

///|
fn resident_twins_snapshot(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> ResidentTwinsSnapshot {
  {
    worker_label: resident_twins_worker_label(worker),
    active_twin_label: resident_twins_active_twin_label(model),
    private_scope_count: resident_private_scope_count(model),
    review_queue_count: resident_review_queue_count(model),
    build_stage: resident_twins_build_stage(model, execution),
  }
}

///|
fn resident_twins_copy_from_snapshot(snapshot : ResidentTwinsSnapshot) -> String {
  [
    "Resident Twins now runs as a supervised district lane.",
    "\{snapshot.worker_label} is carrying the memory-reflection-plan loop,",
    "\{snapshot.active_twin_label} is the active twin in view,",
    "\{snapshot.private_scope_count} private scopes stay hidden from town view,",
    "\{snapshot.review_queue_count} records need keeper attention,",
    "and the current stage is \{snapshot.build_stage}.",
  ].join(" ")
}

///|
fn resident_twins_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  resident_twins_queue_pressure_from_inputs(
    model.pressure,
    resident_review_queue_count(model),
    worker,
  )
}

///|
fn resident_twins_queue_pressure_from_inputs(
  pressure : Int,
  review_queue_count : Int,
  worker : WorkerSim?,
) -> Int {
  let review_weight = review_queue_count * 16
  civic_queue_pressure_from_policy(
    resident_twins_queue_pressure_policy(pressure, review_weight),
    worker,
  )
}

///|
fn resident_twins_queue_pressure_policy(
  pressure : Int,
  review_weight : Int,
) -> CivicQueuePressurePolicy {
  {
    worker_base: pressure,
    worker_bonus: review_weight,
    worker_divisor: 3,
    fallback_base: pressure,
    fallback_bonus: review_weight,
    fallback_divisor: 1,
  }
}

///|
fn resident_twins_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  civic_health_after_execution(
    resident_twins_base_health(worker),
    execution,
    resident_twins_health_execution_policy(),
  )
}

///|
fn resident_twins_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -8,
    review_delta: -18,
    failed_delta: -28,
    completed_delta: 10,
  }
}

///|
fn resident_twins_base_health(worker : WorkerSim?) -> Int {
  let base = civic_worker_energy_health_base(
    worker,
    resident_twins_worker_health_policy(),
  )
  base
}

///|
fn resident_twins_worker_health_policy() -> CivicWorkerEnergyHealthPolicy {
  {
    fallback: 54,
    load_divisor: 4,
    energy_bonus: 22,
  }
}
