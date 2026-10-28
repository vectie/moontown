///|
fn ai_garden_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  ai_garden_copy_from_snapshot(ai_garden_snapshot(model, worker, execution))
}

///|
fn ai_garden_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="AI Garden Tutor")
}

///|
priv struct AiGardenSnapshot {
  worker_label : String
  stage : String
  scenario_count : Int32
  tool_trial : String
  workshop : String
  queue_pressure : Int32
}

///|
fn ai_garden_snapshot(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> AiGardenSnapshot {
  let scenario_count = ai_garden_scenario_count(model)
  {
    worker_label: ai_garden_worker_label(worker),
    stage: ai_garden_stage(model, execution),
    scenario_count,
    tool_trial: ai_garden_tool_trial_label(model, execution),
    workshop: ai_garden_workshop_label(model),
    queue_pressure: ai_garden_queue_pressure_from_inputs(
      model.pressure,
      scenario_count,
      worker,
    ),
  }
}

///|
fn ai_garden_copy_from_snapshot(snapshot : AiGardenSnapshot) -> String {
  ignore(snapshot)
  "AI 学习任务示例；真实工具试用和学习测评未接入。"
}

///|
fn ai_garden_queue_pressure(model : Model, worker : WorkerSim?) -> Int32 {
  ai_garden_queue_pressure_from_inputs(
    model.pressure,
    ai_garden_scenario_count(model),
    worker,
  )
}

///|
fn ai_garden_queue_pressure_from_inputs(
  pressure : Int32,
  scenario_count : Int32,
  worker : WorkerSim?,
) -> Int32 {
  civic_queue_pressure_from_policy(
    ai_garden_queue_pressure_policy(pressure, scenario_count),
    worker,
  )
}

///|
fn ai_garden_queue_pressure_policy(
  pressure : Int32,
  scenario_count : Int32,
) -> CivicQueuePressurePolicy {
  {
    worker_base: pressure,
    worker_bonus: scenario_count * 6,
    worker_divisor: 3,
    fallback_base: pressure,
    fallback_bonus: scenario_count * 5,
    fallback_divisor: 1,
  }
}

///|
fn ai_garden_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int32 {
  let scenario_count = ai_garden_scenario_count(model)
  let base = ai_garden_base_health_from_inputs(
    model.pressure,
    scenario_count,
    worker,
  )
  civic_health_after_execution(
    base,
    execution,
    ai_garden_health_execution_policy(),
  )
}

///|
fn ai_garden_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -8,
    review_delta: -18,
    failed_delta: -30,
    completed_delta: 10,
  }
}

///|
fn ai_garden_base_health_from_inputs(
  pressure : Int32,
  scenario_count : Int32,
  worker : WorkerSim?,
) -> Int32 {
  let scenario_bonus = ai_garden_scenario_bonus(scenario_count)
  let base = match worker {
    Some(worker) =>
      clamp_metric(
        worker.energy +
        scenario_bonus -
        ai_garden_queue_pressure_from_inputs(
          pressure,
          scenario_count,
          Some(worker),
        ) /
        4,
      )
    None => clamp_metric(50 + scenario_bonus)
  }
  base
}
