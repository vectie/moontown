///|
fn vitality_dashboard_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  vitality_dashboard_copy_from_snapshot(
    vitality_dashboard_snapshot(model, worker, execution),
  )
}

///|
fn vitality_dashboard_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Town Shell Foreman")
}

///|
priv struct VitalityDashboardSnapshot {
  worker_label : String
  joins_today : Int32
  active_quests : Int32
  events_today : Int32
  achievement_broadcasts : Int32
  response_minutes : Int32
  agent_actions : Int32
  return_signal : Int32
  build_stage : String
}

///|
fn vitality_dashboard_snapshot(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> VitalityDashboardSnapshot {
  {
    worker_label: vitality_dashboard_worker_label(worker),
    joins_today: resident_joins_today(model),
    active_quests: active_quest_count(model),
    events_today: events_today(model),
    achievement_broadcasts: achievement_broadcast_count(model),
    response_minutes: service_response_minutes(model),
    agent_actions: agent_action_count(model),
    return_signal: retention_signal(model),
    build_stage: town_shell_build_stage(model, execution),
  }
}

///|
fn vitality_dashboard_copy_from_snapshot(
  snapshot : VitalityDashboardSnapshot,
) -> String {
  ignore(snapshot)
  "居民、积分、活动和服务响应统计未接入；任务记录不等于真实地区活力。"
}

///|
fn vitality_dashboard_queue_pressure(
  model : Model,
  worker : WorkerSim?,
) -> Int32 {
  vitality_dashboard_queue_pressure_from_inputs(
    model.pressure,
    active_quest_count(model),
    worker,
  )
}

///|
fn vitality_dashboard_queue_pressure_from_inputs(
  pressure : Int32,
  active_quests : Int32,
  worker : WorkerSim?,
) -> Int32 {
  let quest_load = active_quests * 5
  civic_queue_pressure_from_policy(
    vitality_dashboard_queue_pressure_policy(pressure, quest_load),
    worker,
  )
}

///|
fn vitality_dashboard_queue_pressure_policy(
  pressure : Int32,
  quest_load : Int32,
) -> CivicQueuePressurePolicy {
  {
    worker_base: pressure,
    worker_bonus: quest_load,
    worker_divisor: 3,
    fallback_base: pressure,
    fallback_bonus: quest_load / 2,
    fallback_divisor: 1,
  }
}

///|
fn vitality_dashboard_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int32 {
  civic_health_after_execution(
    vitality_dashboard_base_health(model, worker),
    execution,
    vitality_dashboard_health_execution_policy(),
  )
}

///|
fn vitality_dashboard_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -8,
    review_delta: -18,
    failed_delta: -30,
    completed_delta: 8,
  }
}

///|
fn vitality_dashboard_base_health(model : Model, worker : WorkerSim?) -> Int32 {
  vitality_dashboard_base_health_from_inputs(
    model.energy,
    model.stability,
    retention_signal(model),
    worker,
  )
}

///|
fn vitality_dashboard_base_health_from_inputs(
  energy : Int32,
  stability : Int32,
  return_signal : Int32,
  worker : WorkerSim?,
) -> Int32 {
  let base = match worker {
    Some(worker) =>
      clamp_metric((worker.energy + stability + return_signal) / 3)
    None => clamp_metric((energy + stability) / 2)
  }
  base
}
