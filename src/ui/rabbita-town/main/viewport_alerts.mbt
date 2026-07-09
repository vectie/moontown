///|
fn all_alerts(scene : @ui.SceneRenderModel, model : Model) -> Array[String] {
  let alerts : Array[String] = []
  if mayor_recovery_active(model) {
    alerts.push(town_recovery_alert_text)
    return alerts
  }
  for alert in scene.alerts {
    alerts.push(alert)
  }
  if model.pressure > 72 {
    alerts.push("Queue pressure is above safe town thresholds.")
  }
  if model.stability < 38 {
    alerts.push("Town stability is degrading and blockers may spread.")
  }
  if model.budget < 24 {
    alerts.push("Budget reserve is thin; dispatch flexibility is shrinking.")
  }
  if alerts.is_empty() {
    alerts.push(no_active_alert_text)
  }
  alerts
}
