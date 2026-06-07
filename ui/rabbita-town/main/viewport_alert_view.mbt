///|
let no_active_alert_text = "No active alerts"

///|
let mayor_recovery_alert_text =
  "Mayor supervision is actively recovering the town loop before service collapse."

///|
priv struct AlertStripView {
  alerts : Array[String]
  chip_class : String
}

///|
fn alert_strip_view(alerts : Array[String]) -> AlertStripView {
  {
    alerts,
    chip_class: alert_strip_chip_class(alerts),
  }
}

///|
fn alert_strip_chip_class(alerts : Array[String]) -> String {
  match alerts {
    [message] if message == no_active_alert_text => "chip-calm"
    [message] if message == mayor_recovery_alert_text => "chip-recovery"
    _ => "chip-alert"
  }
}
