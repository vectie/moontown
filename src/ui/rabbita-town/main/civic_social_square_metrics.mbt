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
  match_count : Int32
  queue_pressure : Int32
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
    stage: social_square_stage(model, execution),
  }
}

///|
fn social_square_copy_from_snapshot(snapshot : SocialSquareSnapshot) -> String {
  [
    "示例合作方向 \{snapshot.match_count} 组；未发送邀请。",
    "真实介绍需要双方同意，不提供未经验证的匹配概率。",
  ].join(" ")
}

///|
fn social_square_queue_pressure(model : Model, worker : WorkerSim?) -> Int32 {
  social_square_queue_pressure_from_inputs(
    model.pressure,
    social_square_match_count(),
    worker,
  )
}

///|
fn social_square_queue_pressure_from_inputs(
  pressure : Int32,
  match_count : Int32,
  worker : WorkerSim?,
) -> Int32 {
  civic_queue_pressure_from_policy(
    social_square_queue_pressure_policy(pressure, match_count),
    worker,
  )
}

///|
fn social_square_queue_pressure_policy(
  pressure : Int32,
  match_count : Int32,
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
) -> Int32 {
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
fn social_square_base_health(worker : WorkerSim?) -> Int32 {
  let base = civic_worker_energy_health_base(
    worker,
    social_square_worker_health_policy(),
  )
  base
}

///|
fn social_square_worker_health_policy() -> CivicWorkerEnergyHealthPolicy {
  { fallback: 54, load_divisor: 5, energy_bonus: 22, }
}
