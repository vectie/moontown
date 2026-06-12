///|
pub fn count_health_anomalies_by_title(
  report : HealthReport,
  title : String,
) -> Int {
  let mut count = 0
  for anomaly in report.anomalies {
    if anomaly.title == title {
      count += 1
    }
  }
  count
}
