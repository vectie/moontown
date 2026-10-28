///|
/// Count displayed examples only, not real residents. Unconnected business
/// metrics below retain neutral compatibility values for simulation helpers;
/// they are never rendered as observed zeroes. Real task counts stay separate.
fn resident_count(model : Model) -> Int32 {
  resident_sims(model).length()
}

///|
fn resident_joins_today(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn active_quest_count(model : Model) -> Int32 {
  let mut count = 0
  for task in tasks_for_model(model) {
    if task.status == Assigned || task.status == Running {
      count += 1
    }
  }
  count
}

///|
fn events_today(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn valley_points_issued(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn valley_points_redeemed(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn achievement_broadcast_count(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn service_response_minutes(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn agent_action_count(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn retention_signal(model : Model) -> Int32 {
  ignore(model)
  0
}

///|
fn robot_service_count(model : Model) -> Int32 {
  ignore(model)
  0
}
