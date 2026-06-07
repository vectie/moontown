///|
fn resident_private_scope_count(model : Model) -> Int {
  let mut count = 0
  for resident in resident_sims(model) {
    if resident.privacy_scope == "Operator summary" {
      count += 1
    }
  }
  count
}

///|
fn resident_review_queue_count(model : Model) -> Int {
  let mut count = 0
  for execution in executions_for_model(model) {
    if execution.status == @core.TaskExecutionStatus::AwaitingPersistence ||
      execution.status == @core.TaskExecutionStatus::ReviewQueued {
      count += 1
    }
  }
  count
}

///|
fn resident_twins_resident_plan(model : Model) -> String {
  match resident_sims(model).get(model.tick % resident_sims(model).length()) {
    Some(resident) => resident.plan
    None => "Await first resident projection."
  }
}
