///|
priv struct LatestWatcherMetricView {
  decision : String
  sources : String
  checked : String
  accepted : String
  wiki : String
  book_changed : String
  detail : String
}

///|
priv struct WatcherRecordMetricLabels {
  sources : String
  checked : String
  found : String
  accepted : String
  rejected : String
  wiki : String
  book_changed : String
}

///|
fn watcher_record_metric_labels(
  record : WatcherRunRecordSnapshot,
) -> WatcherRecordMetricLabels {
  {
    sources: record.new_source_count.to_string(),
    checked: watcher_metric_value(record.checked_sources_count),
    found: watcher_metric_value(record.new_sources_found),
    accepted: watcher_metric_value(record.accepted_facts_count),
    rejected: watcher_metric_value(record.rejected_facts_count),
    wiki: watcher_metric_value(record.wiki_pages_changed_count),
    book_changed: watcher_book_changed_value(record.book_changed),
  }
}

///|
fn latest_watcher_metric_view(
  latest : WatcherRunRecordSnapshot?,
) -> LatestWatcherMetricView {
  match latest {
    Some(record) => {
      let metrics = watcher_record_metric_labels(record)
      {
        decision: record.decision,
        sources: metrics.sources,
        checked: metrics.checked,
        accepted: metrics.accepted,
        wiki: metrics.wiki,
        book_changed: metrics.book_changed,
        detail: one_line(record.detail),
      }
    }
    None =>
      {
        decision: "Waiting",
        sources: "0",
        checked: "n/a",
        accepted: "n/a",
        wiki: "n/a",
        book_changed: "unknown",
        detail: "No durable watcher ledger has been published yet.",
      }
  }
}
