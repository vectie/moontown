///|
fn town_shell_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  town_shell_copy_from_snapshot(town_shell_snapshot(model, worker, execution))
}

///|
fn town_shell_worker_label(worker : WorkerSim?) -> String {
  civic_worker_status_label(worker, fallback_title="Town Shell Foreman")
}

///|
priv struct TownShellSnapshot {
  worker_label : String
  queue_pressure : Int
  runtime_feed : String
  build_stage : String
}

///|
fn town_shell_snapshot(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> TownShellSnapshot {
  {
    worker_label: town_shell_worker_label(worker),
    queue_pressure: town_shell_queue_pressure(model, worker),
    runtime_feed: town_shell_runtime_feed_label(model),
    build_stage: town_shell_build_stage(model, execution),
  }
}

///|
fn town_shell_copy_from_snapshot(snapshot : TownShellSnapshot) -> String {
  [
    "Town Shell now carries the Wenyu build lane as a visible district.",
    "\{snapshot.worker_label} is driving the operator surface,",
    "queue pressure sits at \{snapshot.queue_pressure}%,",
    "the runtime feed is \{snapshot.runtime_feed},",
    "and the current build stage is \{snapshot.build_stage}.",
  ].join(" ")
}

///|
fn town_shell_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  town_shell_queue_pressure_from_inputs(model.pressure, worker)
}

///|
fn town_shell_queue_pressure_from_inputs(
  pressure : Int,
  worker : WorkerSim?,
) -> Int {
  civic_queue_pressure_from_policy(
    town_shell_queue_pressure_policy(pressure),
    worker,
  )
}

///|
fn town_shell_queue_pressure_policy(pressure : Int) -> CivicQueuePressurePolicy {
  {
    worker_base: pressure,
    worker_bonus: 0,
    worker_divisor: 2,
    fallback_base: pressure,
    fallback_bonus: 0,
    fallback_divisor: 1,
  }
}

///|
fn town_shell_runtime_feed_label(model : Model) -> String {
  if model_projection_snapshot_ready(model) {
    "Projection live"
  } else if model_projection_snapshot_waiting(model) {
    "Bridge waiting"
  } else {
    "Demo supervision"
  }
}

///|
fn town_shell_activity_label(
  model : Model,
  tasks : Array[@core.TownTask],
  executions : Array[@core.TaskExecutionRecord],
) -> String {
  let workers_summary = worker_count_summary(workers_for_model(model))
  let executions_summary = execution_count_summary(executions)
  "\{workers_summary.running} workers / \{tasks.length()} tasks / \{executions_summary.review_queued} review"
}

///|
fn town_shell_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  civic_health_after_execution(
    town_shell_base_health(worker),
    execution,
    town_shell_health_execution_policy(),
  )
}

///|
fn town_shell_health_execution_policy() -> CivicHealthExecutionPolicy {
  {
    awaiting_delta: -6,
    review_delta: -16,
    failed_delta: -28,
    completed_delta: 10,
  }
}

///|
fn town_shell_base_health(worker : WorkerSim?) -> Int {
  let base = civic_worker_energy_health_base(
    worker,
    town_shell_worker_health_policy(),
  )
  base
}

///|
fn town_shell_worker_health_policy() -> CivicWorkerEnergyHealthPolicy {
  { fallback: 48, load_divisor: 4, energy_bonus: 18 }
}
