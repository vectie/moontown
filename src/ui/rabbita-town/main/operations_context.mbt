///|
priv struct OperationsContext {
  state : @core.TownState
  town_title : String
  workers : Array[WorkerSim]
  executions : Array[@core.TaskExecutionRecord]
  alerts : Array[String]
}

///|
fn operations_health_alerts(state : @core.TownState) -> Array[String] {
  let alerts : Array[String] = []
  for anomaly in @health.inspect_town(state).anomalies {
    alerts.push("[warning] \{anomaly.detail}")
  }
  alerts
}

///|
fn build_operations_context(model : Model) -> OperationsContext {
  let state = state_for_model(model)
  let workers = workers_for_model(model)
  let executions = state.executions
  {
    state,
    town_title: state.config.name,
    workers,
    executions,
    alerts: all_alerts(operations_health_alerts(state), model),
  }
}
