///|
priv struct LatestWatcherMetricView {
  decision : String
  sources : String
}

///|
fn latest_watcher_metric_view(
  latest : WatcherRunRecordSnapshot?,
) -> LatestWatcherMetricView {
  match latest {
    Some(record) =>
      { decision: record.decision, sources: record.new_source_count.to_string() }
    None =>
      {
        decision: "Waiting",
        sources: "0",
      }
  }
}
