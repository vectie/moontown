///|
test "module config runtime status is calm without validation issues" {
  let status = module_config_runtime_status(0)
  assert_eq(status.class, "module-status-calm")
  assert_eq(status.label, "Configured")
}

///|
test "module config runtime status is unbound when validation issues exist" {
  let status = module_config_runtime_status(2)
  assert_eq(status.class, "module-status-unbound")
  assert_eq(status.label, "Needs config")
}

///|
test "civic health runtime counts map seeded health to waiting" {
  let health = civic_health_snapshot_fixture()
  let counts = civic_health_runtime_counts(
    health,
    civic_health_status_kind(health.status),
  )
  assert_eq(counts.waiting, 1)
  assert_eq(counts.review, 0)
  assert_eq(counts.blocked, 0)
  assert_eq(counts.completed, 0)
}

///|
test "civic health runtime counts use status kind for waiting policy" {
  let health = { ..civic_health_snapshot_fixture(), status: "seeded" }
  let waiting = civic_health_runtime_counts(health, Waiting)
  let projected = civic_health_runtime_counts(health, Projected)
  assert_eq(waiting.waiting, 1)
  assert_eq(projected.waiting, 0)
}

///|
test "civic health runtime counts map review blocked and completed evidence" {
  let seeded = civic_health_snapshot_fixture()
  let review = { ..seeded, status: "needs-review", latest_review_items: 3 }
  let blocked = { ..seeded, status: "blocked" }
  let completed = { ..seeded, status: "changed", proven_by_result: true }
  let review_counts = civic_health_runtime_counts(
    review,
    civic_health_status_kind(review.status),
  )
  let blocked_counts = civic_health_runtime_counts(
    blocked,
    civic_health_status_kind(blocked.status),
  )
  let completed_counts = civic_health_runtime_counts(
    completed,
    civic_health_status_kind(completed.status),
  )
  assert_eq(review_counts.waiting, 0)
  assert_eq(review_counts.review, 3)
  assert_eq(blocked_counts.blocked, 1)
  assert_eq(completed_counts.completed, 1)
}

///|
test "civic health runtime issue count includes missing paths" {
  let health = {
    ..civic_health_snapshot_fixture(),
    missing_required_paths: ["book/Home.md", "book/review/queue.md"],
  }
  assert_eq(civic_health_runtime_issue_count(3, health), 5)
}

///|
test "execution runtime state uses professional status labels" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="task",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=RunConfirmed,
    summary="confirmed",
    output_contract="contract",
  )
  let runtime = runtime_state_from_execution(execution, 0, 0)
  assert_eq(runtime.status_label, "Running")
  assert_true(!runtime.status_label.contains("RunConfirmed"))
}
