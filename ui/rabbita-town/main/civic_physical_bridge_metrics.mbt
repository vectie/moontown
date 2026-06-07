///|
fn physical_bridge_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  physical_bridge_copy_from_snapshot(
    physical_bridge_snapshot(model, worker, execution),
  )
}

///|
fn physical_bridge_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Physical Bridge Link")
}

///|
priv struct PhysicalBridgeSnapshot {
  worker_label : String
  stage : String
  robot_calls : Int
  telemetry_signals : Int
}

///|
fn physical_bridge_snapshot(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> PhysicalBridgeSnapshot {
  {
    worker_label: physical_bridge_worker_label(worker),
    stage: physical_bridge_stage(model, execution),
    robot_calls: robot_service_count(model),
    telemetry_signals: physical_bridge_telemetry_signal_count(model),
  }
}

///|
fn physical_bridge_copy_from_snapshot(
  snapshot : PhysicalBridgeSnapshot,
) -> String {
  [
    "Physical Bridge turns Wenyu's offline promise into a reviewable district lane.",
    "\{snapshot.worker_label} is carrying \{snapshot.stage},",
    "\{snapshot.robot_calls} robot or venue calls are visible in this window,",
    "and \{snapshot.telemetry_signals} live telemetry signals are ready for projection-safe town view.",
  ].join(" ")
}

///|
fn physical_bridge_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  physical_bridge_queue_pressure_from_inputs(
    model.pressure,
    robot_service_count(model),
    physical_bridge_telemetry_signal_count(model),
    worker,
  )
}

///|
fn physical_bridge_queue_pressure_from_inputs(
  pressure : Int,
  robot_calls : Int,
  telemetry_signals : Int,
  worker : WorkerSim?,
) -> Int {
  let load_bonus = physical_bridge_load_bonus(robot_calls, telemetry_signals)
  civic_queue_pressure_from_policy(
    physical_bridge_queue_pressure_policy(pressure, load_bonus),
    worker,
  )
}

///|
fn physical_bridge_queue_pressure_policy(
  pressure : Int,
  load_bonus : Int,
) -> CivicQueuePressurePolicy {
  {
    worker_base: pressure,
    worker_bonus: load_bonus,
    worker_divisor: 2,
    fallback_base: pressure,
    fallback_bonus: load_bonus,
    fallback_divisor: 1,
  }
}

///|
fn physical_bridge_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let robot_calls = robot_service_count(model)
  let telemetry_signals = physical_bridge_telemetry_signal_count(model)
  let base = physical_bridge_base_health_from_inputs(
    model.pressure,
    robot_calls,
    telemetry_signals,
    worker,
  )
  civic_health_after_execution(
    base,
    execution,
    physical_bridge_health_execution_policy(),
  )
}

///|
fn physical_bridge_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -8,
    review_delta: -18,
    failed_delta: -28,
    completed_delta: 12,
  }
}

///|
fn physical_bridge_base_health_from_inputs(
  pressure : Int,
  robot_calls : Int,
  telemetry_signals : Int,
  worker : WorkerSim?,
) -> Int {
  let telemetry_bonus = physical_bridge_telemetry_bonus(telemetry_signals)
  let base = match worker {
    Some(worker) =>
      clamp_metric(
        worker.energy +
        telemetry_bonus -
        physical_bridge_queue_pressure_from_inputs(
          pressure,
          robot_calls,
          telemetry_signals,
          Some(worker),
        ) / 4,
      )
    None => clamp_metric(48 + telemetry_bonus)
  }
  base
}
