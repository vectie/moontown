///|
fn talent_avenue_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  talent_avenue_copy_from_snapshot(
    talent_avenue_snapshot(model, worker, execution),
  )
}

///|
fn talent_avenue_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Talent Cartographer")
}

///|
priv struct TalentAvenueSnapshot {
  worker_label : String
  stage : String
  graph_entities : Int
  verified_cards : Int
}

///|
fn talent_avenue_snapshot(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> TalentAvenueSnapshot {
  let signals = talent_signals(model)
  {
    worker_label: talent_avenue_worker_label(worker),
    stage: talent_avenue_stage(model, execution),
    graph_entities: signals.length(),
    verified_cards: talent_avenue_verified_card_count_from_signals(signals),
  }
}

///|
fn talent_avenue_copy_from_snapshot(snapshot : TalentAvenueSnapshot) -> String {
  [
    "Talent Avenue keeps the district legible for visitors and operators:",
    "\{snapshot.worker_label} is carrying \{snapshot.stage},",
    "\{snapshot.graph_entities} public-safe cards are live,",
    "and \{snapshot.verified_cards} cards already carry reviewable evidence status.",
  ].join(" ")
}

///|
fn talent_avenue_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  talent_avenue_queue_pressure_from_inputs(
    model.pressure,
    talent_avenue_activity_score(model),
    worker,
  )
}

///|
fn talent_avenue_queue_pressure_from_inputs(
  pressure : Int,
  activity_score : Int,
  worker : WorkerSim?,
) -> Int {
  civic_queue_pressure_from_policy(
    talent_avenue_queue_pressure_policy(pressure, activity_score),
    worker,
  )
}

///|
fn talent_avenue_queue_pressure_policy(
  pressure : Int,
  activity_score : Int,
) -> CivicQueuePressurePolicy {
  {
    worker_base: 0,
    worker_bonus: activity_score,
    worker_divisor: 2,
    fallback_base: pressure,
    fallback_bonus: activity_score,
    fallback_divisor: 2,
  }
}

///|
fn talent_avenue_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = talent_avenue_base_health_from_inputs(
    model.pressure,
    talent_avenue_activity_score(model),
    talent_avenue_verified_card_count(model),
    worker,
  )
  civic_health_after_execution(
    base,
    execution,
    talent_avenue_health_execution_policy(),
  )
}

///|
fn talent_avenue_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -8,
    review_delta: -18,
    failed_delta: -28,
    completed_delta: 10,
  }
}

///|
fn talent_avenue_base_health_from_inputs(
  pressure : Int,
  activity_score : Int,
  verified_cards : Int,
  worker : WorkerSim?,
) -> Int {
  match worker {
    Some(worker) =>
      clamp_metric(
        worker.energy +
        talent_avenue_verified_card_bonus(verified_cards) -
        talent_avenue_queue_pressure_from_inputs(
          pressure,
          activity_score,
          Some(worker),
        ) /
        4,
      )
    None => 44
  }
}
