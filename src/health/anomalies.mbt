///|
fn detect_anomalies(
  worker_health : Array[WorkerHealth],
  executions : Array[@core.TaskExecutionRecord],
) -> Array[Anomaly] {
  let anomalies : Array[Anomaly] = []
  for item in worker_health {
    if item.level != Healthy {
      anomalies.push({
        title: "worker-health",
        detail: "\{item.worker_id} is \{item.level.to_string()}",
      })
    }
  }
  for execution in executions {
    match execution.status {
      Failed =>
        if !execution_issue_superseded(executions, execution) {
          anomalies.push({
            title: "execution-failed",
            detail: "\{execution.task_id} failed after packet \{execution.packet_id}",
          })
        }
      Stale =>
        if !execution_issue_superseded(executions, execution) {
          anomalies.push({
            title: "execution-stale",
            detail: "\{execution.task_id} missed heartbeat and needs mayor recovery",
          })
        }
      _ => ()
    }
  }
  anomalies
}
