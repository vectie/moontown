///|
fn social_square_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  social_square_copy_from_snapshot(
    social_square_snapshot(model, worker, execution),
  )
}

///|
fn social_square_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Cafe Matchmaker")
}

///|
priv struct SocialSquareSnapshot {
  worker_label : String
  match_count : Int
  queue_pressure : Int
  lead_confidence : Int
  stage : String
}

///|
fn social_square_snapshot(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> SocialSquareSnapshot {
  let match_count = social_square_match_count()
  {
    worker_label: social_square_worker_label(worker),
    match_count,
    queue_pressure: social_square_queue_pressure_from_inputs(
      model.pressure,
      match_count,
      worker,
    ),
    lead_confidence: social_square_lead_match(model).confidence,
    stage: social_square_stage(model, execution),
  }
}

///|
fn social_square_copy_from_snapshot(snapshot : SocialSquareSnapshot) -> String {
  [
    "Social Square now reads like a live district instead of a static networking tile.",
    "\{snapshot.worker_label} is holding \{snapshot.match_count} reasoned introductions,",
    "queue pressure sits at \{snapshot.queue_pressure}%,",
    "strongest current confidence is \{snapshot.lead_confidence}%,",
    "and the active social step is \{snapshot.stage}.",
  ].join(" ")
}

///|
fn social_square_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  social_square_queue_pressure_from_inputs(
    model.pressure,
    social_square_match_count(),
    worker,
  )
}

///|
fn social_square_queue_pressure_from_inputs(
  pressure : Int,
  match_count : Int,
  worker : WorkerSim?,
) -> Int {
  civic_queue_pressure_from_policy(
    social_square_queue_pressure_policy(pressure, match_count),
    worker,
  )
}

///|
fn social_square_queue_pressure_policy(
  pressure : Int,
  match_count : Int,
) -> CivicQueuePressurePolicy {
  {
    worker_base: pressure,
    worker_bonus: match_count * 8,
    worker_divisor: 2,
    fallback_base: pressure,
    fallback_bonus: match_count * 4,
    fallback_divisor: 1,
  }
}

///|
fn social_square_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  civic_health_after_execution(
    social_square_base_health(worker),
    execution,
    social_square_health_execution_policy(),
  )
}

///|
fn social_square_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -4,
    review_delta: -14,
    failed_delta: -24,
    completed_delta: 8,
  }
}

///|
fn social_square_base_health(worker : WorkerSim?) -> Int {
  let base = civic_worker_energy_health_base(
    worker,
    social_square_worker_health_policy(),
  )
  base
}

///|
fn social_square_worker_health_policy() -> CivicWorkerEnergyHealthPolicy {
  { fallback: 54, load_divisor: 5, energy_bonus: 22 }
}
