///|
pub fn recovery_actions(report : HealthReport) -> Array[RecoveryAction] {
  let actions : Array[RecoveryAction] = []
  for anomaly in report.anomalies {
    actions.push({ kind: "investigate", detail: anomaly.detail })
  }
  actions
}
