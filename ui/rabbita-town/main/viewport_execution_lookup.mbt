fn running_execution_count(
  executions : Array[@core.TaskExecutionRecord],
) -> Int {
  execution_count_summary(executions).active_or_unresolved()
}

///|
fn node_matches_execution(
  node_key : String,
  book_id : String,
  status : @core.TaskExecutionStatus,
) -> Bool {
  match node_key {
    "city-hall" => execution_status_is_dispatch_phase(status)
    "anomaly-corner" => execution_status_needs_attention(status)
    "book-coding" => book_id == "coding"
    "book-finance" => book_id == "finance"
    "worker-yard" => execution_status_is_persistence_or_done(status)
    _ => node_key == "book-\{book_id}"
  }
}
