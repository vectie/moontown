///|
fn resident_count(model : Model) -> Int {
  52 + model.tick % 19
}

///|
fn resident_joins_today(model : Model) -> Int {
  let operating_lift = 1
  let recovery_drag = if mayor_recovery_active(model) { 2 } else { 0 }
  let joins = 4 + model.tick % 6 + operating_lift - recovery_drag
  if joins < 1 {
    1
  } else {
    joins
  }
}

///|
fn active_quest_count(model : Model) -> Int {
  let mut count = 0
  for task in tasks_for_model(model) {
    if task.status == Assigned || task.status == Running {
      count += 1
    }
  }
  count
}

///|
fn events_today(model : Model) -> Int {
  social_matches().length() + 1 + model.tick % 3
}

///|
fn valley_points_issued(model : Model) -> Int {
  valley_points_redeemed(model) +
  resident_joins_today(model) +
  events_today(model)
}

///|
fn valley_points_redeemed(model : Model) -> Int {
  12 + model.tick % 11
}

///|
fn achievement_broadcast_count(model : Model) -> Int {
  execution_count_summary(executions_for_model(model)).completed +
  model.tick % 3
}

///|
fn service_response_minutes(model : Model) -> Int {
  let recovery_delay = if mayor_recovery_active(model) { 2 } else { 0 }
  4 + model.pressure / 12 + recovery_delay
}

///|
fn agent_action_count(model : Model) -> Int {
  let workers_summary = worker_count_summary(workers_for_model(model))
  18 + workers_summary.running * 4 + model.tick % 9
}

///|
fn retention_signal(model : Model) -> Int {
  clamp_metric(
    (model.stability * 2 + model.energy + model.budget - model.pressure) / 3,
  )
}

///|
fn robot_service_count(model : Model) -> Int {
  8 + model.tick % 7
}
