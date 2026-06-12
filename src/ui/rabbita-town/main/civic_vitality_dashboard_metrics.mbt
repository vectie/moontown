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
  joins_today : Int
  active_quests : Int
  events_today : Int
  achievement_broadcasts : Int
  response_minutes : Int
  agent_actions : Int
  return_signal : Int
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
  [
    "Moontown now projects a real Vitality Dashboard lane:",
    "\{snapshot.worker_label} is keeping the district pulse visible,",
    "\{snapshot.joins_today} joins,",
    "\{snapshot.active_quests} active quests,",
    "and \{snapshot.events_today} events are on the board,",
    "\{snapshot.achievement_broadcasts} achievement broadcasts are live,",
    "service response is \{snapshot.response_minutes} minutes,",
    "agent actions total \{snapshot.agent_actions},",
    "return signal is \{snapshot.return_signal}%,",
    "and the current patch stage is \{snapshot.build_stage}.",
  ].join(" ")
}

///|
fn vitality_dashboard_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  vitality_dashboard_queue_pressure_from_inputs(
    model.pressure,
    active_quest_count(model),
    worker,
  )
}

///|
fn vitality_dashboard_queue_pressure_from_inputs(
  pressure : Int,
  active_quests : Int,
  worker : WorkerSim?,
) -> Int {
  let quest_load = active_quests * 5
  civic_queue_pressure_from_policy(
    vitality_dashboard_queue_pressure_policy(pressure, quest_load),
    worker,
  )
}

///|
fn vitality_dashboard_queue_pressure_policy(
  pressure : Int,
  quest_load : Int,
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
) -> Int {
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
fn vitality_dashboard_base_health(model : Model, worker : WorkerSim?) -> Int {
  vitality_dashboard_base_health_from_inputs(
    model.energy,
    model.stability,
    retention_signal(model),
    worker,
  )
}

///|
fn vitality_dashboard_base_health_from_inputs(
  energy : Int,
  stability : Int,
  return_signal : Int,
  worker : WorkerSim?,
) -> Int {
  let base = match worker {
    Some(worker) =>
      clamp_metric((worker.energy + stability + return_signal) / 3)
    None => clamp_metric((energy + stability) / 2)
  }
  base
}
